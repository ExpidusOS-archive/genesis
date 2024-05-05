#include <bitsdojo_window_linux/bitsdojo_window_plugin.h>

#include "application.h"
#include "application-priv.h"

#include <flutter_linux/flutter_linux.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#include "flutter/generated_plugin_registrant.h"

G_DEFINE_TYPE(GenesisShellApplication, genesis_shell_application, GTK_TYPE_APPLICATION);

// Implements GApplication::activate.
static void genesis_shell_application_activate(GApplication* application) {
  GenesisShellApplication* self = GENESIS_SHELL_APPLICATION(application);
  self->win = GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));

  auto bdw = bitsdojo_window_from(self->win);
  bdw->setCustomFrame(true);

  gtk_widget_show(GTK_WIDGET(self->win));

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(project, self->dart_entrypoint_arguments);

  self->view = fl_view_new(project);
  gtk_widget_show(GTK_WIDGET(self->view));
  gtk_container_add(GTK_CONTAINER(self->win), GTK_WIDGET(self->view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(self->view));

  account_channel_init(&self->account, self->view);
  auth_channel_init(&self->auth, self->view);
  display_channel_init(&self->display, self->view);
  outputs_channel_init(&self->outputs, self->view);
  session_channel_init(&self->session, self->view);

  gtk_widget_grab_focus(GTK_WIDGET(self->view));
}

// Implements GApplication::local_command_line.
static gboolean genesis_shell_application_local_command_line(GApplication* application, gchar*** arguments, int* exit_status) {
  GenesisShellApplication* self = GENESIS_SHELL_APPLICATION(application);
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
static void genesis_shell_application_startup(GApplication* application) {
  //GenesisShellApplication* self = GENESIS_SHELL_APPLICATION(object);

  // Perform any actions required at application startup.

  G_APPLICATION_CLASS(genesis_shell_application_parent_class)->startup(application);
}

// Implements GApplication::shutdown.
static void genesis_shell_application_shutdown(GApplication* application) {
  //GenesisShellApplication* self = GENESIS_SHELL_APPLICATION(object);

  // Perform any actions required at application shutdown.

  G_APPLICATION_CLASS(genesis_shell_application_parent_class)->shutdown(application);
}

// Implements GObject::dispose.
static void genesis_shell_application_dispose(GObject* object) {
  GenesisShellApplication* self = GENESIS_SHELL_APPLICATION(object);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);

  account_channel_deinit(&self->account);
  auth_channel_deinit(&self->auth);
  display_channel_deinit(&self->display);
  outputs_channel_deinit(&self->outputs);
  session_channel_deinit(&self->session);

  G_OBJECT_CLASS(genesis_shell_application_parent_class)->dispose(object);
}

static void genesis_shell_application_class_init(GenesisShellApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = genesis_shell_application_activate;
  G_APPLICATION_CLASS(klass)->local_command_line = genesis_shell_application_local_command_line;
  G_APPLICATION_CLASS(klass)->startup = genesis_shell_application_startup;
  G_APPLICATION_CLASS(klass)->shutdown = genesis_shell_application_shutdown;
  G_OBJECT_CLASS(klass)->dispose = genesis_shell_application_dispose;
}

static void genesis_shell_application_init(GenesisShellApplication* self) {}

GenesisShellApplication* genesis_shell_application_new() {
  return GENESIS_SHELL_APPLICATION(g_object_new(genesis_shell_application_get_type(),
                                     "application-id", APPLICATION_ID,
                                     "flags", G_APPLICATION_NON_UNIQUE,
                                     nullptr));
}
