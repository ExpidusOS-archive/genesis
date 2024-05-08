#include <drm_fourcc.h>
#include <GLES2/gl2.h>
#include <GLES2/gl2ext.h>
#include <wlr/config.h>
#include <string.h>

#include "pixel-format.h"

static const struct wlr_gles2_pixel_format gles2_formats[] = {
	{
		.drm_format = DRM_FORMAT_ARGB8888,
		.gl_format = GL_BGRA_EXT,
		.gl_type = GL_UNSIGNED_BYTE,
	},
	{
		.drm_format = DRM_FORMAT_XRGB8888,
		.gl_format = GL_BGRA_EXT,
		.gl_type = GL_UNSIGNED_BYTE,
	},
	{
		.drm_format = DRM_FORMAT_XBGR8888,
		.gl_format = GL_RGBA,
		.gl_type = GL_UNSIGNED_BYTE,
	},
	{
		.drm_format = DRM_FORMAT_ABGR8888,
		.gl_format = GL_RGBA,
		.gl_type = GL_UNSIGNED_BYTE,
	},
	{
		.drm_format = DRM_FORMAT_BGR888,
		.gl_format = GL_RGB,
		.gl_type = GL_UNSIGNED_BYTE,
	},
#if WLR_LITTLE_ENDIAN
	{
		.drm_format = DRM_FORMAT_RGBX4444,
		.gl_format = GL_RGBA,
		.gl_type = GL_UNSIGNED_SHORT_4_4_4_4,
	},
	{
		.drm_format = DRM_FORMAT_RGBA4444,
		.gl_format = GL_RGBA,
		.gl_type = GL_UNSIGNED_SHORT_4_4_4_4,
	},
	{
		.drm_format = DRM_FORMAT_RGBX5551,
		.gl_format = GL_RGBA,
		.gl_type = GL_UNSIGNED_SHORT_5_5_5_1,
	},
	{
		.drm_format = DRM_FORMAT_RGBA5551,
		.gl_format = GL_RGBA,
		.gl_type = GL_UNSIGNED_SHORT_5_5_5_1,
	},
	{
		.drm_format = DRM_FORMAT_RGB565,
		.gl_format = GL_RGB,
		.gl_type = GL_UNSIGNED_SHORT_5_6_5,
	},
	{
		.drm_format = DRM_FORMAT_XBGR2101010,
		.gl_format = GL_RGBA,
		.gl_type = GL_UNSIGNED_INT_2_10_10_10_REV_EXT,
	},
	{
		.drm_format = DRM_FORMAT_ABGR2101010,
		.gl_format = GL_RGBA,
		.gl_type = GL_UNSIGNED_INT_2_10_10_10_REV_EXT,
	},
	{
		.drm_format = DRM_FORMAT_XBGR16161616F,
		.gl_format = GL_RGBA,
		.gl_type = GL_HALF_FLOAT_OES,
	},
	{
		.drm_format = DRM_FORMAT_ABGR16161616F,
		.gl_format = GL_RGBA,
		.gl_type = GL_HALF_FLOAT_OES,
	},
	{
		.drm_format = DRM_FORMAT_XBGR16161616,
		.gl_internalformat = GL_RGBA16_EXT,
		.gl_format = GL_RGBA,
		.gl_type = GL_UNSIGNED_SHORT,
	},
	{
		.drm_format = DRM_FORMAT_ABGR16161616,
		.gl_internalformat = GL_RGBA16_EXT,
		.gl_format = GL_RGBA,
		.gl_type = GL_UNSIGNED_SHORT,
	},
#endif
};

