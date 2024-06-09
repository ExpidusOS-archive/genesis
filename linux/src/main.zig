const std = @import("std");
const FlutterEngine = @import("flutter/Engine.zig");

pub fn main() !void {
    const alloc = std.heap.page_allocator;

    const mngr = try FlutterEngine.Manager.loadDefault(alloc);
    defer mngr.destroy();

    std.debug.print("{}", .{mngr});
}
