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

static void genesis_shell_wayfire_monitor_set_gamma(GenesisCommonMonitor* monitor, guint16 size, guint16* red, gint red_length, guint16* green, gint green_length, guint16* blue, gint blue_length, GError** error) {
	GenesisShellWayfireMonitor* self = GENESIS_SHELL_WAYFIRE_MONITOR(monitor);
	GenesisShellWayfireMonitorPrivate* priv = (GenesisShellWayfireMonitorPrivate*)genesis_shell_wayfire_monitor_get_instance_private(self);
	
	if (((size + red_length) - (green_length + blue_length)) != 0) {
		g_set_error(error, GENESIS_COMMON_SHELL_ERROR, GENESIS_COMMON_SHELL_ERROR_INVALID_GAMMA, "Either the red, green, or blue arrays did not match the length of gamma size");
	} else {
		g_clear_error(error);
		wlr_output_set_gamma(priv->wf_output->handle, size, red, green, blue);
	}
}

static void genesis_shell_wayfire_monitor_get_gamma(GenesisCommonMonitor* monitor, guint16* size, guint16** red, gint* red_length, guint16** green, gint* green_length, guint16** blue, gint* blue_length, GError** error) {
	GenesisShellWayfireMonitor* self = GENESIS_SHELL_WAYFIRE_MONITOR(monitor);
	GenesisShellWayfireMonitorPrivate* priv = (GenesisShellWayfireMonitorPrivate*)genesis_shell_wayfire_monitor_get_instance_private(self);
	
	g_clear_error(error);
	if (priv->wf_output->handle->pending.committed & WLR_OUTPUT_STATE_GAMMA_LUT) {	
		*size = priv->wf_output->handle->pending.gamma_lut_size;
		*red = priv->wf_output->handle->pending.gamma_lut;

		if (green != NULL) *green = NULL;
		if (green_length != NULL) *green_length = 0;
		if (blue != NULL) *blue = NULL;
		if (blue_length != NULL) *blue_length = 0;
	} else {
		if (size != NULL) *size = 0;
		if (red != NULL) *red = NULL;
		if (red_length != NULL) *red_length = 0;
		if (green != NULL) *green = NULL;
		if (green_length != NULL) *green_length = 0;
		if (blue != NULL) *blue = NULL;
		if (blue_length != NULL) *blue_length = 0;
	}
}

static void genesis_shell_wayfire_monitor_init(GenesisShellWayfireMonitor* self) {
	(void)self;
}

static void genesis_shell_wayfire_monitor_class_init(GenesisShellWayfireMonitorClass* klass) {
	GenesisCommonMonitorClass* common_monitor_class = GENESIS_COMMON_MONITOR_CLASS(klass);

	common_monitor_class->get_geometry = genesis_shell_wayfire_monitor_get_geometry;
	common_monitor_class->get_name = genesis_shell_wayfire_monitor_get_name;
	common_monitor_class->get_physical_size = genesis_shell_wayfire_monitor_get_physical_size;
	common_monitor_class->set_gamma = genesis_shell_wayfire_monitor_set_gamma;
	common_monitor_class->get_gamma = genesis_shell_wayfire_monitor_get_gamma;
}

GenesisShellMonitor* genesis_shell_wayfire_monitor_new(wf::output_t* output) {
	GenesisShellWayfireMonitor* self = GENESIS_SHELL_WAYFIRE_MONITOR(g_object_new(GENESIS_SHELL_TYPE_WAYFIRE_MONITOR, NULL));
	
	GenesisShellWayfireMonitorPrivate* priv = (GenesisShellWayfireMonitorPrivate*)genesis_shell_wayfire_monitor_get_instance_private(self);
	priv->wf_output = output;
	return GENESIS_SHELL_MONITOR(self);
}