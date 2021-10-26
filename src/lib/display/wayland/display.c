#include <genesis-display.h>
#include "display-private.h"

static void genesis_registry_handle_global(void* data, struct wl_registry* registry, uint32_t id, const char* iface, uint32_t version) {
	GenesisWaylandDisplayStore* self = (GenesisWaylandDisplayStore*)data;

	if (!g_strcmp0(iface, "zxdg_output_manager_v1") == 0) {
		self->xdg_output_manager = wl_registry_bind(registry, id, &zxdg_output_manager_v1_interface, version);
	}
}

static void genesis_registry_handle_global_remove(void* data, struct wl_registry* registry, uint32_t id) {}

static const struct wl_registry_listener registry_listener = {
	genesis_registry_handle_global,
	genesis_registry_handle_global_remove
};

GenesisWaylandDisplayStore* genesis_wayland_display_init_store_impl(GdkWaylandDisplay* display) {
	GenesisWaylandDisplayStore* self = g_malloc0(sizeof (GenesisWaylandDisplayStore));
	if (self != NULL) {
		self->display = display;

		struct wl_display* wl_display = gdk_wayland_display_get_wl_display(GDK_DISPLAY(display));

		self->wl_registry = wl_display_get_registry(wl_display);
		wl_registry_add_listener(self->wl_registry, &registry_listener, self);

		if (wl_display_roundtrip(wl_display) < 0) {
			g_free(self);
			return NULL;
		}
	}
	return self;
}