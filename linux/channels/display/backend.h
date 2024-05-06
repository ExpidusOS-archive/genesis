#pragma once

#include <wlr/backend/interface.h>
#include <wayland-server.h>
#include <gdk/gdk.h>

typedef struct _DisplayChannelBackend {
  struct wlr_backend backend;
  struct wl_display* (*get_display)(struct _DisplayChannelBackend*);
  struct wlr_output* (*add_output)(struct _DisplayChannelBackend*, unsigned int, unsigned int);
} DisplayChannelBackend;

struct wlr_backend* display_channel_backend_create(GdkDisplay* display);
struct wl_display* display_channel_backend_get_display(struct wlr_backend* backend);
struct wlr_output* display_channel_backend_add_output(struct wlr_backend* backend, unsigned int width, unsigned int height);
