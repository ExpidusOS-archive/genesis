#include <wayfire/output.hpp>
#include <wayfire/gtk-shell.hpp>
#include "window.hpp"

G_DEFINE_TYPE(GenesisShellWayfireWindow, genesis_shell_wayfire_window, GENESIS_SHELL_TYPE_WINDOW);

static const gchar* genesis_shell_wayfire_window_get_application_id(GenesisShellWindow* win) {
	auto view = genesis_shell_wayfire_window_get_wayfire_view(win);
	return g_strdup(view->get_app_id().c_str());
}

static const gchar* genesis_shell_wayfire_window_get_gtk_application_id(GenesisShellWindow* win) {
	auto view = genesis_shell_wayfire_window_get_wayfire_view(win);
	return g_strdup(get_gtk_shell_app_id(view).c_str());
}

static GenesisShellWindowRole genesis_shell_wayfire_window_get_role(GenesisShellWindow* win) {
	auto view = genesis_shell_wayfire_window_get_wayfire_view(win);

	switch (view->role) {
		case wf::VIEW_ROLE_TOPLEVEL: return GENESIS_SHELL_WINDOW_ROLE_TOPLEVEL;
		case wf::VIEW_ROLE_UNMANAGED: return GENESIS_SHELL_WINDOW_ROLE_UNMANAGED;
		case wf::VIEW_ROLE_DESKTOP_ENVIRONMENT: return GENESIS_SHELL_WINDOW_ROLE_SHELL;
	}
	return GENESIS_SHELL_WINDOW_ROLE_NONE;
}

static GenesisShellWindowFlags genesis_shell_wayfire_window_get_flags(GenesisShellWindow* win) {
	auto view = genesis_shell_wayfire_window_get_wayfire_view(win);

	uint8_t flags = 0;
	if (view->is_mapped()) flags |= GENESIS_SHELL_WINDOW_FLAGS_MAPPED;
	if (view->is_focuseable()) flags |= GENESIS_SHELL_WINDOW_FLAGS_FOCUSABLE;
	if (view->should_be_decorated()) flags |= GENESIS_SHELL_WINDOW_FLAGS_DECORATABLE;
	return (GenesisShellWindowFlags)flags;
}

static GenesisShellWindowState genesis_shell_wayfire_window_get_state(GenesisShellWindow* win) {
	auto view = genesis_shell_wayfire_window_get_wayfire_view(win);

	uint8_t state = 0;
	if (view->activated) state |= GENESIS_SHELL_WINDOW_STATE_ACTIVE;
	if (view->sticky) state |= GENESIS_SHELL_WINDOW_STATE_STICKY;
	if (view->minimized) state |= GENESIS_SHELL_WINDOW_STATE_MINIMIZED;
	if (view->tiled_edges == wf::TILED_EDGES_ALL) state |= GENESIS_SHELL_WINDOW_STATE_MAXIMIZED;
	if (view->fullscreen) state |= GENESIS_SHELL_WINDOW_STATE_FULLSCREEN;
	return (GenesisShellWindowState)state;
}

static void genesis_shell_wayfire_window_set_state(GenesisShellWindow* win, GenesisShellWindowState state) {
	auto view = genesis_shell_wayfire_window_get_wayfire_view(win);

	view->set_activated(state & GENESIS_SHELL_WINDOW_STATE_ACTIVE);
	view->set_sticky(state & GENESIS_SHELL_WINDOW_STATE_STICKY);
	view->minimize_request(state & GENESIS_SHELL_WINDOW_STATE_MINIMIZED);

	if (state & GENESIS_SHELL_WINDOW_STATE_MAXIMIZED) view->tile_request(wf::TILED_EDGES_ALL);

	view->set_fullscreen(state & GENESIS_SHELL_WINDOW_STATE_FULLSCREEN);
}

static void genesis_shell_wayfire_window_get_geometry(GenesisShellWindow* win, GdkRectangle* rect) {
	auto view = genesis_shell_wayfire_window_get_wayfire_view(win);

	auto geo = view->get_output_geometry();
	rect->x = geo.x;
	rect->y = geo.y;
	rect->width = geo.width;
	rect->height = geo.height;
}

static const gchar* genesis_shell_wayfire_window_get_monitor_name(GenesisShellWindow* win) {
	auto view = genesis_shell_wayfire_window_get_wayfire_view(win);
	return g_strdup(view->get_output()->to_string().c_str());
}

static gchar* genesis_shell_wayfire_window_to_string(GenesisShellWindow* win) {
	auto view = genesis_shell_wayfire_window_get_wayfire_view(win);
	return g_strdup(view->to_string().c_str());
}

static void genesis_shell_wayfire_window_init(GenesisShellWayfireWindow* self) {
	(void)self;
}

static void genesis_shell_wayfire_window_class_init(GenesisShellWayfireWindowClass* klass) {
	GenesisShellWindowClass* win_class = GENESIS_SHELL_WINDOW_CLASS(klass);

	win_class->get_application_id = genesis_shell_wayfire_window_get_application_id;
	win_class->get_gtk_application_id = genesis_shell_wayfire_window_get_gtk_application_id;
	win_class->get_role = genesis_shell_wayfire_window_get_role;
	win_class->get_flags = genesis_shell_wayfire_window_get_flags;
	win_class->get_state = genesis_shell_wayfire_window_get_state;
	win_class->set_state = genesis_shell_wayfire_window_set_state;
	win_class->get_geometry = genesis_shell_wayfire_window_get_geometry;
	win_class->get_monitor_name = genesis_shell_wayfire_window_get_monitor_name;
	win_class->to_string = genesis_shell_wayfire_window_to_string;
}

GenesisShellWindow* genesis_shell_wayfire_window_new(wayfire_view view) {
	GenesisShellWayfireWindow* self = GENESIS_SHELL_WAYFIRE_WINDOW(g_object_new(GENESIS_SHELL_TYPE_WAYFIRE_WINDOW, NULL));
	g_object_set_data(G_OBJECT(self), "wayfire-view", view.get());
	return GENESIS_SHELL_WINDOW(self);
}

wayfire_view genesis_shell_wayfire_window_get_wayfire_view(GenesisShellWindow* self) {
	return nonstd::observer_ptr<wf::view_interface_t>(reinterpret_cast<wf::view_interface_t*>(g_object_get_data(G_OBJECT(self), "wayfire-view")));
}