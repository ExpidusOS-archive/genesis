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
#include <wlr/types/wlr_compositor.h>
#include <wlr/types/wlr_data_device.h>
#include <wlr/types/wlr_seat.h>
#include <wlr/types/wlr_shm.h>
#include <wlr/types/wlr_subcompositor.h>
#include <wlr/types/wlr_xdg_shell.h>
#include <wayland-server.h>

#ifdef __cplusplus
#undef static
#endif

#include "../application.h"

typedef struct _DisplayChannelDisplay {
  struct wl_display* display;
  struct wlr_backend* backend;
  struct wlr_compositor* compositor;
  struct wlr_shm* shm;
  struct wlr_seat* seat;
  struct wlr_xdg_shell* xdg_shell;

  const gchar* prev_wl_disp;
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
