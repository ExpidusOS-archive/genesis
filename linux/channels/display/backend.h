#pragma once

#include <gdk/gdk.h>

typedef struct _DisplayChannelBackend {
  void (*deinit)(struct _DisplayChannelBackend*);
  uint32_t* (*get_shm_formats)(struct _DisplayChannelBackend*, size_t* len);
  const struct wlr_linux_dmabuf_feedback_v1* (*get_default_drm_feedback)(struct _DisplayChannelBackend*);
} DisplayChannelBackend;

DisplayChannelBackend* display_channel_backend_init(GdkDisplay* display);
void display_channel_backend_deinit(DisplayChannelBackend* self);
uint32_t* display_channel_backend_get_shm_formats(DisplayChannelBackend* self, size_t* len);
const struct wlr_linux_dmabuf_feedback_v1* display_channel_backend_get_default_drm_feedback(DisplayChannelBackend* self);
