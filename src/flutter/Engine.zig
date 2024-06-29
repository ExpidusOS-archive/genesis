const std = @import("std");
const builtin = @import("builtin");
const options = @import("options");
const log = std.log.scoped(.@"flutter.Engine");
const assert = std.debug.assert;
const fs = std.fs;
const Allocator = std.mem.Allocator;
const Self = @This();

pub const Aot = @import("Engine/Aot.zig");
pub const Dart = @import("Engine/Dart.zig");
pub const Manager = @import("Engine/Manager.zig");
pub const Renderer = @import("Engine/Renderer.zig");

pub const Impl = *opaque {};
pub const Id = u64;

pub const ProjectArgs = struct {
    assets_path: []const u8,
    icu_data_path: []const u8,
    custom_dart_entrypoint: ?[]const u8 = null,
    cmd_args: ?[]const []const u8 = null,
    dart_entrypoint_args: ?[]const []const u8 = null,
    aot_data: ?Aot.Data,
    custom_task_runners: ?*const Extern.CustomTaskRunners = null,
    log_tag: ?[]const u8 = null,

    pub fn toExtern(self: *const ProjectArgs, alloc: Allocator) Allocator.Error!Extern {
        const assets_path = try alloc.dupeZ(u8, self.assets_path);
        errdefer alloc.free(assets_path);

        const icu_data_path = try alloc.dupeZ(u8, self.icu_data_path);
        errdefer alloc.free(icu_data_path);

        const log_tag = if (self.log_tag) |lt| try alloc.dupeZ(u8, lt) else null;
        errdefer {
            if (log_tag) |lt| alloc.free(lt);
        }

        const custom_dart_entrypoint = if (self.custom_dart_entrypoint) |v| try alloc.dupeZ(u8, v) else null;
        errdefer {
            if (custom_dart_entrypoint) |v| alloc.free(v);
        }

        const cmd_argv = blk: {
            if (self.cmd_args) |args| {
                var list = std.ArrayList([*:0]const u8).init(alloc);
                errdefer {
                    for (list.items) |item| alloc.free(item[0..std.mem.len(item)]);
                }
                defer list.deinit();

                for (args) |arg| {
                    const argz = try alloc.dupeZ(u8, arg);
                    errdefer alloc.free(argz);
                    try list.append(argz);
                }

                break :blk try list.toOwnedSlice();
            }
            break :blk null;
        };
        errdefer {
            if (cmd_argv) |v| {
                for (v) |i| alloc.free(i[0..std.mem.len(i)]);
                alloc.free(v);
            }
        }

        const dart_entrypoint_argv = blk: {
            if (self.dart_entrypoint_args) |args| {
                var list = std.ArrayList([*:0]const u8).init(alloc);
                errdefer {
                    for (list.items) |item| alloc.free(item[0..std.mem.len(item)]);
                }
                defer list.deinit();

                for (args) |arg| {
                    const argz = try alloc.dupeZ(u8, arg);
                    errdefer alloc.free(argz);
                    try list.append(argz);
                }

                break :blk try list.toOwnedSlice();
            }
            break :blk null;
        };
        errdefer {
            if (dart_entrypoint_argv) |v| {
                for (v) |i| alloc.free(i[0..std.mem.len(i)]);
                alloc.free(v);
            }
        }

        const aot_data = if (self.aot_data) |aot_data| aot_data.value else null;
        errdefer {
            if (aot_data) |v| v.destroy(alloc);
        }

        return .{
            .assets_path = assets_path,
            .icu_data_path = icu_data_path,
            .custom_dart_entrypoint = if (custom_dart_entrypoint) |cde| cde.ptr else null,
            .cmd_argc = if (self.cmd_args) |args| @intCast(args.len) else 0,
            .cmd_argv = if (cmd_argv) |ca| ca.ptr else null,
            .dart_entrypoint_argc = if (self.dart_entrypoint_args) |args| @intCast(args.len) else 0,
            .dart_entrypoint_argv = if (dart_entrypoint_argv) |dea| dea.ptr else null,
            .aot_data = aot_data,
            .custom_task_runners = self.custom_task_runners,
            .log_tag = if (log_tag) |lt| lt.ptr else null,
            .log_message_callback = (struct {
                fn func(tag: [*:0]const u8, message: [*:0]const u8, _: ?*anyopaque) callconv(.C) void {
                    @import("../logger.zig").tryLog(.info, tag[0..std.mem.len(tag)], "{s}", .{message}) catch return;
                }
            }).func,
        };
    }

    pub const CustomTaskRunners = Extern.CustomTaskRunners;

    pub const Extern = extern struct {
        struct_size: usize = @sizeOf(Extern),
        assets_path: [*:0]const u8,
        main_path__unused__: ?[*:0]const u8 = null,
        packages_path__unused__: ?[*:0]const u8 = null,
        icu_data_path: [*:0]const u8,
        cmd_argc: c_int = 0,
        cmd_argv: ?[*]const [*:0]const u8 = null,
        platform_message_callback: ?*const fn (*const PlatformMessage, ?*anyopaque) callconv(.C) void = null,
        vm_snapshot_data: ?[*]const u8 = null,
        vm_snapshot_data_size: usize = 0,
        vm_snapshot_instructions: ?[*]const u8 = null,
        vm_snapshot_instructions_size: usize = 0,
        isolate_snapshot_data: ?[*]const u8 = null,
        isolate_snapshot_data_size: usize = 0,
        isolate_snapshot_instructions: ?[*]const u8 = null,
        isolate_snapshot_instructions_size: usize = 0,
        root_isolate_create_callback: ?*const fn (?*anyopaque) callconv(.C) void = null,
        update_semantics_node_callback: ?*const fn (*const SemanticsNode, ?*anyopaque) callconv(.C) void = null,
        update_semantics_custom_action_callback: ?*const fn (*const SemanticsCustomAction, ?*anyopaque) callconv(.C) void = null,
        persistent_cache_path: ?[*:0]const u8 = null,
        is_persistent_cache_read_only: bool = false,
        vsync_callback: ?*const fn (?*anyopaque, *i64) callconv(.C) void = null,
        custom_dart_entrypoint: ?[*:0]const u8 = null,
        custom_task_runners: ?*const Extern.CustomTaskRunners = null,
        shutdown_dart_vm_when_done: bool = false,
        compositor: ?*const Compositor = null,
        dart_old_gen_heap_size: i64 = -1,
        aot_data: ?Aot.Data.Extern,
        compute_platform_resolved_locale_callback: ?*const fn ([*]const *Locale, usize) callconv(.C) *const Locale = null,
        dart_entrypoint_argc: c_int = 0,
        dart_entrypoint_argv: ?[*]const [*:0]const u8 = null,
        log_message_callback: ?*const fn ([*:0]const u8, [*:0]const u8, ?*anyopaque) callconv(.C) void = null,
        log_tag: ?[*:0]const u8 = null,
        on_pre_engine_restart_callback: ?*const fn (?*anyopaque) callconv(.C) void = null,
        update_semantics_callback: ?*const fn (*const SemanticsUpdate, ?*anyopaque) callconv(.C) void = null,
        update_semantics_callback2: ?*const fn (*const SemanticsUpdate2, ?*anyopaque) callconv(.C) void = null,
        channel_update_callback: ?*const fn (*const ChannelUpdate, ?*anyopaque) callconv(.C) void = null,

        pub fn destroy(self: *const Extern, alloc: Allocator) void {
            alloc.free(self.assets_path[0 .. std.mem.len(self.assets_path) + 1]);
            alloc.free(self.icu_data_path[0 .. std.mem.len(self.icu_data_path) + 1]);

            if (self.log_tag) |lt| alloc.free(lt[0 .. std.mem.len(lt) + 1]);

            if (self.cmd_argv) |argv| {
                const argc: usize = @intCast(self.cmd_argc);
                for (argv[0..argc]) |arg| alloc.free(arg[0 .. std.mem.len(arg) + 1]);
                alloc.free(argv[0..argc]);
            }

            if (self.dart_entrypoint_argv) |argv| {
                const argc: usize = @intCast(self.dart_entrypoint_argc);
                for (argv[0..argc]) |arg| alloc.free(arg[0 .. std.mem.len(arg) + 1]);
                alloc.free(argv[0..argc]);
            }

            if (self.custom_dart_entrypoint) |custom_dart_entrypoint| alloc.free(custom_dart_entrypoint[0 .. std.mem.len(custom_dart_entrypoint) + 1]);
        }

        pub const CustomTaskRunners = extern struct {
            struct_size: usize = @sizeOf(Extern.CustomTaskRunners),
            platform: ?*const TaskRunnerDescription = null,
            render: ?*const TaskRunnerDescription = null,
            thread_priority_setter: ?*const fn (ThreadPriority) callconv(.C) void = null,

            pub const TaskRunner = *opaque {};

            pub const Task = extern struct {
                runner: TaskRunner,
                task: u64,
            };

            pub const TaskRunnerDescription = extern struct {
                struct_size: usize = @sizeOf(TaskRunnerDescription),
                user_data: ?*anyopaque,
                runs_task_on_current_thread_callback: *const fn (?*anyopaque) callconv(.C) bool,
                post_task_callback: *const fn (Extern.CustomTaskRunners.Task, u64, ?*anyopaque) callconv(.C) void,
                id: usize,
            };

            pub const ThreadPriority = enum(c_int) {
                background,
                normal,
                display,
                raster,
            };
        };

        pub const Compositor = extern struct {
            struct_size: usize = @sizeOf(Compositor),
        };
    };
};

