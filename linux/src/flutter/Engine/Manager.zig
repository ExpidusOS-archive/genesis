const std = @import("std");
const fs = std.fs;
const Allocator = std.mem.Allocator;
const Self = @This();
const Engine = @import("../Engine.zig");

allocator: Allocator,
lib: *anyopaque,
proc_table: Engine.ProcTable,
instances: std.ArrayListUnmanaged(Engine) = .{},
next_id: Engine.Id = 1,

pub const LoadError = Allocator.Error || Engine.Result.Error || error{Unexpected};

pub fn getDefaultPath(alloc: Allocator) (Allocator.Error || fs.SelfExePathError)![]const u8 {
    var exe_path = [_]u8{0} ** fs.MAX_PATH_BYTES;
    _ = try fs.selfExePath(&exe_path);

    return try fs.path.join(alloc, &.{
        fs.path.dirname(&exe_path).?,
        "lib",
        "libflutter_engine.so",
    });
}

pub fn load(alloc: Allocator, path: []const u8) LoadError!*Self {
    const pathZ = try alloc.dupeZ(u8, path);
    defer alloc.free(pathZ);

    const lib = std.c.dlopen(pathZ, std.c.RTLD.NOW) orelse return switch (std.posix.errno(std.c._errno().*)) {
        else => |e| std.posix.unexpectedErrno(e),
    };
    errdefer _ = std.c.dlclose(lib);

    const getProcAddresses: Engine.GetProcAddressesFn = @ptrCast(@alignCast(std.c.dlsym(lib, "FlutterEngineGetProcAddresses") orelse return switch (std.posix.errno(std.c._errno().*)) {
        else => |e| std.posix.unexpectedErrno(e),
    }));

    const self = try alloc.create(Self);
    errdefer alloc.destroy(self);

    self.* = .{
        .allocator = alloc,
        .lib = lib,
        .proc_table = .{},
    };

    try getProcAddresses(&self.proc_table).err();
    return self;
}

pub fn loadDefault(alloc: Allocator) (LoadError || fs.SelfExePathError)!*Self {
    const path = try getDefaultPath(alloc);
    defer alloc.free(path);
    return try load(alloc, path);
}

pub fn destroy(self: *Self) void {
    while (self.instances.popOrNull()) |instance| {
        _ = instance;
        // TODO: destroy
    }

    self.instances.deinit(self.allocator);
    _ = std.c.dlclose(self.lib);
    self.allocator.destroy(self);
}
