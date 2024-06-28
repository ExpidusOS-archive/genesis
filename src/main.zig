const std = @import("std");
const assert = std.debug.assert;
const GenesisShell = @import("GenesisShell.zig");

pub const std_options: std.Options = .{
    .logFn = @import("logger.zig").log,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer assert(gpa.deinit() == .ok);

    const alloc = gpa.allocator();

    var args = try std.process.argsWithAllocator(alloc);
    defer args.deinit();

    var nargs = std.ArrayList([]const u8).init(alloc);
    defer {
        for (nargs.items) |item| gpa.allocator().free(item);
        nargs.deinit();
    }

    var mode: ?GenesisShell.Options.ModeType = GenesisShell.Options.default_mode;

    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "--mode")) {
            const value = args.next() orelse return error.MissingValue;
            mode = std.meta.stringToEnum(GenesisShell.Options.ModeType, value) orelse return error.InvalidValue;
        } else {
            try nargs.append(try alloc.dupe(u8, arg));
        }
    }

    const shell = try GenesisShell.create(alloc, .{
        .args = nargs.items,
        .mode = mode orelse return error.InvalidMode,
    });
    defer shell.destroy();

    try shell.run();
}
