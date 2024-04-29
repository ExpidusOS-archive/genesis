#include <flutter_linux/flutter_linux.h>
#include "outputs.h"
#include "../application-priv.h"

void outputs_method_call_handler(FlMethodChannel* channel, FlMethodCall* method_call, gpointer user_data) {
  GenesisShellApplication* self = GENESIS_SHELL_APPLICATION(user_data);

  g_autoptr(FlMethodResponse) response = nullptr;
  if (strcmp(fl_method_call_get_name(method_call), "list") == 0) {
    GdkDisplay* disp = gtk_widget_get_display(GTK_WIDGET(self->win));
    g_autoptr(FlValue) result = fl_value_new_list();

    int count = gdk_display_get_n_monitors(disp);
    for (int i = 0; i < count; i++) {
      GdkMonitor* monitor = gdk_display_get_monitor(disp, i);
      if (monitor == nullptr) continue;

      GdkRectangle geom;
      gdk_monitor_get_geometry(monitor, &geom);

      g_autoptr(FlValue) result_geom = fl_value_new_map();
      fl_value_set(
          result_geom,
          fl_value_new_string("x"),
          fl_value_new_int(geom.x));
      fl_value_set(
          result_geom,
          fl_value_new_string("y"),
          fl_value_new_int(geom.y));
      fl_value_set(
          result_geom,
          fl_value_new_string("width"),
          fl_value_new_int(geom.width));
      fl_value_set(
          result_geom,
          fl_value_new_string("height"),
          fl_value_new_int(geom.height));

      g_autoptr(FlValue) result_size = fl_value_new_map();
      fl_value_set(
          result_size,
          fl_value_new_string("width"),
          fl_value_new_int(gdk_monitor_get_width_mm(monitor)));
      fl_value_set(
          result_size,
          fl_value_new_string("height"),
          fl_value_new_int(gdk_monitor_get_height_mm(monitor)));

      g_autoptr(FlValue) result_monitor = fl_value_new_map();
      fl_value_set(
          result_monitor,
          fl_value_new_string("geometry"),
          result_geom);
      fl_value_set(
          result_monitor,
          fl_value_new_string("size"),
          result_size);
      fl_value_set(
          result_monitor,
          fl_value_new_string("refreshRate"),
          fl_value_new_int(gdk_monitor_get_refresh_rate(monitor)));
      fl_value_set(
          result_monitor,
          fl_value_new_string("scale"),
          fl_value_new_int(gdk_monitor_get_scale_factor(monitor)));
      fl_value_set(
          result_monitor,
          fl_value_new_string("model"),
          fl_value_new_string(gdk_monitor_get_model(monitor)));
      fl_value_set(
          result_monitor,
          fl_value_new_string("manufacturer"),
          fl_value_new_string(gdk_monitor_get_manufacturer(monitor)));
      fl_value_set(
          result_monitor,
          fl_value_new_string("isPrimary"),
          fl_value_new_bool(gdk_monitor_is_primary(monitor)));

      fl_value_append(result, result_monitor);
    }

    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  g_autoptr(GError) error = nullptr;
  if (!fl_method_call_respond(method_call, response, &error)) {
    g_warning("Failed to send response: %s", error->message);
  }
}
