#pragma once

#include <wlr/types/wlr_buffer.h>
#include <flutter_linux/flutter_linux.h>

G_BEGIN_DECLS

G_DECLARE_FINAL_TYPE(DisplayChannelTexture, display_channel_texture, DISPLAY_CHANNEL, TEXTURE, FlTextureGL);

struct _DisplayChannelTexture {
  FlTextureGL parent_instance;
};

#define DISPLAY_CHANNEL_TEXTURE(obj) (G_TYPE_CHECK_INSTANCE_CAST((obj), display_channel_texture_get_type(), DisplayChannelTexture))

DisplayChannelTexture* display_channel_texture_new(GdkGLContext* gl_context, struct wlr_buffer* buffer);
void display_channel_texture_update(DisplayChannelTexture* self, struct wlr_buffer* buffer);

G_END_DECLS
