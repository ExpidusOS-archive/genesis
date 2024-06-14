const std = @import("std");
const flutter = @import("flutter.zig");
const Allocator = std.mem.Allocator;
const Self = @This();

allocator: Allocator,
engine_manager: *flutter.Engine.Manager,
engine: *flutter.Engine,

pub fn create(alloc: Allocator) !*Self {
    const self = try alloc.create(Self);
    errdefer alloc.destroy(self);

    const engine_manager = try flutter.Engine.Manager.loadDefault(alloc);
    errdefer engine_manager.destroy();

    const assets_path = try flutter.Engine.getPath(alloc, .assets);
    defer alloc.free(assets_path);

    const assets_pathZ = try alloc.dupeZ(u8, assets_path);
    defer alloc.free(assets_pathZ);

    const icudata_path = try flutter.Engine.getPath(alloc, .icu_data);
    defer alloc.free(icudata_path);

    const icudata_pathZ = try alloc.dupeZ(u8, icudata_path);
    defer alloc.free(icudata_pathZ);

    const engine = try engine_manager.createEngine(.{
        .render_cfg = .{
            .software = .{
                .present = (struct {
                    fn func(user_data: ?*anyopaque, buff: [*]const u8, w: usize, h: usize) callconv(.C) bool {
                        _ = user_data;
                        _ = buff;
                        _ = w;
                        _ = h;
                        return true;
                    }
                }).func,
            },
        },
        .project_args = .{
            .assets_path = assets_pathZ,
            .icu_data_path = icudata_pathZ,
            .aot_data = if (try engine_manager.runsAotCompiledDartCode()) blk: {
                const elf_path = try flutter.Engine.getPath(alloc, .aot);
                defer alloc.free(elf_path);

                break :blk (try engine_manager.createAotData(.{
                    .elf_path = elf_path,
                })).value;
            } else null,
        },
        .user_data = self,
    });

    self.* = .{
        .allocator = alloc,
        .engine_manager = engine_manager,
        .engine = engine,
    };

    try self.engine.run();
    return self;
}

pub fn destroy(self: *Self) void {
    self.engine_manager.destroy();
    self.allocator.destroy(self);
}
