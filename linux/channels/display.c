#include <drm_fourcc.h>

#include "display.h"
#include "session.h"
#include "../application-priv.h"

static gchar* get_string(FlValue* value) {
  if (fl_value_get_type(value) != FL_VALUE_TYPE_STRING) return g_strdup("Unknown");
  return g_strdup(fl_value_get_string(value));
}

static void method_call_handler(FlMethodChannel* channel, FlMethodCall* method_call, gpointer user_data) {
  DisplayChannel* self = (DisplayChannel*)user_data;

  g_autoptr(FlMethodResponse) response = NULL;
  if (strcmp(fl_method_call_get_name(method_call), "start") == 0) {
    FlValue* args = fl_method_call_get_args(method_call);
    const gchar* session_name = fl_value_get_string(fl_value_lookup_string(args, "sessionName"));

    GenesisShellApplication* app = wl_container_of(self, app, display);
    if (!g_hash_table_contains(app->session.seats, session_name)) {
      fl_method_call_respond_error(method_call, "libseat", "seat does not exist", NULL, NULL);
      return;
    }

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

    disp->outputs = NULL;

    disp->compositor = wlr_compositor_create(disp->display, 5, NULL);
    wlr_subcompositor_create(disp->display);
    wlr_data_device_manager_create(disp->display);

    size_t n_formats = 2;
    uint32_t* formats = malloc(sizeof (uint32_t) * n_formats);
    formats[0] = DRM_FORMAT_ARGB8888;
    formats[1] = DRM_FORMAT_XRGB8888;

    disp->shm = wlr_shm_create(disp->display, 1, formats, n_formats);
    disp->seat = wlr_seat_create(disp->display, session_name);
    disp->xdg_shell = wlr_xdg_shell_create(disp->display, 3);

    disp->prev_wl_disp = getenv("WAYLAND_DISPLAY");
    setenv("WAYLAND_DISPLAY", socket, true);

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
  } else if (strcmp(fl_method_call_get_name(method_call), "setOutputs") == 0) {
    FlValue* args = fl_method_call_get_args(method_call);
    const gchar* name = fl_value_get_string(fl_value_lookup_string(args, "name"));

    if (!g_hash_table_contains(self->displays, name)) {
      fl_method_call_respond_error(method_call, "Linux", "Display server does not exist", NULL, NULL);
      return;
    }

    DisplayChannelDisplay* disp = g_hash_table_lookup(self->displays, name);
    g_clear_list(&disp->outputs, (GDestroyNotify)wlr_output_destroy_global);

    FlValue* list = fl_value_lookup_string(args, "list");
    for (size_t i = 0; i < fl_value_get_length(list); i++) {
      FlValue* item = fl_value_get_list_value(list, i);
      FlValue* item_geom = fl_value_lookup_string(item, "geometry");

      int64_t width = fl_value_get_int(fl_value_lookup_string(item_geom, "width"));
      int64_t height = fl_value_get_int(fl_value_lookup_string(item_geom, "height"));

      int64_t refresh = fl_value_get_int(fl_value_lookup_string(item, "refreshRate"));
      int64_t scale = fl_value_get_int(fl_value_lookup_string(item, "scale"));

      struct wlr_output* output = wlr_headless_add_output(disp->backend, width, height);
      output->model = get_string(fl_value_lookup_string(item, "model"));
      output->make = get_string(fl_value_lookup_string(item, "manufacturer"));

      wlr_output_create_global(output);
      wlr_output_set_custom_mode(output, width, height, refresh);
      wlr_output_set_scale(output, scale);
      wlr_output_enable(output, true);
      wlr_output_commit(output);

      disp->outputs = g_list_append(disp->outputs, (gpointer)output);
    }

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

  g_clear_list(&self->outputs, (GDestroyNotify)wlr_output_destroy_global);

  wlr_backend_destroy(self->backend);
  wl_display_destroy(self->display);

  setenv("WAYLAND_DISPLAY", self->prev_wl_disp, true);
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