static const struct wlr_pixel_format_info pixel_format_info[] = {
	{
		.drm_format = DRM_FORMAT_XRGB8888,
		.bytes_per_block = 4,
	},
	{
		.drm_format = DRM_FORMAT_ARGB8888,
		.opaque_substitute = DRM_FORMAT_XRGB8888,
		.bytes_per_block = 4,
		.has_alpha = true,
	},
	{
		.drm_format = DRM_FORMAT_XBGR8888,
		.bytes_per_block = 4,
	},
	{
		.drm_format = DRM_FORMAT_ABGR8888,
		.opaque_substitute = DRM_FORMAT_XBGR8888,
		.bytes_per_block = 4,
		.has_alpha = true,
	},
	{
		.drm_format = DRM_FORMAT_RGBX8888,
		.bytes_per_block = 4,
	},
	{
		.drm_format = DRM_FORMAT_RGBA8888,
		.opaque_substitute = DRM_FORMAT_RGBX8888,
		.bytes_per_block = 4,
		.has_alpha = true,
	},
	{
		.drm_format = DRM_FORMAT_BGRX8888,
		.bytes_per_block = 4,
	},
	{
		.drm_format = DRM_FORMAT_BGRA8888,
		.opaque_substitute = DRM_FORMAT_BGRX8888,
		.bytes_per_block = 4,
		.has_alpha = true,
	},
	{
		.drm_format = DRM_FORMAT_R8,
		.bytes_per_block = 1,
	},
	{
		.drm_format = DRM_FORMAT_GR88,
		.bytes_per_block = 2,
	},
	{
		.drm_format = DRM_FORMAT_RGB888,
		.bytes_per_block = 3,
	},
	{
		.drm_format = DRM_FORMAT_BGR888,
		.bytes_per_block = 3,
	},
	{
		.drm_format = DRM_FORMAT_RGBX4444,
		.bytes_per_block = 2,
	},
	{
		.drm_format = DRM_FORMAT_RGBA4444,
		.opaque_substitute = DRM_FORMAT_RGBX4444,
		.bytes_per_block = 2,
		.has_alpha = true,
	},
	{
		.drm_format = DRM_FORMAT_BGRX4444,
		.bytes_per_block = 2,
	},
	{
		.drm_format = DRM_FORMAT_BGRA4444,
		.opaque_substitute = DRM_FORMAT_BGRX4444,
		.bytes_per_block = 2,
		.has_alpha = true,
	},
	{
		.drm_format = DRM_FORMAT_RGBX5551,
		.bytes_per_block = 2,
	},
	{
		.drm_format = DRM_FORMAT_RGBA5551,
		.opaque_substitute = DRM_FORMAT_RGBX5551,
		.bytes_per_block = 2,
		.has_alpha = true,
	},
	{
		.drm_format = DRM_FORMAT_BGRX5551,
		.bytes_per_block = 2,
	},
	{
		.drm_format = DRM_FORMAT_BGRA5551,
		.opaque_substitute = DRM_FORMAT_BGRX5551,
		.bytes_per_block = 2,
		.has_alpha = true,
	},
	{
		.drm_format = DRM_FORMAT_XRGB1555,
		.bytes_per_block = 2,
	},
	{
		.drm_format = DRM_FORMAT_ARGB1555,
		.opaque_substitute = DRM_FORMAT_XRGB1555,
		.bytes_per_block = 2,
		.has_alpha = true,
	},
	{
		.drm_format = DRM_FORMAT_RGB565,
		.bytes_per_block = 2,
	},
	{
		.drm_format = DRM_FORMAT_BGR565,
		.bytes_per_block = 2,
	},
	{
		.drm_format = DRM_FORMAT_XRGB2101010,
		.bytes_per_block = 4,
	},
	{
		.drm_format = DRM_FORMAT_ARGB2101010,
		.opaque_substitute = DRM_FORMAT_XRGB2101010,
		.bytes_per_block = 4,
		.has_alpha = true,
	},
	{
		.drm_format = DRM_FORMAT_XBGR2101010,
		.bytes_per_block = 4,
	},
	{
		.drm_format = DRM_FORMAT_ABGR2101010,
		.opaque_substitute = DRM_FORMAT_XBGR2101010,
		.bytes_per_block = 4,
		.has_alpha = true,
	},
	{
		.drm_format = DRM_FORMAT_XBGR16161616F,
		.bytes_per_block = 8,
	},
	{
		.drm_format = DRM_FORMAT_ABGR16161616F,
		.opaque_substitute = DRM_FORMAT_XBGR16161616F,
		.bytes_per_block = 8,
		.has_alpha = true,
	},
	{
		.drm_format = DRM_FORMAT_XBGR16161616,
		.bytes_per_block = 8,
	},
	{
		.drm_format = DRM_FORMAT_ABGR16161616,
		.opaque_substitute = DRM_FORMAT_XBGR16161616,
		.bytes_per_block = 8,
		.has_alpha = true,
	},
	{
		.drm_format = DRM_FORMAT_YVYU,
		.bytes_per_block = 4,
		.block_width = 2,
		.block_height = 1,
	},
	{
		.drm_format = DRM_FORMAT_VYUY,
		.bytes_per_block = 4,
		.block_width = 2,
		.block_height = 1,
	},
};

static const size_t pixel_format_info_size = sizeof(pixel_format_info) / sizeof(pixel_format_info[0]);

const struct wlr_gles2_pixel_format* get_gles2_format_from_drm(uint32_t fmt) {
  for (size_t i = 0; i < sizeof(gles2_formats) / sizeof(*gles2_formats); ++i) {
    if (gles2_formats[i].drm_format == fmt) return &gles2_formats[i];
  }
  return NULL;
}

const struct wlr_pixel_format_info* drm_get_pixel_format_info(uint32_t fmt) {
  for (size_t i = 0; i < pixel_format_info_size; ++i) {
    if (pixel_format_info[i].drm_format == fmt) return &pixel_format_info[i];
  }
  return NULL;
}
