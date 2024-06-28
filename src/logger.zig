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

fn tryLog(comptime level: std.log.Level, comptime scope: @TypeOf(.EnumLiteral), comptime format: []const u8, args: anytype) !void {
    const streamTag: StreamTag = comptime switch (level) {
        .err, .debug => .stderr,
        else => .stdout,
    };

    const stream = @field(streams, @tagName(streamTag));

    var bw = std.io.bufferedWriter(stream.writer());
    const writer = bw.writer();

    stream.lock();
    defer stream.unlock();

    const stream_cfg = stream.detectConfig();
    nosuspend {
        if (scope != .default) {
            try stream_cfg.setColor(writer, .dim);
            try writer.writeByte('[');
            try writer.writeAll(@tagName(scope));
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

pub fn log(comptime level: std.log.Level, comptime scope: @TypeOf(.EnumLiteral), comptime format: []const u8, args: anytype) void {
    tryLog(level, scope, format, args) catch return;
}
