#pragma once

#include <gdk/gdk.h>

typedef struct _DisplayChannelBackend {
  void (*deinit)(struct _DisplayChannelBackend*);
  uint32_t* (*get_shm_formats)(struct _DisplayChannelBackend*, size_t* len);
} DisplayChannelBackend;

DisplayChannelBackend* display_channel_backend_init(GdkDisplay* display);
void display_channel_backend_deinit(DisplayChannelBackend* self);
uint32_t* display_channel_backend_get_shm_formats(DisplayChannelBackend* self, size_t* len);
