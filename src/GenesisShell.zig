const std = @import("std");
const flutter = @import("flutter.zig");
const Allocator = std.mem.Allocator;
const Self = @This();
const Mode = @import("GenesisShell/Mode.zig");

pub const Options = struct {
    mode: ModeType,

    pub const default_mode = Mode.default_type;
    pub const ModeType = Mode.Type;
};

allocator: Allocator,
engine_manager: *flutter.Engine.Manager,
engine: *flutter.Engine,
mode: *Mode,

pub fn create(alloc: Allocator, options: Options) !*Self {
    const self = try alloc.create(Self);
    errdefer alloc.destroy(self);

    const mode = try Mode.create(alloc, options.mode);
    errdefer mode.destroy();

    const engine_manager = try flutter.Engine.Manager.loadDefault(alloc);
    errdefer engine_manager.destroy();

    const assets_path = try flutter.Engine.getPath(alloc, .assets);
    defer alloc.free(assets_path);

    const icudata_path = try flutter.Engine.getPath(alloc, .icu_data);
    defer alloc.free(icudata_path);

    const aot_data = if (try engine_manager.runsAotCompiledDartCode()) blk: {
        const elf_path = try flutter.Engine.getPath(alloc, .aot);
        defer alloc.free(elf_path);

        break :blk try engine_manager.createAotData(.{
            .elf_path = elf_path,
        });
    } else null;
    defer {
        if (aot_data) |v| v.destroy();
    }

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
            .assets_path = assets_path,
            .icu_data_path = icudata_path,
            .aot_data = aot_data,
        },
        .user_data = self,
    });

    self.* = .{
        .allocator = alloc,
        .engine_manager = engine_manager,
        .engine = engine,
        .mode = mode,
    };

    try self.engine.run();
    return self;
}

pub fn destroy(self: *Self) void {
    self.engine_manager.destroy();
    self.mode.destroy();
    self.allocator.destroy(self);
}