pub const SemanticsNode = extern struct {};
pub const SemanticsCustomAction = extern struct {};
pub const SemanticsUpdate = extern struct {};
pub const SemanticsUpdate2 = extern struct {};
pub const ChannelUpdate = extern struct {};

pub const Event = struct {
    pub const WindowMetrics = extern struct {
        struct_size: usize = @sizeOf(WindowMetrics),
        width: usize,
        height: usize,
        pixel_ratio: f64,
        left: usize,
        top: usize,
        physical_view_inset_top: f64,
        physical_view_inset_right: f64,
        physical_view_inset_bottom: f64,
        physical_view_inset_left: f64,
        display_id: u64,
        view_id: i64,
    };

    pub const Pointer = extern struct {};
    pub const Key = extern struct {
        pub const Callback = *const fn () callconv(.C) void;
    };
};

pub const PlatformMessage = extern struct {
    pub const ResponseHandle = opaque {};
};

pub const AccessibilityFeature = extern struct {};

pub const SemanticsAction = extern struct {};

pub const Locale = extern struct {};

pub const Display = extern struct {
    struct_size: usize = @sizeOf(Display),
    id: u64,
    is_single: bool = true,
    refresh_rate: f64,
    width: usize,
    height: usize,
    pixel_ratio: f64,

    pub const UpdateType = enum(c_int) {
        startup,
    };
};

