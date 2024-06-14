const std = @import("std");

pub const Transformation = extern struct {
    scale_x: f32,
    skew_x: f32,
    trans_x: f32,
    scale_y: f32,
    skew_y: f32,
    trans_y: f32,
    pers: [3]f32,
};

pub const UintSize = extern struct {
    width: usize,
    height: usize,
};

pub const Rect = extern struct {
    left: f32,
    top: f32,
    right: f32,
    bottom: f32,
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

    pub fn toExtern(self: *const Config) Extern {
        return .{
            .type = std.meta.activeTag(self.*),
            .value = switch (self.*) {
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
        gl_external_texture_frame_callback: *const fn (?*anyopaque, i64, usize, usize, *Extern.Value.OpenGL.Texture) callconv(.C) bool,
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
        pub fn toExtern(_: *const Metal) Extern.Value.Metal {
            return .{};
        }
    };

    pub const Vulkan = struct {
        pub fn toExtern(_: *const Vulkan) Extern.Value.Vulkan {
            return .{};
        }
    };

    pub const Extern = extern struct {
        type: Type,
        value: Value,

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
                gl_external_texture_frame_callback: *const fn (?*anyopaque, i64, usize, usize, *Texture) callconv(.C) bool,
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

            pub const Metal = extern struct {};
            pub const Vulkan = extern struct {};
        };
    };
};
