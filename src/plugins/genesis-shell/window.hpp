#pragma once

#include <wayfire/view.hpp>
#include <genesis-common.h>
#include <genesis-shell.h>

G_BEGIN_DECLS

#define GENESIS_SHELL_TYPE_WAYFIRE_WINDOW genesis_shell_wayfire_window_get_type()
G_DECLARE_FINAL_TYPE(GenesisShellWayfireWindow, genesis_shell_wayfire_window, GENESIS_SHELL, WAYFIRE_WINDOW, GenesisShellWindow);

struct _GenesisShellWayfireWindow {
	GenesisShellWindow parent_instance;
};

GenesisShellWindow* genesis_shell_wayfire_window_new(wayfire_view view);

wayfire_view genesis_shell_wayfire_window_get_wayfire_view(GenesisShellWindow* self);

G_END_DECLS