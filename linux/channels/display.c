#include "display.h"
#include "../application-priv.h"

static void method_call_handler(FlMethodChannel* channel, FlMethodCall* method_call, gpointer user_data) {
  DisplayChannel* self = (DisplayChannel*)user_data;

  g_autoptr(FlMethodResponse) response = NULL;
  if (strcmp(fl_method_call_get_name(method_call), "start") == 0) {
    DisplayChannelDisplay* disp = (DisplayChannelDisplay*)malloc(sizeof (DisplayChannelDisplay));

    disp->display = wl_display_create();
    if (disp->display == NULL) {
      fl_method_call_respond_error(method_call, "wayland", "failed to create server", NULL, NULL);
      free(disp);
      return;
    }

    disp->backend = wlr_headless_backend_create(disp->display);

    const char* socket = wl_display_add_socket_auto(disp->display);
    if (socket == NULL) {
      fl_method_call_respond_error(method_call, "wayland", "failed to create socket", NULL, NULL);
      wlr_backend_destroy(disp->backend);
      wl_display_destroy(disp->display);
      free(disp);
      return;
    }

    if (!wlr_backend_start(disp->backend)) {
      fl_method_call_respond_error(method_call, "wlroots", "failed to start backend", NULL, NULL);
      wlr_backend_destroy(disp->backend);
      wl_display_destroy(disp->display);
      free(disp);
      return;
    }

    wlr_subcompositor_create(disp->display);
    wlr_data_device_manager_create(disp->display);

    pthread_create(&disp->thread, NULL, (void *(*)(void*))wl_display_run, disp->display);
    g_hash_table_insert(self->displays, (gpointer)g_strdup(socket), (gpointer)disp);

    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_string(socket)));
  } else if (strcmp(fl_method_call_get_name(method_call), "stop") == 0) {
    FlValue* args = fl_method_call_get_args(method_call);
    const gchar* name = fl_value_get_string(args);

    if (!g_hash_table_contains(self->displays, name)) {
      fl_method_call_respond_error(method_call, "Linux", "Display server does not exist", NULL, NULL);
      return;
    }

    g_hash_table_remove(self->displays, name);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(NULL));
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  g_autoptr(GError) error = NULL;
  if (!fl_method_call_respond(method_call, response, &error)) {
    g_warning("Failed to send response: %s", error->message);
  }
}

static void destory_display(DisplayChannelDisplay* self) {
  wl_display_terminate(self->display);
  pthread_join(self->thread, NULL);

  wlr_backend_destroy(self->backend);
  wl_display_destroy(self->display);
  free(self);
}

void display_channel_init(DisplayChannel* self, FlView* view) {
  self->displays = g_hash_table_new_full(g_str_hash, g_str_equal, g_free, (GDestroyNotify)destory_display);

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  self->channel = fl_method_channel_new(fl_engine_get_binary_messenger(fl_view_get_engine(view)), "com.expidusos.genesis.shell/display", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(self->channel, method_call_handler, self, NULL);
}

void display_channel_deinit(DisplayChannel* self) {
  g_clear_object(&self->channel);
  g_hash_table_unref(self->displays);
}
