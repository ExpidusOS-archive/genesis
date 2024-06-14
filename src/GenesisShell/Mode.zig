const std = @import("std");
const builtin = @import("builtin");
const xev = @import("xev");
const GenesisShell = @import("../GenesisShell.zig");
const assert = std.debug.assert;
const Allocator = std.mem.Allocator;
const Self = @This();

pub const VTable = struct {
    destroy: *const fn (*const Self) void,
    run: ?*const fn (*const Self) anyerror!void = null,
};

ptr: *anyopaque,
vtable: *const VTable,
allocator: Allocator,
dart_entrypoint: ?[]const u8 = null,
shell: ?*GenesisShell = null,

pub fn create(alloc: Allocator, t: Type, loop: *xev.Loop) !*Self {
    inline for (comptime std.meta.declarations(types)) |decl| {
        if (std.mem.eql(u8, decl.name, @tagName(t))) {
            return @field(types, decl.name).create(alloc, loop);
        }
    }
    unreachable;
}

pub inline fn run(self: *const Self) !void {
    if (self.vtable.run) |func| return func(self);
}

pub inline fn destroy(self: *const Self) void {
    self.vtable.destroy(self);
}

pub inline fn getShell(self: *const Self) *GenesisShell {
    assert(self.shell != null);
    return self.shell.?;
}

pub const types = if (builtin.os.tag == .linux) struct {
    pub const compositor = @import("Mode/linux/compositor.zig");
    pub const installer = @import("Mode/linux/installer.zig");
} else struct {};

pub const default_type: ?Type = if (@hasDecl(types, "compositor")) .compositor else if (@hasDecl(types, "installer")) .installer else null;

pub const Type = std.meta.DeclEnum(types);
