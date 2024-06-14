const std = @import("std");
const builtin = @import("builtin");
const Self = @This();

pub const types = struct {
    pub usingnamespace if (builtin.os.tag == .linux) struct {
        pub const compositor = @import("Mode/linux/compositor.zig");
        pub const installer = @import("Mode/linux/installer.zig");
    } else struct {};
};

pub const default_type: ?Type = if (@hasDecl(types, "compositor")) .compositor else if (@hasDecl(types, "installer")) .installer else null;

pub const Type = std.meta.DeclEnum(types);