pub const PathType = enum {
    engine,
    aot,
    assets,
    icu_data,

    pub fn filename(self: PathType) []const u8 {
        return switch (self) {
            .engine => std.fmt.comptimePrint("{s}flutter_engine{s}", .{ comptime builtin.target.libPrefix(), comptime builtin.os.tag.dynamicLibSuffix() }),
            .aot => std.fmt.comptimePrint("{s}app{s}", .{ comptime builtin.target.libPrefix(), comptime builtin.os.tag.dynamicLibSuffix() }),
            .assets => "flutter_assets",
            .icu_data => "icudtl.dat",
        };
    }
};

pub const ViewInfo = struct {
    pub const Add = extern struct {
        struct_size: usize = @sizeOf(Add),
        id: i64,
        metrics: *const Event.WindowMetrics,
        user_data: ?*anyopaque = null,
        callback: *const fn (*const Add.Result) callconv(.C) void,

        pub const Result = extern struct {
            struct_size: usize = @sizeOf(Add.Result),
            added: bool,
            user_data: ?*anyopaque = null,
        };
    };

    pub const Remove = extern struct {
        struct_size: usize = @sizeOf(Add),
        id: i64,
        user_data: ?*anyopaque = null,
        callback: *const fn (*const Remove.Result) callconv(.C) void,

        pub const Result = extern struct {
            struct_size: usize = @sizeOf(Add.Result),
            removed: bool,
            user_data: ?*anyopaque = null,
        };
    };
};

pub const GetProcAddressesFn = *const fn (*ProcTable) callconv(.C) Result;
pub const DataCallback = *const fn () callconv(.C) void;
pub const VoidCallback = *const fn (?*anyopaque) callconv(.C) void;
pub const NativeThreadCallback = *const fn () callconv(.C) void;

pub const Version: usize = 1;

