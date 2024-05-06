#pragma once

#include <wlr/backend.h>
#include <gdk/gdkwayland.h>

struct wlr_backend* display_channel_backend_wayland_create(GdkWaylandDisplay*);
