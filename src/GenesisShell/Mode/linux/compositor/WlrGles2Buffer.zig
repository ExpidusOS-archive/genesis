const std = @import("std");
const Allocator = std.mem.Allocator;
const wl = @import("wayland").server.wl;
const wlr = @import("wlroots");
const gl = @import("../../../../gl/gl3v3.zig");
const Self = @This();

const impl: wlr.Buffer.Impl = .{
    .destroy = destroy,
    .get_dmabuf = get_dmabuf,
    .get_shm = get_shm,
    .begin_data_ptr_access = begin_data_ptr_access,
    .end_data_ptr_access = end_data_ptr_access,
};

const TextureAttribs = extern struct {
    target: gl.GLenum,
    tex: gl.GLuint,
    has_alpha: bool,
};

extern fn wlr_gles2_texture_get_attribs(texture: *wlr.Texture, attribs: *TextureAttribs) callconv(.C) void;

buffer: wlr.Buffer,
backing_buffer: *wlr.Buffer,
texture: *wlr.Texture,
allocator: Allocator,
wlr_allocator: *wlr.Allocator,
wlr_renderer: *wlr.Renderer,
fbo: gl.GLuint,

pub fn create(
    alloc: Allocator,
    wlr_allocator: *wlr.Allocator,
    wlr_renderer: *wlr.Renderer,
    width: c_int,
    height: c_int,
) !*Self {
    const self = try alloc.create(Self);
    errdefer alloc.destroy(self);

    self.allocator = alloc;
    self.wlr_allocator = wlr_allocator;
    self.wlr_renderer = wlr_renderer;

    self.buffer.init(&impl, width, height);

    const formats = self.wlr_renderer.getDmabufFormats() orelse return error.NoDmabufFormats;
    const format = formats.get(0x34325241);

    self.backing_buffer = self.wlr_allocator.createBuffer(width, height, format) orelse return error.BufferCreateFailed;
    self.texture = wlr.Texture.fromBuffer(self.wlr_renderer, self.backing_buffer) orelse return error.TextureFromBufferFailed;

    var attribs: TextureAttribs = undefined;
    wlr_gles2_texture_get_attribs(self.texture, &attribs);

    gl.genFramebuffers(1, &self.fbo);
    gl.bindFramebuffer(gl.FRAMEBUFFER, self.fbo);
    gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, attribs.target, attribs.tex, 0);
    const fb_status = gl.checkFramebufferStatus(gl.FRAMEBUFFER);
    gl.bindFramebuffer(gl.FRAMEBUFFER, 0);

    if (fb_status != gl.FRAMEBUFFER_COMPLETE) return error.FramebufferIncomplete;
    return self;
}

fn destroy(buffer: *wlr.Buffer) callconv(.C) void {
    const self: *Self = @fieldParentPtr("buffer", buffer);

    gl.deleteFramebuffers(1, &self.fbo);

    self.texture.destroy();
    self.backing_buffer.drop();
    self.allocator.destroy(self);
}

fn get_dmabuf(buffer: *wlr.Buffer, attribs: *wlr.DmabufAttributes) callconv(.C) bool {
    const self: *Self = @fieldParentPtr("buffer", buffer);
    return self.backing_buffer.getDmabuf(attribs);
}

fn get_shm(buffer: *wlr.Buffer, attribs: *wlr.ShmAttributes) callconv(.C) bool {
    const self: *Self = @fieldParentPtr("buffer", buffer);
    return self.backing_buffer.getShm(attribs);
}

fn begin_data_ptr_access(buffer: *wlr.Buffer, flags: u32, data: **anyopaque, format: *u32, stride: *usize) callconv(.C) bool {
    const self: *Self = @fieldParentPtr("buffer", buffer);
    return self.backing_buffer.beginDataPtrAccess(flags, data, format, stride);
}

fn end_data_ptr_access(buffer: *wlr.Buffer) callconv(.C) void {
    const self: *Self = @fieldParentPtr("buffer", buffer);
    self.backing_buffer.endDataPtrAccess();
}
