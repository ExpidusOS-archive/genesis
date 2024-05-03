#include <flutter_linux/flutter_linux.h>

#include <wayland-util.h>

#include "outputs.h"
#include "../application-priv.h"

static FlValue* new_string(const gchar* str) {
  if (str == nullptr || g_utf8_strlen(str, -1) == 0) return fl_value_new_null();
  return fl_value_new_string(str);
}

static void method_call_handler(FlMethodChannel* channel, FlMethodCall* method_call, gpointer user_data) {
  OutputsChannel* self = (OutputsChannel*)user_data;
  GenesisShellApplication* app = wl_container_of(self, app, outputs);
  GdkDisplay* disp = gtk_widget_get_display(GTK_WIDGET(app->win));

  g_autoptr(FlMethodResponse) response = nullptr;
  if (strcmp(fl_method_call_get_name(method_call), "list") == 0) {
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
          new_string(gdk_monitor_get_model(monitor)));
      fl_value_set(
          result_monitor,
          fl_value_new_string("manufacturer"),
          new_string(gdk_monitor_get_manufacturer(monitor)));
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

static void monitor_added(GdkDisplay* disp, GdkMonitor* monitor, gpointer user_data) {
  (void)disp;
  (void)monitor;

  OutputsChannel* self = (OutputsChannel*)user_data;
  fl_method_channel_invoke_method(self->channel, "added", nullptr, nullptr, nullptr, nullptr);
}

static void monitor_removed(GdkDisplay* disp, GdkMonitor* monitor, gpointer user_data) {
  (void)disp;
  (void)monitor;

  OutputsChannel* self = (OutputsChannel*)user_data;
  fl_method_channel_invoke_method(self->channel, "removed", nullptr, nullptr, nullptr, nullptr);
}

void outputs_channel_init(OutputsChannel* self, FlView* view) {
  GenesisShellApplication* app = wl_container_of(self, app, outputs);
  GdkDisplay* disp = gtk_widget_get_display(GTK_WIDGET(app->win));

  self->monitor_added = g_signal_connect(disp, "monitor-added", G_CALLBACK(monitor_added), self);
  self->monitor_removed = g_signal_connect(disp, "monitor-removed", G_CALLBACK(monitor_removed), self);

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  self->channel = fl_method_channel_new(fl_engine_get_binary_messenger(fl_view_get_engine(view)), "com.expidusos.genesis.shell/outputs", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(self->channel, method_call_handler, self, nullptr);
}

void outputs_channel_deinit(OutputsChannel* self) {
  GenesisShellApplication* app = wl_container_of(self, app, outputs);
  GdkDisplay* disp = gtk_widget_get_display(GTK_WIDGET(app->win));

  g_signal_handler_disconnect(disp, self->monitor_added);
  g_signal_handler_disconnect(disp, self->monitor_removed);
  g_clear_object(&self->channel);
}
