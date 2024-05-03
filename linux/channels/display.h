#pragma once

#include <flutter_linux/flutter_linux.h>
#include <wayland-server-core.h>

#ifdef __cplusplus
extern "C" {
#endif

#include <pthread.h>

#ifdef __cplusplus
#define static
#endif

#include <wlr/backend/headless.h>
#include <wayland-server.h>

#ifdef __cplusplus
#undef static
#endif

#include "../application.h"

typedef struct _DisplayChannelDisplay {
  struct wl_display* display;
  struct wlr_backend* backend;
  pthread_t thread;
} DisplayChannelDisplay;

typedef struct _DisplayChannel {
  GHashTable* displays;
  FlMethodChannel* channel;
} DisplayChannel;

void display_channel_init(DisplayChannel* self, FlView* view);
void display_channel_deinit(DisplayChannel* self);

#ifdef __cplusplus
}
#endif
