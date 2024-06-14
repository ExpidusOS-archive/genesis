const std = @import("std");
const builtin = @import("builtin");
const Allocator = std.mem.Allocator;
const Self = @This();

pub const VTable = struct {
    destroy: *const fn (*const Self) void,
};

ptr: *anyopaque,
vtable: *const VTable,
allocator: Allocator,

pub fn create(alloc: Allocator, t: Type) !*Self {
    inline for (comptime std.meta.declarations(types)) |decl| {
        if (std.mem.eql(u8, decl.name, @tagName(t))) {
            return @field(types, decl.name).create(alloc);
        }
    }
    unreachable;
}

pub inline fn destroy(self: *const Self) void {
    self.vtable.destroy(self);
}

pub const types = if (builtin.os.tag == .linux) struct {
    pub const compositor = @import("Mode/linux/compositor.zig");
    pub const installer = @import("Mode/linux/installer.zig");
} else struct {};

pub const default_type: ?Type = if (@hasDecl(types, "compositor")) .compositor else if (@hasDecl(types, "installer")) .installer else null;

pub const Type = std.meta.DeclEnum(types);
