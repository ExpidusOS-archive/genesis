const std = @import("std");

const streams = struct {
    pub const stderr = struct {
        pub const lock = std.debug.lockStdErr;
        pub const unlock = std.debug.unlockStdErr;

        pub inline fn detectConfig() std.io.tty.Config {
            return std.io.tty.detectConfig(std.io.getStdErr());
        }

        pub inline fn writer() std.fs.File.Writer {
            return std.io.getStdErr().writer();
        }
    };
    pub const stdout = struct {
        var mutex = std.Thread.Mutex.Recursive.init;

        pub inline fn lock() void {
            mutex.lock();
        }

        pub inline fn unlock() void {
            mutex.unlock();
        }

        pub inline fn detectConfig() std.io.tty.Config {
            return std.io.tty.detectConfig(std.io.getStdOut());
        }

        pub inline fn writer() std.fs.File.Writer {
            return std.io.getStdOut().writer();
        }
    };
};

pub const StreamTag = std.meta.DeclEnum(streams);

pub fn writeLog(
    uw: anytype,
    stream_cfg: std.io.tty.Config,
    comptime level: std.log.Level,
    scope: []const u8,
    comptime format: []const u8,
    args: anytype,
) @TypeOf(uw).Error!void {
    var bw = std.io.bufferedWriter(uw);
    const writer = bw.writer();

    nosuspend {
        if (!std.mem.eql(u8, scope, "default")) {
            try stream_cfg.setColor(writer, .dim);
            try writer.writeByte('[');
            try writer.writeAll(scope);
            try writer.writeByte(']');

            try stream_cfg.setColor(writer, .reset);
            try writer.writeByte(' ');
        }

        try stream_cfg.setColor(writer, switch (level) {
            .err => .red,
            .debug => .cyan,
            .info => .green,
            .warn => .yellow,
        });

        try writer.writeAll(level.asText());
        try stream_cfg.setColor(writer, .reset);

        try writer.writeAll(" - ");
        try writer.print(format ++ "\n", args);

        try bw.flush();
    }
}

pub fn tryLog(comptime level: std.log.Level, scope: []const u8, comptime format: []const u8, args: anytype) !void {
    const streamTag: StreamTag = comptime switch (level) {
        .err, .debug => .stderr,
        else => .stdout,
    };

    const stream = @field(streams, @tagName(streamTag));

    stream.lock();
    defer stream.unlock();

    try writeLog(stream.writer(), stream.detectConfig(), level, scope, format, args);
}

pub fn log(comptime level: std.log.Level, comptime scope: @TypeOf(.EnumLiteral), comptime format: []const u8, args: anytype) void {
    tryLog(level, @tagName(scope), format, args) catch return;
}

pub fn printErrorMessageWithTrace(
    comptime streamTag: StreamTag,
    comptime level: std.log.Level,
    scope: []const u8,
    alloc: std.mem.Allocator,
    comptime format: []const u8,
    args: anytype,
    stack_trace: std.builtin.StackTrace,
) !void {
    const stream = @field(streams, @tagName(streamTag));

    var bw = std.io.bufferedWriter(stream.writer());
    const writer = bw.writer();

    stream.lock();
    defer stream.unlock();

    try writeLog(writer, stream.detectConfig(), level, scope, format, args);

    var debug_info = try std.debug.openSelfDebugInfo(alloc);
    defer debug_info.deinit();

    try std.debug.writeStackTrace(stack_trace, writer, alloc, &debug_info, stream.detectConfig());
    try bw.flush();
}

pub fn printErrorWithTrace(
    comptime streamTag: StreamTag,
    comptime level: std.log.Level,
    scope: []const u8,
    alloc: std.mem.Allocator,
    err: anyerror,
    stack_trace: std.builtin.StackTrace,
) !void {
    try printErrorMessageWithTrace(streamTag, level, scope, alloc, "Error {s} occured", .{@errorName(err)}, stack_trace);
}
