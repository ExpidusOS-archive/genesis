#include "monitor.hpp"

typedef struct {
	wf::output_t* wf_output;
} GenesisShellWayfireMonitorPrivate;
G_DEFINE_TYPE_WITH_PRIVATE(GenesisShellWayfireMonitor, genesis_shell_wayfire_monitor, GENESIS_SHELL_TYPE_MONITOR);

static void genesis_shell_wayfire_monitor_get_geometry(GenesisCommonMonitor* monitor, GdkRectangle* rect) {
	GenesisShellWayfireMonitor* self = GENESIS_SHELL_WAYFIRE_MONITOR(monitor);
	GenesisShellWayfireMonitorPrivate* priv = (GenesisShellWayfireMonitorPrivate*)genesis_shell_wayfire_monitor_get_instance_private(self);

	auto geo = priv->wf_output->get_layout_geometry();
	rect->x = geo.x;
	rect->y = geo.y;
	rect->width = geo.width;
	rect->height = geo.height;
}

static gchar* genesis_shell_wayfire_monitor_get_name(GenesisCommonMonitor* monitor) {
	GenesisShellWayfireMonitor* self = GENESIS_SHELL_WAYFIRE_MONITOR(monitor);
	GenesisShellWayfireMonitorPrivate* priv = (GenesisShellWayfireMonitorPrivate*)genesis_shell_wayfire_monitor_get_instance_private(self);
	return g_strdup(priv->wf_output->to_string().c_str());
}

static void genesis_shell_wayfire_monitor_get_physical_size(GenesisCommonMonitor* monitor, gint* width, gint* height) {
	GenesisShellWayfireMonitor* self = GENESIS_SHELL_WAYFIRE_MONITOR(monitor);
	GenesisShellWayfireMonitorPrivate* priv = (GenesisShellWayfireMonitorPrivate*)genesis_shell_wayfire_monitor_get_instance_private(self);

	if (width != NULL) *width = priv->wf_output->handle->phys_width;
	if (height != NULL) *height = priv->wf_output->handle->phys_height;
}

static void genesis_shell_wayfire_monitor_init(GenesisShellWayfireMonitor* self) {
	(void)self;
}

static void genesis_shell_wayfire_monitor_class_init(GenesisShellWayfireMonitorClass* klass) {
	GenesisCommonMonitorClass* common_monitor_class = GENESIS_COMMON_MONITOR_CLASS(klass);

	common_monitor_class->get_geometry = genesis_shell_wayfire_monitor_get_geometry;
	common_monitor_class->get_name = genesis_shell_wayfire_monitor_get_name;
	common_monitor_class->get_physical_size = genesis_shell_wayfire_monitor_get_physical_size;
}

GenesisShellMonitor* genesis_shell_wayfire_monitor_new(wf::output_t* output) {
	GenesisShellWayfireMonitor* self = GENESIS_SHELL_WAYFIRE_MONITOR(g_object_new(GENESIS_SHELL_TYPE_WAYFIRE_MONITOR, NULL));
	
	GenesisShellWayfireMonitorPrivate* priv = (GenesisShellWayfireMonitorPrivate*)genesis_shell_wayfire_monitor_get_instance_private(self);
	priv->wf_output = output;
	return GENESIS_SHELL_MONITOR(self);
}