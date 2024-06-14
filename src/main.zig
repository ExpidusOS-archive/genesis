const std = @import("std");
const assert = std.debug.assert;
const GenesisShell = @import("GenesisShell.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer assert(gpa.deinit() == .ok);

    const shell = try GenesisShell.create(gpa.allocator());
    defer shell.destroy();

    std.debug.print("{}\n", .{shell});
}
