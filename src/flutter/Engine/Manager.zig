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

pub const CreateEngineOptions = struct {
    project_args: Engine.ProjectArgs.Extern,
    render_cfg: Engine.Renderer.Config,
    user_data: ?*anyopaque = null,
};

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

pub fn loadDefault(alloc: Allocator) LoadError!*Self {
    const path = try Engine.getPath(alloc, .engine);
    defer alloc.free(path);
    return try load(alloc, path);
}

pub fn destroy(self: *Self) void {
    while (self.instances.popOrNull()) |*instance| {
        @constCast(instance).destroy();
    }

    self.instances.deinit(self.allocator);
    self.lib.close();
    self.allocator.destroy(self);
}

pub fn createAotData(self: *const Self, source: Engine.Aot.Data.Source) (Allocator.Error || Engine.Error)!Engine.Aot.Data {
    if (self.proc_table.createAotData) |func| {
        const source_extern = try source.toExtern(self.allocator);
        defer source_extern.destroy(self.allocator);

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

pub fn createEngine(self: *Self, options: CreateEngineOptions) (Allocator.Error || Engine.Error)!*Engine {
    if (self.proc_table.init) |func| {
        const instance = try self.instances.addOne(self.allocator);
        errdefer _ = self.instances.pop();

        instance.id = self.next_id;
        self.next_id += 1;

        instance.manager = self;

        const render_cfg = options.render_cfg.toExtern();
        try func(Engine.Version, &render_cfg, &options.project_args, options.user_data, &instance.ptr).err();
        return instance;
    }
    return error.InvalidFunction;
}