pub const ProcTable = extern struct {
    struct_size: usize = @sizeOf(ProcTable),
    createAotData: ?*const fn (*const Aot.Data.Source.Extern, *Aot.Data.Extern) callconv(.C) Result = null,
    collectAotData: ?*const fn (Aot.Data.Extern) callconv(.C) Result = null,
    run: ?*const fn (usize, *const Renderer.Config.Extern, *const ProjectArgs.Extern, ?*anyopaque, *Impl) callconv(.C) Result = null,
    shutdown: ?*const fn (Impl) callconv(.C) Result = null,
    init: ?*const fn (usize, *const Renderer.Config.Extern, *const ProjectArgs.Extern, ?*anyopaque, *Impl) callconv(.C) Result = null,
    deinit: ?*const fn (Impl) callconv(.C) Result = null,
    runInit: ?*const fn (Impl) callconv(.C) Result = null,
    sendWindowMetricsEvent: ?*const fn (Impl, *const Event.WindowMetrics) callconv(.C) Result = null,
    sendPointerEvent: ?*const fn (Impl, [*]const Event.Pointer, usize) callconv(.C) Result = null,
    sendKeyEvent: ?*const fn (Impl, *const Event.Key, Event.Key.Callback, ?*anyopaque) callconv(.C) Result = null,
    sendPlatformMessage: ?*const fn (Impl, *const PlatformMessage) callconv(.C) Result = null,
    platformMessageCreateResponseHandle: ?*const fn (Impl, DataCallback, ?*anyopaque, **PlatformMessage.ResponseHandle) callconv(.C) Result = null,
    platformMessageReleaseResponseHandle: ?*const fn (Impl, *PlatformMessage.ResponseHandle) callconv(.C) Result = null,
    platformMessageSendResponse: ?*const fn (Impl, *PlatformMessage.ResponseHandle, [*]const u8, usize) callconv(.C) Result = null,
    registerExternalTexture: ?*const fn (Impl, i64) callconv(.C) Result = null,
    unregisterExternalTexture: ?*const fn (Impl, i64) callconv(.C) Result = null,
    markExternalTextureFrameAvailable: ?*const fn (Impl, i64) callconv(.C) Result = null,
    updateSemanticsEnabled: ?*const fn (Impl, bool) callconv(.C) Result = null,
    updateAccessibilityFeatures: ?*const fn (Impl, AccessibilityFeature) callconv(.C) Result = null,
    dispatchSemanticsAction: ?*const fn (Impl, u64, SemanticsAction, [*]const u8, usize) callconv(.C) Result = null,
    onVSync: ?*const fn (Impl, isize, u64, u64) callconv(.C) Result = null,
    reloadSystemFonts: ?*const fn (Impl) callconv(.C) Result = null,
    traceEventDurationBegin: ?*const fn (Impl, [*:0]const u8) callconv(.C) void = null,
    traceEventDurationEnd: ?*const fn (Impl, [*:0]const u8) callconv(.C) void = null,
    traceEventDurationInstant: ?*const fn (Impl, [*:0]const u8) callconv(.C) void = null,
    postRenderThreadTask: ?*const fn (Impl, VoidCallback, ?*anyopaque) callconv(.C) Result = null,
    getCurrentTime: ?*const fn () callconv(.C) u64 = null,
    runTask: ?*const fn (Impl, *const ProjectArgs.CustomTaskRunners.Task) callconv(.C) Result = null,
    updateLocales: ?*const fn (Impl, [*]const Locale, usize) callconv(.C) Result = null,
    runsAotCompiledDartCode: ?*const fn () callconv(.C) bool = null,
    postDartObject: ?*const fn (Impl, i64, *const Dart.Object.Extern) callconv(.C) Result = null,
    notifyLowMemoryWarning: ?*const fn (Impl) callconv(.C) Result = null,
    postCallbackOnAllNativeThreads: ?*const fn (*Impl, NativeThreadCallback, ?*anyopaque) callconv(.C) Result = null,
    notifyDisplayUpdate: ?*const fn (Impl, Display.UpdateType, [*]const Display, usize) callconv(.C) Result = null,
    scheduleFrame: ?*const fn (Impl) callconv(.C) Result = null,
    setNextFrameCallback: ?*const fn (Impl, VoidCallback, ?*anyopaque) callconv(.C) Result = null,
    addView: ?*const fn (Impl, *const ViewInfo.Add) callconv(.C) Result = null,
    removeView: ?*const fn (Impl, *const ViewInfo.Remove) callconv(.C) Result = null,
};

