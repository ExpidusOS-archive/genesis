#pragma once

#include <gdk/gdkwayland.h>

#include "../backend.h"

DisplayChannelBackend* display_channel_backend_wayland_init(GdkWaylandDisplay*);
