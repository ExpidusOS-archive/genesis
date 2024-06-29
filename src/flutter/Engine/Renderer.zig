const std = @import("std");
const Allocator = std.mem.Allocator;

pub const Transformation = extern struct {
    scale_x: f64,
    skew_x: f64,
    trans_x: f64,
    scale_y: f64,
    skew_y: f64,
    trans_y: f64,
    pers: [3]f64,
};

pub const UintSize = extern struct {
    width: usize,
    height: usize,
};

pub const Rect = extern struct {
    left: f64,
    top: f64,
    right: f64,
    bottom: f64,
};

pub const Damage = extern struct {
    struct_size: usize = @sizeOf(Damage),
    num_rects: usize,
    rects: [*]Rect,
};

pub const FrameInfo = extern struct {
    struct_size: usize = @sizeOf(FrameInfo),
    size: UintSize,
};

pub const PresentInfo = extern struct {
    struct_size: usize = @sizeOf(PresentInfo),
    fbo: u32,
    frame_damage: Damage,
    buffer_damage: Damage,
};

pub const Config = union(Type) {
    opengl: OpenGL,
    software: Software,
    metal: Metal,
    vulkan: Vulkan,

    pub fn toExtern(self: *const Config, alloc: Allocator) Allocator.Error!Extern {
        return .{
            .type = std.meta.activeTag(self.*),
            .value = switch (self.*) {
                .vulkan => .{ .vulkan = try self.vulkan.toExtern(alloc) },
                inline else => |v, t| @unionInit(Extern.Value, @tagName(t), v.toExtern()),
            },
        };
    }

    pub const Type = enum(c_int) {
        opengl,
        software,
        metal,
        vulkan,
    };

    pub const OpenGL = struct {
        make_current: *const fn (?*anyopaque) callconv(.C) bool,
        clear_current: *const fn (?*anyopaque) callconv(.C) bool,
        present: union(enum) {
            with_info: *const fn (?*anyopaque, *const PresentInfo) callconv(.C) bool,
            default: *const fn (?*anyopaque) callconv(.C) bool,
        },
        fbo_callback: union(enum) {
            with_info: *const fn (?*anyopaque, *const FrameInfo) callconv(.C) u32,
            default: *const fn (?*anyopaque) callconv(.C) u32,
        },
        make_resource_current: ?*const fn (?*anyopaque) callconv(.C) bool,
        fbo_reset_after_present: bool,
        surface_transformation: ?*const fn (?*anyopaque) callconv(.C) Transformation,
        gl_proc_resolver: *const fn (?*anyopaque) callconv(.C) ?*anyopaque,
        gl_external_texture_frame_callback: ?*const fn (?*anyopaque, i64, usize, usize, *Extern.Value.OpenGL.Texture) callconv(.C) bool = null,
        populate_existing_damage: *const fn (?*anyopaque, *const isize, *Damage) callconv(.C) void,

        pub fn toExtern(self: *const OpenGL) Extern.Value.OpenGL {
            return .{
                .make_current = self.make_current,
                .clear_current = self.clear_current,
                .present = if (self.present == .default) self.present.default else null,
                .fbo_callback = if (self.fbo_callback == .default) self.fbo_callback.default else null,
                .make_resource_current = self.make_resource_current,
                .fbo_reset_after_present = self.fbo_reset_after_present,
                .surface_transformation = self.surface_transformation,
                .gl_proc_resolver = self.gl_proc_resolver,
                .gl_external_texture_frame_callback = self.gl_external_texture_frame_callback,
                .fbo_with_info = if (self.fbo_callback == .with_info) self.fbo_callback.with_info else null,
                .present_with_info = if (self.present == .with_info) self.present.with_info else null,
                .populate_existing_damage = self.populate_existing_damage,
            };
        }
    };

    pub const Software = struct {
        present: *const fn (?*anyopaque, [*]const u8, usize, usize) callconv(.C) bool,

        pub fn toExtern(self: *const Software) Extern.Value.Software {
            return .{
                .present = self.present,
            };
        }
    };

    pub const Metal = struct {
        device: *anyopaque,
        present_command_queue: *anyopaque,
        get_next_drawable_callback: ?*const fn (?*anyopaque, *const FrameInfo) callconv(.C) Extern.Value.Metal.Texture = null,
        present_drawable_callback: ?*const fn (?*anyopaque, *const Extern.Value.Metal.Texture) callconv(.C) bool = null,
        external_texture_frame_callback: ?*const fn (?*anyopaque, i64, usize, usize, *Extern.Value.Metal.ExternalTexture) callconv(.C) void = null,

        pub fn toExtern(self: *const Metal) Extern.Value.Metal {
            return .{
                .device = self.device,
                .present_command_queue = self.present_command_queue,
                .get_next_drawable_callback = self.get_next_drawable_callback,
                .present_drawable_callback = self.present_drawable_callback,
                .external_texture_frame_callback = self.external_texture_frame_callback,
            };
        }
    };

    pub const Vulkan = struct {
        version: u32,
        instance: *anyopaque,
        phys_dev: *anyopaque,
        dev: *anyopaque,
        queue_family_index: u32,
        queue: *anyopaque,
        enabled_instance_extensions: ?[]const []const u8 = null,
        enabled_device_extensions: ?[]const []const u8 = null,
        get_instance_proc_address_callback: *const fn (?*anyopaque, *anyopaque, [*:0]const u8) callconv(.C) ?*anyopaque,
        get_next_image_callback: ?*const fn (?*anyopaque, *const FrameInfo) callconv(.C) Extern.Value.Vulkan.Image = null,
        present_image_callback: ?*const fn (?*anyopaque, *const Extern.Value.Vulkan.Image) callconv(.C) bool = null,

        pub fn toExtern(self: *const Vulkan, alloc: Allocator) Allocator.Error!Extern.Value.Vulkan {
            const enabled_instance_extensions = blk: {
                if (self.enabled_instance_extensions) |args| {
                    var list = std.ArrayList([*:0]const u8).init(alloc);
                    errdefer {
                        for (list.items) |item| alloc.free(item[0..std.mem.len(item)]);
                    }
                    defer list.deinit();

                    for (args) |arg| {
                        const argz = try alloc.dupeZ(u8, arg);
                        errdefer alloc.free(argz);
                        try list.append(argz);
                    }

                    break :blk try list.toOwnedSlice();
                }
                break :blk null;
            };
            errdefer {
                if (enabled_instance_extensions) |v| {
                    for (v) |i| alloc.free(i[0..std.mem.len(i)]);
                    alloc.free(v);
                }
            }

            const enabled_device_extensions = blk: {
                if (self.enabled_device_extensions) |args| {
                    var list = std.ArrayList([*:0]const u8).init(alloc);
                    errdefer {
                        for (list.items) |item| alloc.free(item[0..std.mem.len(item)]);
                    }
                    defer list.deinit();

                    for (args) |arg| {
                        const argz = try alloc.dupeZ(u8, arg);
                        errdefer alloc.free(argz);
                        try list.append(argz);
                    }

                    break :blk try list.toOwnedSlice();
                }
                break :blk null;
            };
            errdefer {
                if (enabled_device_extensions) |v| {
                    for (v) |i| alloc.free(i[0..std.mem.len(i)]);
                    alloc.free(v);
                }
            }

            return .{
                .version = self.version,
                .instance = self.instance,
                .phys_dev = self.phys_dev,
                .dev = self.dev,
                .queue_family_index = self.queue_family_index,
                .queue = self.queue,
                .enabled_instance_extension_count = if (self.enabled_instance_extensions) |eie| eie.len else 0,
                .enabled_instance_extensions = if (enabled_instance_extensions) |eie| eie.ptr else null,
                .enabled_device_extension_count = if (self.enabled_device_extensions) |ede| ede.len else 0,
                .enabled_device_extensions = if (enabled_device_extensions) |ede| ede.ptr else null,
                .get_instance_proc_address_callback = self.get_instance_proc_address_callback,
                .get_next_image_callback = self.get_next_image_callback,
                .present_image_callback = self.present_image_callback,
            };
        }
    };

    pub const Extern = extern struct {
        type: Type,
        value: Value,

        pub fn destroy(self: *const Extern, alloc: Allocator) void {
            if (self.type == .vulkan) self.value.vulkan.destroy(alloc);
        }

        pub const Value = extern union {
            opengl: Value.OpenGL,
            software: Value.Software,
            metal: Value.Metal,
            vulkan: Value.Vulkan,

            pub const OpenGL = extern struct {
                struct_size: usize = @sizeOf(Value.OpenGL),
                make_current: *const fn (?*anyopaque) callconv(.C) bool,
                clear_current: *const fn (?*anyopaque) callconv(.C) bool,
                present: ?*const fn (?*anyopaque) callconv(.C) bool,
                fbo_callback: ?*const fn (?*anyopaque) callconv(.C) u32,
                make_resource_current: ?*const fn (?*anyopaque) callconv(.C) bool,
                fbo_reset_after_present: bool,
                surface_transformation: ?*const fn (?*anyopaque) callconv(.C) Transformation,
                gl_proc_resolver: *const fn (?*anyopaque) callconv(.C) ?*anyopaque,
                gl_external_texture_frame_callback: ?*const fn (?*anyopaque, i64, usize, usize, *Texture) callconv(.C) bool = null,
                fbo_with_info: ?*const fn (?*anyopaque, *const FrameInfo) callconv(.C) u32,
                present_with_info: ?*const fn (?*anyopaque, *const PresentInfo) callconv(.C) bool,
                populate_existing_damage: *const fn (?*anyopaque, *const isize, *Damage) callconv(.C) void,

                pub const Texture = extern struct {
                    target: u32,
                    name: u32,
                    fmt: u32,
                    user_data: ?*anyopaque,
                    destroy_callback: ?*const fn (?*anyopaque) callconv(.C) void,
                    width: usize,
                    height: usize,
                };
            };

            pub const Software = extern struct {
                struct_size: usize = @sizeOf(Value.Software),
                present: *const fn (?*anyopaque, [*]const u8, usize, usize) callconv(.C) bool,
            };

            pub const Metal = extern struct {
                struct_size: usize = @sizeOf(Value.Metal),
                device: *anyopaque,
                present_command_queue: *anyopaque,
                get_next_drawable_callback: ?*const fn (?*anyopaque, *const FrameInfo) callconv(.C) Texture = null,
                present_drawable_callback: ?*const fn (?*anyopaque, *const Texture) callconv(.C) bool = null,
                external_texture_frame_callback: ?*const fn (?*anyopaque, i64, usize, usize, *ExternalTexture) callconv(.C) void = null,

                pub const PixelFormat = enum(c_int) {
                    yuva,
                    rgba,
                };

                pub const YuvaColorSpace = enum(c_int) {
                    bt601_full_range,
                    bt601_limited_range,
                };

                pub const Texture = extern struct {
                    struct_size: usize = @sizeOf(Texture),
                    id: i64,
                    handle: ?*anyopaque = null,
                    user_data: ?*anyopaque = null,
                    destroy_callback: ?*const fn (?*anyopaque) callconv(.C) void,
                };

                pub const ExternalTexture = extern struct {
                    struct_size: usize = @sizeOf(ExternalTexture),
                    width: usize,
                    height: usize,
                    pixel_fmt: PixelFormat,
                    n_texts: usize,
                    texts: [*]*anyopaque,
                    yuv_color_space: YuvaColorSpace,
                };
            };

            pub const Vulkan = extern struct {
                struct_size: usize = @sizeOf(Value.Vulkan),
                version: u32,
                instance: *anyopaque,
                phys_dev: *anyopaque,
                dev: *anyopaque,
                queue_family_index: u32,
                queue: *anyopaque,
                enabled_instance_extension_count: usize = 0,
                enabled_instance_extensions: ?[*]const [*:0]const u8 = null,
                enabled_device_extension_count: usize = 0,
                enabled_device_extensions: ?[*]const [*:0]const u8 = null,
                get_instance_proc_address_callback: *const fn (?*anyopaque, *anyopaque, [*:0]const u8) callconv(.C) ?*anyopaque,
                get_next_image_callback: ?*const fn (?*anyopaque, *const FrameInfo) callconv(.C) Image = null,
                present_image_callback: ?*const fn (?*anyopaque, *const Image) callconv(.C) bool = null,

                pub fn destroy(self: *const Value.Vulkan, alloc: Allocator) void {
                    if (self.enabled_instance_extensions) |argv| {
                        const argc: usize = @intCast(self.enabled_instance_extension_count);
                        for (argv[0..argc]) |arg| alloc.free(arg[0..std.mem.len(arg)]);
                        alloc.free(argv[0..argc]);
                    }

                    if (self.enabled_device_extensions) |argv| {
                        const argc: usize = @intCast(self.enabled_device_extension_count);
                        for (argv[0..argc]) |arg| alloc.free(arg[0..std.mem.len(arg)]);
                        alloc.free(argv[0..argc]);
                    }
                }

                pub const Image = extern struct {
                    struct_size: usize = @sizeOf(Image),
                    handle: u64,
                    fmt: u32,
                };
            };
        };
    };
};
