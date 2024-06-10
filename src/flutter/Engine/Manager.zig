const std = @import("std");
const fs = std.fs;
const Allocator = std.mem.Allocator;
const Self = @This();
const Engine = @import("../Engine.zig");

allocator: Allocator,
lib: std.DynLib,
proc_table: Engine.ProcTable,
instances: std.ArrayListUnmanaged(Engine) = .{},
next_id: Engine.Id = 1,

pub const LoadError = Allocator.Error || Engine.Error || std.DynLib.Error || error{Unexpected};

pub fn load(alloc: Allocator, path: []const u8) LoadError!*Self {
    const pathZ = try alloc.dupeZ(u8, path);
    defer alloc.free(pathZ);

    var lib = try std.DynLib.open(path);
    errdefer lib.close();

    const getProcAddresses = lib.lookup(Engine.GetProcAddressesFn, "FlutterEngineGetProcAddresses") orelse return error.InvalidFunction;

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
    const path = try Engine.getPath(alloc, .engine);
    defer alloc.free(path);
    return try load(alloc, path);
}

pub fn destroy(self: *Self) void {
    while (self.instances.popOrNull()) |instance| {
        _ = instance;
        // TODO: destroy
    }

    self.instances.deinit(self.allocator);
    self.lib.close();
    self.allocator.destroy(self);
}

pub fn createAotData(self: *const Self, source: Engine.Aot.Data.Source) (Allocator.Error || Engine.Error)!Engine.Aot.Data {
    if (self.proc_table.createAotData) |func| {
        const source_extern = try source.toExtern(self.allocator);
        defer self.allocator.free(source_extern.value.elf_path[0..std.mem.len(source_extern.value.elf_path)]);

        var value: Engine.Aot.Data.Extern = undefined;
        try func(&source_extern, &value).err();
        return .{
            .manager = self,
            .value = value,
        };
    }
    return error.InvalidFunction;
}

pub inline fn getCurrentTime(self: *const Self) error{InvalidFunction}!u64 {
    return if (self.proc_table.getCurrentTime) |func| func() else error.InvalidFunction;
}

pub inline fn runsAotCompiledDartCode(self: *const Self) error{InvalidFunction}!bool {
    return if (self.proc_table.runsAotCompiledDartCode) |func| func() else error.InvalidFunction;
}
