#pragma once

#include <wayfire/output.hpp>
#include <genesis-shell.h>

G_BEGIN_DECLS

#define GENESIS_SHELL_TYPE_WAYFIRE_MONITOR genesis_shell_wayfire_monitor_get_type()
G_DECLARE_FINAL_TYPE(GenesisShellWayfireMonitor, genesis_shell_wayfire_monitor, GENESIS_SHELL, WAYFIRE_MONITOR, GenesisShellMonitor);

struct _GenesisShellWayfireMonitor {
	GenesisShellMonitor parent_instance;
};

GenesisShellMonitor* genesis_shell_wayfire_monitor_new(wf::output_t* output);

G_END_DECLS