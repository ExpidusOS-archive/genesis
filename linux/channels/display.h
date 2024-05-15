#pragma once

#include <flutter_linux/flutter_linux.h>
#include <wayland-server-core.h>
#include <wayland-client-core.h>

#ifdef __cplusplus
extern "C" {
#endif

#ifdef __cplusplus
#define static
#endif

#include <wlr/render/allocator.h>
#include <wlr/types/wlr_compositor.h>
#include <wlr/types/wlr_data_device.h>
#include <wlr/types/wlr_linux_dmabuf_v1.h>
#include <wlr/types/wlr_seat.h>
#include <wlr/types/wlr_shm.h>
#include <wlr/types/wlr_subcompositor.h>
#include <wlr/types/wlr_xdg_decoration_v1.h>
#include <wlr/types/wlr_xdg_shell.h>
#include <wayland-server.h>
#include <wayland-client.h>

#include "display/backend.h"

#ifdef __cplusplus
#undef static
#endif

#include "../application.h"

typedef struct _DisplayChannelDisplay {
  struct wlr_backend* backend;
	struct wlr_allocator* allocator;

  struct wlr_compositor* compositor;
  struct wlr_seat* seat;
  struct wlr_xdg_shell* xdg_shell;
  struct wlr_xdg_decoration_manager_v1* xdg_decor;

  const gchar* prev_wl_disp;
  const char* socket;
  struct _DisplayChannel* channel;

  struct wl_listener xdg_surface_new;
  struct wl_listener toplevel_decor_new;

  GList* outputs;
  GHashTable* surfaces;
  size_t surface_id;

  GIOChannel* wl_poll;
  guint wl_poll_id;
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
