#pragma once

#include <gdk/wayland/gdkwayland.h>
#include "xdg-output-unstable-v1-client-protocol.h"

typedef struct {
	GdkWaylandDisplay* display;
	struct wl_registry* wl_registry;
	struct zxdg_output_manager_v1* xdg_output_manager;
} GenesisWaylandDisplayStore;