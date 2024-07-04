const std = @import("std");
const Allocator = std.mem.Allocator;
const wl = @import("wayland").server.wl;
const wlr = @import("wlroots");
const Self = @This();

const c = @cImport({
    @cInclude("cairo.h");
});

const impl: wlr.Buffer.Impl = .{
    .destroy = destroy,
    .get_dmabuf = null,
    .get_shm = null,
    .begin_data_ptr_access = begin_data_ptr_access,
    .end_data_ptr_access = end_data_ptr_access,
};

buffer: wlr.Buffer,
allocator: Allocator,
cairo_surface: *c.cairo_surface_t,
cairo: *c.cairo_t,

pub fn create(alloc: Allocator, width: c_int, height: c_int) !*Self {
    const self = try alloc.create(Self);
    errdefer alloc.destroy(self);

    self.allocator = alloc;
    self.buffer.init(&impl, width, height);

    self.cairo_surface = c.cairo_image_surface_create(c.CAIRO_FORMAT_ARGB32, width, height) orelse return error.InvalidImageSurface;
    self.cairo = c.cairo_create(self.cairo_surface) orelse return error.InvalidCairo;
    return self;
}

fn destroy(buffer: *wlr.Buffer) callconv(.C) void {
    const self: *Self = @fieldParentPtr("buffer", buffer);
    c.cairo_surface_destroy(self.cairo_surface);
    c.cairo_destroy(self.cairo);
    self.allocator.destroy(self);
}

fn begin_data_ptr_access(buffer: *wlr.Buffer, _: u32, data: **anyopaque, format: *u32, stride: *usize) callconv(.C) bool {
    const self: *Self = @fieldParentPtr("buffer", buffer);

    data.* = c.cairo_image_surface_get_data(self.cairo_surface);
    format.* = 0x34325241;
    stride.* = @intCast(c.cairo_image_surface_get_stride(self.cairo_surface));
    return true;
}

fn end_data_ptr_access(_: *wlr.Buffer) callconv(.C) void {}
