#include <gdk/wayland/gdkwayland.h>
#include <genesis-display.h>
#include <xdg-output-unstable-v1-client-protocol.h>
#include "display-private.h"

typedef struct {
	int index;
	GdkRectangle workarea;
} GenesisWaylandMonitorDataStore;

typedef struct {
	GdkWaylandMonitor* monitor;
	GenesisWaylandMonitorDataStore* data;
} GenesisWaylandMonitorStore;

GenesisWaylandMonitorStore* genesis_wayland_monitor_init_store_impl(GdkWaylandMonitor* monitor, GenesisWaylandMonitorDataStore* data_store) {
	struct wl_output* output = gdk_wayland_monitor_get_wl_output(GDK_MONITOR(monitor));
	GenesisWaylandMonitorStore* self = g_malloc0(sizeof (GenesisWaylandMonitorStore));
	if (self != NULL) {
		self->monitor = monitor;
		self->data = data_store;

		GdkWaylandDisplay* disp = GDK_WAYLAND_DISPLAY(gdk_monitor_get_display(GDK_MONITOR(monitor)));
		GenesisWaylandDisplayStore* disp_store = g_object_get_data(G_OBJECT(disp), "genesis-wayland-display-store");
		if (disp_store == NULL) {
			g_free(self);
			return NULL;
		}
	}
	return self;
}