pub const Result = enum(u8) {
    success,
    invalid_lib_ver,
    invalid_args,
    internal_inconsistency,

    pub const Error = error{
        InvalidLibraryVersion,
        InvalidArguments,
        InternalInconsistency,
    };

    pub fn err(self: Result) Result.Error!void {
        return switch (self) {
            .success => {},
            .invalid_lib_ver => Result.Error.InvalidLibraryVersion,
            .invalid_args => Result.Error.InvalidArguments,
            .internal_inconsistency => Result.Error.InternalInconsistency,
        };
    }
};

pub const Error = Result.Error || error{InvalidFunction};

ptr: Impl,
id: Id,
manager: *Manager,
displays: std.ArrayListUnmanaged(Display) = .{},
display_mutex: std.Thread.Mutex = .{},

pub fn run(self: *const Self) Error!void {
    return if (self.manager.proc_table.runInit) |func| try func(self.ptr).err() else error.InvalidFunction;
}

pub fn runTask(self: *const Self, task: *const ProjectArgs.CustomTaskRunners.Task) Error!void {
    return if (self.manager.proc_table.runTask) |func| try func(self.ptr, task).err() else error.InvalidFunction;
}

pub fn addDisplay(self: *Self, display: Display) (Allocator.Error || error{AlreadyExists})!void {
    for (self.displays.items) |item| {
        if (item.id == display.id) return error.AlreadyExists;
    }

    self.display_mutex.lock();
    defer self.display_mutex.unlock();

    try self.displays.append(self.manager.allocator, display);
    errdefer _ = self.displays.pop();
}

pub fn updateDisplay(self: *Self, display: Display) error{NoEntry}!void {
    self.display_mutex.lock();
    defer self.display_mutex.unlock();

    for (self.displays.items) |*item| {
        if (item.id == display.id) {
            item.* = display;
            return;
        }
    }
    return error.NoEntry;
}

pub fn removeDisplay(self: *Self, id: u64) bool {
    self.display_mutex.lock();
    defer self.display_mutex.unlock();

    for (self.displays.items, 0..) |item, i| {
        if (item.id == id) {
            _ = self.displays.orderedRemove(i);
            return true;
        }
    }
    return false;
}

pub fn notifyDisplays(self: *Self) Error!void {
    self.display_mutex.lock();
    defer self.display_mutex.unlock();

    if (self.manager.proc_table.notifyDisplayUpdate) |func| {
        for (self.displays.items) |*item| {
            item.is_single = self.displays.items.len == 1;
        }

        return try func(self.ptr, .startup, self.displays.items.ptr, self.displays.items.len).err();
    }
    return error.InvalidFunction;
}

pub fn sendWindowMetricsEvent(self: *Self, event: *const Event.WindowMetrics) Error!void {
    if (self.manager.proc_table.sendWindowMetricsEvent) |func| {
        return try func(self.ptr, event).err();
    }
    return error.InvalidFunction;
}

pub fn addView(self: *Self, id: i64, metrics: *const Event.WindowMetrics) Error!void {
    if (self.manager.proc_table.addView) |func| {
        return try func(self.ptr, &ViewInfo.Add{
            .id = id,
            .metrics = metrics,
            .callback = (struct {
                fn callback(_: *const ViewInfo.Add.Result) callconv(.C) void {}
            }).callback,
        }).err();
    }
    return error.InvalidFunction;
}

pub fn removeView(self: *Self, id: i64) Error!void {
    if (self.manager.proc_table.removeView) |func| {
        return try func(self.ptr, &ViewInfo.Remove{
            .id = id,
            .callback = (struct {
                fn callback(_: *const ViewInfo.Remove.Result) callconv(.C) void {}
            }).callback,
        }).err();
    }
    return error.InvalidFunction;
}

pub fn destroy(self: *Self) void {
    assert(self.manager.proc_table.deinit != null);
    assert(self.manager.proc_table.deinit.?(self.ptr) == .success);

    self.displays.deinit(self.manager.allocator);

    for (self.manager.instances.items, 0..) |item, i| {
        if (item.id == self.id) {
            _ = self.manager.instances.orderedRemove(i);
            break;
        }
    }
}

pub fn getPath(alloc: Allocator, t: PathType) Allocator.Error![]const u8 {
    return try fs.path.join(alloc, &.{
        options.libdir,
        t.filename(),
    });
}
