const std = @import("std");
const wl = @import("wayland").server.wl;
const wlr = @import("wlroots");
const xev = @import("xev");
const Allocator = std.mem.Allocator;
const log = std.log.scoped(.@"GenesisShell.Mode.linux.compositor");
const GenesisShell = @import("../../../GenesisShell.zig");
const Mode = @import("../../Mode.zig");
const Output = @import("compositor/Output.zig");
const WlrCairoBuffer = @import("compositor/WlrCairoBuffer.zig");
const Self = @This();

const c = @cImport({
    @cInclude("cairo.h");
});

extern fn wlr_renderer_is_gles2(renderer: *wlr.Renderer) callconv(.C) bool;
extern fn wlr_renderer_is_pixman(renderer: *wlr.Renderer) callconv(.C) bool;

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
next_view_id: i64,
scene: *wlr.Scene,
scene_output_layout: *wlr.SceneOutputLayout,
scene_buffer: *wlr.SceneBuffer,

pub fn create(alloc: Allocator, loop: *xev.Loop) !*Mode {
    const self = try alloc.create(Self);
    errdefer alloc.destroy(self);

    self.mode = .{
        .ptr = self,
        .vtable = &.{
            .destroy = destroy,
            .run = run,
        },
        .render_cfg = undefined,
        .allocator = alloc,
    };

    self.next_view_id = 0;

    self.outputs = .{};

    self.wl_server = try wl.Server.create();
    errdefer {
        self.wl_server.destroyClients();
        self.wl_server.destroy();
    }

    const socket = try self.wl_server.addSocketAuto(&self.socket);
    log.info("Wayland is on {s}", .{socket});

    self.backend = try wlr.Backend.autocreate(self.wl_server, null);

    self.output_new = wl.Listener(*wlr.Output).init(createOutput);
    self.backend.events.new_output.add(&self.output_new);

    self.renderer = try wlr.Renderer.autocreate(self.backend);
    try self.renderer.initServer(self.wl_server);

    if (wlr_renderer_is_gles2(self.renderer)) {
        return error.NotImplemented;
    } else if (wlr_renderer_is_pixman(self.renderer)) {
        self.mode.render_cfg = .{
            .software = .{
                .present = (struct {
                    fn func(user_data: ?*anyopaque, source_buff: [*]const u8, w: usize, h: usize) callconv(.C) bool {
                        const shell: *GenesisShell = @ptrCast(@alignCast(user_data.?));
                        const mode: *Self = @fieldParentPtr("mode", shell.mode);

                        // TODO: a more efficient way of managing the buffer creation / update
                        if (mode.scene_buffer.buffer) |wlr_buff| {
                            wlr_buff.drop();
                            mode.scene_buffer.setBuffer(null);
                        }

                        const buff = WlrCairoBuffer.create(mode.mode.allocator, @intCast(w), @intCast(h)) catch |e| {
                            log.err("Failed to create a buffer: {s}", .{@errorName(e)});
                            return false;
                        };

                        // FIXME: why do we need to divide by 2 to not get a segfault?
                        const surface = c.cairo_image_surface_create_for_data(
                            @constCast(@ptrCast(source_buff)),
                            c.CAIRO_FORMAT_RGB24,
                            @intCast(w / 2),
                            @intCast(h / 2),
                            c.cairo_format_stride_for_width(c.CAIRO_FORMAT_RGB24, @intCast(w / 2)),
                        );

                        c.cairo_set_source_surface(buff.cairo, surface, 0, 0);
                        c.cairo_paint(buff.cairo);
                        c.cairo_surface_destroy(surface);

                        mode.scene_buffer.setBuffer(&buff.buffer);

                        var now: std.posix.timespec = undefined;
                        std.posix.clock_gettime(std.posix.CLOCK.MONOTONIC, &now) catch @panic("CLOCK_MONOTONIC not supported");
                        mode.scene_buffer.sendFrameDone(&now);
                        return true;
                    }
                }).func,
            },
        };
    } else {
        return error.IncompatibleRenderer;
    }

    self.allocator = try wlr.Allocator.autocreate(self.backend, self.renderer);

    self.output_layout = try wlr.OutputLayout.create();

    self.scene = try wlr.Scene.create();
    self.scene_output_layout = try self.scene.attachOutputLayout(self.output_layout);
    self.scene_buffer = try self.scene.tree.createSceneBuffer(null);

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
                result.poll catch |e| log.err("Failed to poll wayland server: {s}", .{@errorName(e)});

                const mode: *Self = @ptrCast(@alignCast(user_data.?));
                const ev_loop = mode.wl_server.getEventLoop();

                ev_loop.dispatch(-1) catch |e| log.err("Failed to dispatch wayland events: {s}", .{@errorName(e)});
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
        @import("../../../logger.zig").printErrorMessageWithTrace(
            .stderr,
            .err,
            "GenesisShell.Mode.linux.compositor",
            self.mode.allocator,
            "Failed to add output: {s}",
            .{@errorName(e)},
            @errorReturnTrace().?.*,
        ) catch {};
        wlr_output.destroy();
        return;
    };
}

fn destroy(mode: *Mode) void {
    const self: *Self = @fieldParentPtr("mode", mode);

    self.wl_server.destroyClients();
    self.wl_server.destroy();
    self.outputs.deinit(mode.allocator);

    if (self.scene_buffer.buffer) |wlr_buff| {
        wlr_buff.drop();
    }

    self.scene_buffer.node.destroy();
    mode.allocator.destroy(self);
}

fn run(mode: *const Mode) anyerror!void {
    const self: *const Self = @fieldParentPtr("mode", mode);
    try self.backend.start();
}
