#pragma once

#include <GLES2/gl2.h>
#include <GLES2/gl2ext.h>
#include <stdbool.h>
#include <stdint.h>

struct wlr_gles2_pixel_format {
	uint32_t drm_format;
	// optional field, if empty then internalformat = format
	GLint gl_internalformat;
	GLint gl_format, gl_type;
	bool has_alpha;
};

struct wlr_pixel_format_info {
	uint32_t drm_format;

	/* Equivalent of the format if it has an alpha channel,
	 * DRM_FORMAT_INVALID (0) if NA
	 */
	uint32_t opaque_substitute;

	/* Bytes per block (including padding) */
	uint32_t bytes_per_block;
	/* Size of a block in pixels (zero for 1×1) */
	uint32_t block_width, block_height;

	/* True if the format has an alpha channel */
	bool has_alpha;
};

const struct wlr_gles2_pixel_format* get_gles2_format_from_drm(uint32_t fmt);
const struct wlr_pixel_format_info* drm_get_pixel_format_info(uint32_t fmt);
