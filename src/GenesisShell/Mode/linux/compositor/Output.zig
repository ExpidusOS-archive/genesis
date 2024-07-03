const std = @import("std");
const wl = @import("wayland").server.wl;
const wlr = @import("wlroots");
const Mode = @import("../compositor.zig");
const flutter = @import("../../../../flutter.zig");
const log = std.log.scoped(.@"GenesisShell.Mode.linux.compositor.Output");
const Self = @This();

mode: *Mode,
view_id: i64,
wlr_output: *wlr.Output,
wlr_output_layout: *wlr.OutputLayout.Output,
request_state: wl.Listener(*wlr.Output.event.RequestState) = wl.Listener(*wlr.Output.event.RequestState).init(requestState),
destroy: wl.Listener(*wlr.Output) = wl.Listener(*wlr.Output).init(destroy),
frame: wl.Listener(*wlr.Output) = wl.Listener(*wlr.Output).init(frame),

pub fn init(self: *Self, mode: *Mode, wlr_output: *wlr.Output) !void {
    const output_layout = try mode.output_layout.addAuto(wlr_output);

    self.* = .{
        .mode = mode,
        .view_id = mode.next_view_id,
        .wlr_output = wlr_output,
        .wlr_output_layout = output_layout,
    };

    mode.next_view_id += 1;

    self.wlr_output.events.request_state.add(&self.request_state);
    self.wlr_output.events.destroy.add(&self.destroy);
    self.wlr_output.events.frame.add(&self.frame);

    _ = self.wlr_output.initRender(mode.allocator, mode.renderer);
    self.wlr_output.createGlobal();

    const layout_output = try mode.output_layout.addAuto(wlr_output);

    const scene_output = try mode.scene.createSceneOutput(wlr_output);
    mode.scene_output_layout.addOutput(layout_output, scene_output);

    const shell = mode.mode.getShell();
    try shell.engine.addDisplay(self.flutterDisplay());

    if (self.view_id > 0) {
        try shell.engine.addView(self.view_id, &self.windowMetrics());
    }

    try shell.engine.sendWindowMetricsEvent(&self.windowMetrics());
}

fn id(self: *const Self) u64 {
    return std.hash.Wyhash.hash(0, self.wlr_output.name[0..std.mem.len(self.wlr_output.name)]);
}

fn flutterDisplay(self: *Self) flutter.Engine.Display {
    return .{
        .id = self.id(),
        .refresh_rate = @as(f64, @floatFromInt(self.wlr_output.refresh)) / 1000.0,
        .width = @intCast(self.wlr_output.width),
        .height = @intCast(self.wlr_output.height),
        .pixel_ratio = 1.0,
    };
}

fn windowMetrics(self: *Self) flutter.Engine.Event.WindowMetrics {
    return .{
        .width = @intCast(self.wlr_output.width),
        .height = @intCast(self.wlr_output.height),
        .pixel_ratio = 1.0,
        .left = @intCast(self.wlr_output_layout.x),
        .top = @intCast(self.wlr_output_layout.y),
        .physical_view_inset_top = 0.0,
        .physical_view_inset_right = 0.0,
        .physical_view_inset_bottom = 0.0,
        .physical_view_inset_left = 0.0,
        .display_id = self.id(),
        .view_id = self.view_id,
    };
}

fn setState(self: *Self, state: *wlr.Output.State) !bool {
    const result = self.wlr_output.commitState(state);
    const shell = self.mode.mode.getShell();

    try shell.engine.updateDisplay(self.flutterDisplay());
    try shell.engine.notifyDisplays();
    try shell.engine.sendWindowMetricsEvent(&self.windowMetrics());
    return result;
}

fn requestState(listener: *wl.Listener(*wlr.Output.event.RequestState), event: *wlr.Output.event.RequestState) void {
    const self: *Self = @fieldParentPtr("request_state", listener);
    _ = self.setState(event.state) catch |e| {
        @import("../../../../logger.zig").printErrorMessageWithTrace(
            .stderr,
            .err,
            "GenesisShell.Mode.linux.compositor.Output",
            self.mode.mode.allocator,
            "Failed to set state for output {s}: {s}",
            .{ self.wlr_output.name, @errorName(e) },
            @errorReturnTrace().?.*,
        ) catch return;
    };
}

fn destroy(listener: *wl.Listener(*wlr.Output), wlr_output: *wlr.Output) void {
    const self: *Self = @fieldParentPtr("destroy", listener);

    const shell = self.mode.mode.getShell();

    if (self.view_id > 0) {
        _ = shell.engine.removeView(self.view_id) catch void;
    }

    _ = shell.engine.removeDisplay(self.id());

    self.frame.link.remove();
    self.destroy.link.remove();
    self.request_state.link.remove();

    for (self.mode.outputs.items, 0..) |output, i| {
        if (output.wlr_output == wlr_output) {
            const mode = self.mode;

            _ = mode.outputs.orderedRemove(i);

            if (mode.outputs.items.len == 0) {
                mode.mode.getShell().shutdown();
            }
            break;
        }
    }
}

fn frame(listener: *wl.Listener(*wlr.Output), _: *wlr.Output) void {
    const self: *Self = @fieldParentPtr("frame", listener);

    const scene_output = self.mode.scene.getSceneOutput(self.wlr_output).?;
    _ = scene_output.commit(null);

    var now: std.posix.timespec = undefined;
    std.posix.clock_gettime(std.posix.CLOCK.MONOTONIC, &now) catch @panic("CLOCK_MONOTONIC not supported");
    scene_output.sendFrameDone(&now);
}
