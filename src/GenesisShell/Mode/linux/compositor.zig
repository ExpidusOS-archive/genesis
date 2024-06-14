const std = @import("std");
const wl = @import("wayland").server.wl;
const wlr = @import("wlroots");
const xev = @import("xev");
const Allocator = std.mem.Allocator;
const Mode = @import("../../Mode.zig");
const Output = @import("compositor/Output.zig");
const Self = @This();

mode: Mode,
wl_server: *wl.Server,
backend: *wlr.Backend,
renderer: *wlr.Renderer,
allocator: *wlr.Allocator,
socket: [11]u8,
wl_server_poll: xev.Completion,
output_layout: *wlr.OutputLayout,
output_new: wl.Listener(*wlr.Output),
outputs: std.ArrayListUnmanaged(Output),

pub fn create(alloc: Allocator, loop: *xev.Loop) !*Mode {
    const self = try alloc.create(Self);

    self.mode = .{
        .ptr = self,
        .vtable = &.{
            .destroy = destroy,
            .run = run,
        },
        .allocator = alloc,
    };

    self.outputs = .{};

    self.wl_server = try wl.Server.create();
    errdefer {
        self.wl_server.destroyClients();
        self.wl_server.destroy();
    }

    const socket = try self.wl_server.addSocketAuto(&self.socket);
    std.log.info("Wayland is on {s}", .{socket});

    self.backend = try wlr.Backend.autocreate(self.wl_server, null);

    self.output_new = wl.Listener(*wlr.Output).init(createOutput);
    self.backend.events.new_output.add(&self.output_new);

    self.renderer = try wlr.Renderer.autocreate(self.backend);
    try self.renderer.initServer(self.wl_server);

    self.allocator = try wlr.Allocator.autocreate(self.backend, self.renderer);

    self.output_layout = try wlr.OutputLayout.create();

    const event_loop = self.wl_server.getEventLoop();
    const evfd = event_loop.getFd();

    self.wl_server_poll = .{
        .op = .{
            .poll = .{
                .fd = evfd,
            },
        },
        .userdata = self,
        .callback = (struct {
            fn func(user_data: ?*anyopaque, _: *xev.Loop, _: *xev.Completion, result: xev.Result) xev.CallbackAction {
                result.poll catch |e| std.log.err("Failed to poll wayland server: {s}", .{@errorName(e)});

                const mode: *Self = @ptrCast(@alignCast(user_data.?));
                const ev_loop = mode.wl_server.getEventLoop();

                ev_loop.dispatch(-1) catch |e| std.log.err("Failed to dispatch wayland events: {s}", .{@errorName(e)});
                mode.wl_server.flushClients();
                return .rearm;
            }
        }).func,
    };

    loop.add(&self.wl_server_poll);
    return &self.mode;
}

fn addOutput(self: *Self, wlr_output: *wlr.Output) !void {
    const output = try self.outputs.addOne(self.mode.allocator);
    errdefer _ = self.outputs.pop();
    try output.init(self, wlr_output);
}

fn createOutput(listener: *wl.Listener(*wlr.Output), wlr_output: *wlr.Output) void {
    const self: *Self = @fieldParentPtr("output_new", listener);

    if (!wlr_output.initRender(self.allocator, self.renderer)) return;

    var state = wlr.Output.State.init();
    defer state.finish();

    state.setEnabled(true);

    if (wlr_output.preferredMode()) |mode| state.setMode(mode);
    if (!wlr_output.commitState(&state)) return;

    self.addOutput(wlr_output) catch |e| {
        std.log.err("Failed to add output: {s}", .{@errorName(e)});
        wlr_output.destroy();
        return;
    };
}

fn destroy(mode: *const Mode) void {
    const self: *const Self = @fieldParentPtr("mode", mode);

    self.wl_server.destroyClients();
    self.wl_server.destroy();
    mode.allocator.destroy(self);
}

fn run(mode: *const Mode) anyerror!void {
    const self: *const Self = @fieldParentPtr("mode", mode);
    try self.backend.start();
}
