#pragma once

#include <gdk/gdk.h>

typedef struct _DisplayChannelBackend {
  void (*deinit)(struct _DisplayChannelBackend*);
} DisplayChannelBackend;

DisplayChannelBackend* display_channel_backend_init(GdkDisplay* display);
void display_channel_backend_deinit(DisplayChannelBackend* self);
