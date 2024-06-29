const std = @import("std");
const assert = std.debug.assert;
const GenesisShell = @import("GenesisShell.zig");

pub const Options = struct {
    allocator: std.mem.Allocator,
    args: std.ArrayListUnmanaged([]const u8) = .{},
    mode: ?GenesisShell.Options.ModeType = GenesisShell.Options.default_mode,
};

pub const std_options: std.Options = .{
    .logFn = @import("logger.zig").log,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer assert(gpa.deinit() == .ok);

    const alloc = gpa.allocator();

    var args = try std.process.argsWithAllocator(alloc);
    defer args.deinit();

    var options = Options{
        .allocator = alloc,
    };

    defer {
        for (options.args.items) |item| alloc.free(item);
        options.args.deinit(alloc);
    }

    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "--mode")) {
            const value = args.next() orelse return error.MissingValue;
            options.mode = std.meta.stringToEnum(GenesisShell.Options.ModeType, value) orelse return error.InvalidValue;
        } else {
            try options.args.append(alloc, try alloc.dupe(u8, arg));
        }
    }

    doMain(options) catch |e| {
        @import("logger.zig").printErrorWithTrace(.stderr, .err, "GenesisShell", alloc, e, @errorReturnTrace().?.*) catch return;
        std.process.abort();
    };
}

fn doMain(options: Options) !void {
    const shell = try GenesisShell.create(options.allocator, .{
        .args = options.args.items,
        .mode = options.mode orelse return error.InvalidMode,
    });
    defer shell.destroy();

    try shell.run();
}
