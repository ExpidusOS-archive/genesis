const std = @import("std");
const assert = std.debug.assert;
const FlutterEngine = @import("flutter/Engine.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer assert(gpa.deinit() == .ok);

    const mngr = try FlutterEngine.Manager.loadDefault(gpa.allocator());
    defer mngr.destroy();

    if (try mngr.runsAotCompiledDartCode()) {
        const aotPath = try FlutterEngine.getPath(gpa.allocator(), .aot);
        defer gpa.allocator().free(aotPath);

        const aot = try mngr.createAotData(.{
            .elf_path = aotPath,
        });
        defer aot.destroy();

        std.debug.print("{}", .{aot});
    } else {
        std.debug.print("{}", .{mngr});
    }
}
