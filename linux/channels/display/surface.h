#pragma once

#include <flutter_linux/flutter_linux.h>
#include <wlr/types/wlr_compositor.h>
#include <wlr/types/wlr_xdg_shell.h>

#include "texture.h"

struct _DisplayChannel;
struct _DisplayChannelDisplay;

typedef struct _DisplayChannelSurface {
  struct _DisplayChannelDisplay* display;
  size_t id;
  int monitor;
  bool has_decor;

  struct wlr_xdg_toplevel* xdg;
  struct wlr_xdg_toplevel_decoration_v1* decor;

  struct wl_listener map;
  struct wl_listener unmap;
  struct wl_listener destroy;
  struct wl_listener new_subsurface;
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

  struct wl_listener decor_request_mode;

  DisplayChannelTexture* texture;
} DisplayChannelSurface;

void xdg_toplevel_emit_prop(DisplayChannelSurface* self, const char* name, FlValue* pvalue);
void xdg_surface_new(struct wl_listener* listener, void* data);
