const std = @import("std");
const xev = @import("xev");
const Allocator = std.mem.Allocator;
const Mode = @import("../../Mode.zig");
const Self = @This();

mode: Mode,

pub fn create(alloc: Allocator, _: *xev.Loop) !*Mode {
    const self = try alloc.create(Self);
    self.* = .{
        .mode = .{
            .ptr = self,
            .vtable = &.{
                .destroy = destroy,
            },
            .allocator = alloc,
            .dart_entrypoint = "installerMain",
        },
    };
    return &self.mode;
}

fn destroy(self: *const Mode) void {
    self.allocator.destroy(self);
}
