#include <bitsdojo_window_linux/bitsdojo_window_plugin.h>
#include "my_application.h"

#include <flutter_linux/flutter_linux.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#include "flutter/generated_plugin_registrant.h"

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
  FlMethodChannel* outputs;
  GtkWindow* win;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

void outputs_method_call_handler(FlMethodChannel* channel, FlMethodCall* method_call, gpointer user_data) {
  MyApplication* self = MY_APPLICATION(user_data);

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

// Implements GApplication::activate.
static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);
  self->win = GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));

  auto bdw = bitsdojo_window_from(self->win);
  bdw->setCustomFrame(true);

  gtk_widget_show(GTK_WIDGET(self->win));

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(project, self->dart_entrypoint_arguments);

  FlView* view = fl_view_new(project);
  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(self->win), GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  self->outputs = fl_method_channel_new(fl_engine_get_binary_messenger(fl_view_get_engine(view)), "com.expidusos.genesis.shell/outputs", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(self->outputs, outputs_method_call_handler, self, nullptr);

  gtk_widget_grab_focus(GTK_WIDGET(view));
}

// Implements GApplication::local_command_line.
static gboolean my_application_local_command_line(GApplication* application, gchar*** arguments, int* exit_status) {
  MyApplication* self = MY_APPLICATION(application);
  // Strip out the first argument as it is the binary name.
  self->dart_entrypoint_arguments = g_strdupv(*arguments + 1);

  g_autoptr(GError) error = nullptr;
  if (!g_application_register(application, nullptr, &error)) {
     g_warning("Failed to register: %s", error->message);
     *exit_status = 1;
     return TRUE;
  }

  g_application_activate(application);
  *exit_status = 0;

  return TRUE;
}

// Implements GApplication::startup.
static void my_application_startup(GApplication* application) {
  //MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application startup.

  G_APPLICATION_CLASS(my_application_parent_class)->startup(application);
}

// Implements GApplication::shutdown.
static void my_application_shutdown(GApplication* application) {
  //MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application shutdown.

  G_APPLICATION_CLASS(my_application_parent_class)->shutdown(application);
}

// Implements GObject::dispose.
static void my_application_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  g_clear_object(&self->outputs);
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->local_command_line = my_application_local_command_line;
  G_APPLICATION_CLASS(klass)->startup = my_application_startup;
  G_APPLICATION_CLASS(klass)->shutdown = my_application_shutdown;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

static void my_application_init(MyApplication* self) {}

MyApplication* my_application_new() {
  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID,
                                     "flags", G_APPLICATION_NON_UNIQUE,
                                     nullptr));
}
