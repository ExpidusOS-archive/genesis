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

struct _DisplayChannel;
struct _DisplayChannelDisplay;

typedef struct _DisplayChannelToplevel {
  struct _DisplayChannelDisplay* display;
  size_t id;
  struct wlr_xdg_toplevel* xdg;

  struct wl_listener map;
  struct wl_listener unmap;
  struct wl_listener destroy;
  struct wl_listener commit;

  struct wl_listener request_maximize;
  struct wl_listener request_fullscreen;
  struct wl_listener request_minimize;
  struct wl_listener request_move;
  struct wl_listener request_resize;
  struct wl_listener request_show_window_menu;
  struct wl_listener set_parent;
  struct wl_listener set_title;
  struct wl_listener set_app_id;
} DisplayChannelToplevel;

typedef struct _DisplayChannelDisplay {
  struct wl_display* display;
  struct wlr_backend* backend;
  struct wlr_compositor* compositor;
  struct wlr_shm* shm;
  struct wlr_seat* seat;
  struct wlr_xdg_shell* xdg_shell;

  const gchar* prev_wl_disp;
  pthread_t thread;
  const char* socket;
  struct _DisplayChannel* channel;

  struct wl_listener xdg_surface_new;

  GList* outputs;
  GHashTable* toplevels;
  size_t toplevel_id;
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
