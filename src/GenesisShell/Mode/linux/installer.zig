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
            .render_cfg = .{
                .software = .{
                    .present = (struct {
                        fn func(user_data: ?*anyopaque, buff: [*]const u8, w: usize, h: usize) callconv(.C) bool {
                            _ = user_data;
                            _ = buff;
                            _ = w;
                            _ = h;
                            //const pixbuf = std.mem.bytesAsSlice(u32, buff[0..((w / 2) * (h / 2) * 4)]);
                            //std.debug.print("{any}\n", .{pixbuf});
                            return true;
                        }
                    }).func,
                },
            },
        },
    };
    return &self.mode;
}

fn destroy(self: *const Mode) void {
    self.allocator.destroy(self);
}
