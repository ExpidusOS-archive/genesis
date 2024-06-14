const std = @import("std");
const xev = @import("xev");
const flutter = @import("flutter.zig");
const Allocator = std.mem.Allocator;
const Self = @This();
const Mode = @import("GenesisShell/Mode.zig");

pub const Options = struct {
    mode: ModeType,
    args: ?[]const []const u8 = null,

    pub const default_mode = Mode.default_type;
    pub const ModeType = Mode.Type;
};

const Task = struct {
    id: usize,
    queue: *std.ArrayListUnmanaged(@This()),
    flutter: flutter.Engine.ProjectArgs.CustomTaskRunners.Task,
    completion: xev.Completion,

    fn callback(user_data: ?*anyopaque, loop: *xev.Loop, _: *xev.Completion, result: xev.Result) xev.CallbackAction {
        const self: *Task = @ptrCast(@alignCast(user_data.?));

        const runner: *TaskRunner = @fieldParentPtr("queue", self.queue);
        const shell: *Self = @fieldParentPtr("loop", loop);

        _ = result.timer catch |e| std.log.err("Timer failed for task #{d} on runner #{d}: {s}", .{ self.id, runner.flutter.id, @errorName(e) });

        std.log.debug("Running task #{d} on runner #{d}", .{ self.id, runner.flutter.id });
        shell.engine.runTask(&self.flutter) catch |e| std.log.err("Failed to run task #{d} on runner #{d}: {s}", .{ self.id, runner.flutter.id, @errorName(e) });

        runner.mutex.lock();
        defer runner.mutex.unlock();

        for (runner.queue.items, 0..) |item, i| {
            if (item.id == self.id) {
                _ = runner.queue.orderedRemove(i);
                break;
            }
        }
        return .disarm;
    }
};

const TaskRunner = struct {
    flutter: flutter.Engine.ProjectArgs.CustomTaskRunners.TaskRunnerDescription,
    queue: std.ArrayListUnmanaged(Task) = .{},
    mutex: std.Thread.Mutex = .{},
    next_tid: usize = 1,

    pub fn create(self: *TaskRunner, comptime id: usize) void {
        self.* = .{
            .flutter = .{
                .id = id,
                .user_data = self,
                .post_task_callback = (struct {
                    fn func(task: flutter.Engine.ProjectArgs.CustomTaskRunners.Task, epoch: u64, user_data: ?*anyopaque) callconv(.C) void {
                        const runner: *TaskRunner = @ptrCast(@alignCast(user_data.?));
                        runner.postTask(task, epoch) catch |e| std.log.err("Failed to post task for runner #{d}: {s}", .{ id, @errorName(e) });
                    }
                }).func,
                .runs_task_on_current_thread_callback = (struct {
                    fn func(user_data: ?*anyopaque) callconv(.C) bool {
                        const runner: *const TaskRunner = @ptrCast(@alignCast(user_data.?));
                        const shell = runner.getConstShell();
                        return shell.thread_id == std.os.linux.gettid() and shell.pid == std.os.linux.getpid();
                    }
                }).func,
            },
        };
    }

    pub inline fn getConstShell(self: *const TaskRunner) *const Self {
        return switch (self.flutter.id) {
            1 => @fieldParentPtr("task_runner_platform", self),
            2 => @fieldParentPtr("task_runner_render", self),
            else => unreachable,
        };
    }

    pub inline fn getShell(self: *TaskRunner) *Self {
        return switch (self.flutter.id) {
            1 => @fieldParentPtr("task_runner_platform", self),
            2 => @fieldParentPtr("task_runner_render", self),
            else => unreachable,
        };
    }

    pub fn postTask(self: *TaskRunner, task: flutter.Engine.ProjectArgs.CustomTaskRunners.Task, epoch: u64) !void {
        const shell = self.getShell();

        self.mutex.lock();
        defer self.mutex.unlock();

        const item = try self.queue.addOne(shell.allocator);
        errdefer _ = item.queue.pop();

        item.id = self.next_tid;
        self.next_tid += 1;

        item.queue = &self.queue;
        item.flutter = task;

        const curr = (try shell.engine_manager.getCurrentTime()) / 1000;
        const delta = epoch - curr;

        shell.loop_mutex.lock();
        defer shell.loop_mutex.unlock();

        shell.loop.timer(&item.completion, delta, item, &Task.callback);
    }
};

allocator: Allocator,
engine_manager: *flutter.Engine.Manager,
engine: *flutter.Engine,
mode: *Mode,
loop: xev.Loop,
loop_mutex: std.Thread.Mutex,
task_runners: flutter.Engine.ProjectArgs.CustomTaskRunners,
task_runner_platform: TaskRunner,
task_runner_render: TaskRunner,
thread_id: std.os.linux.pid_t,
pid: std.os.linux.pid_t,

pub fn create(alloc: Allocator, options: Options) !*Self {
    const self = try alloc.create(Self);
    errdefer alloc.destroy(self);

    self.allocator = alloc;

    self.thread_id = std.os.linux.gettid();
    self.pid = std.os.linux.getpid();

    self.loop_mutex = .{};

    self.loop = try xev.Loop.init(.{});
    errdefer self.loop.deinit();

    self.mode = try Mode.create(alloc, options.mode, &self.loop);
    errdefer self.mode.destroy();

    self.mode.shell = self;

    self.engine_manager = try flutter.Engine.Manager.loadDefault(alloc);
    errdefer self.engine_manager.destroy();

    const assets_path = try flutter.Engine.getPath(alloc, .assets);
    defer alloc.free(assets_path);

    const icudata_path = try flutter.Engine.getPath(alloc, .icu_data);
    defer alloc.free(icudata_path);

    const aot_data = if (try self.engine_manager.runsAotCompiledDartCode()) blk: {
        const elf_path = try flutter.Engine.getPath(alloc, .aot);
        defer alloc.free(elf_path);

        break :blk try self.engine_manager.createAotData(.{
            .elf_path = elf_path,
        });
    } else null;
    errdefer {
        if (aot_data) |v| v.destroy();
    }

    self.task_runner_platform.create(1);
    self.task_runner_render.create(2);

    self.task_runners = .{
        //.platform = &self.task_runner_platform.flutter,
        .render = &self.task_runner_render.flutter,
    };

    self.engine = try self.engine_manager.createEngine(.{
        .render_cfg = .{
            .software = .{
                .present = (struct {
                    fn func(user_data: ?*anyopaque, buff: [*]const u8, w: usize, h: usize) callconv(.C) bool {
                        _ = user_data;
                        const pixbuf = std.mem.bytesAsSlice(u32, buff[0..(w * h * 4)]);
                        std.debug.print("{any}\n", .{pixbuf});
                        return true;
                    }
                }).func,
            },
        },
        .project_args = .{
            .assets_path = assets_path,
            .icu_data_path = icudata_path,
            .aot_data = aot_data,
            .dart_entrypoint_args = options.args,
            .custom_dart_entrypoint = self.mode.dart_entrypoint,
            .custom_task_runners = &self.task_runners,
        },
        .user_data = self,
    });
    return self;
}

pub fn destroy(self: *Self) void {
    self.engine_manager.destroy();
    self.mode.destroy();
    self.loop.deinit();
    self.allocator.destroy(self);
}

pub fn run(self: *Self) !void {
    try self.engine.run();
    try self.mode.run();

    try self.engine.notifyDisplays();

    try self.loop.run(.until_done);
}
