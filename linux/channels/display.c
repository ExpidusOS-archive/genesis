#include <wlr/render/pixman.h>
#include <drm_fourcc.h>

#include "display.h"
#include "session.h"
#include "../application-priv.h"
#include "../messaging.h"

void xdg_surface_new(struct wl_listener* listener, void* data);
bool display_gpu_client_handle(DisplayChannel* self, struct wl_registry* registry, uint32_t id, const char* interface, uint32_t version);

static gchar* get_string(FlValue* value) {
  if (fl_value_get_type(value) != FL_VALUE_TYPE_STRING) return g_strdup("Unknown");
  return g_strdup(fl_value_get_string(value));
}

static FlValue* new_string(const gchar* str) {
  if (str == NULL || g_utf8_strlen(str, -1) == 0) return fl_value_new_null();
  return fl_value_new_string(g_strdup(str));
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

    GdkDisplay* gdk_disp = gtk_widget_get_display(GTK_WIDGET(app->win));

    DisplayChannelDisplay* disp = (DisplayChannelDisplay*)malloc(sizeof (DisplayChannelDisplay));
    disp->backend = display_channel_backend_create(gdk_disp);

    struct wl_display* wl_display = display_channel_backend_get_display(disp->backend);

    disp->socket = wl_display_add_socket_auto(wl_display);
    if (disp->socket == NULL) {
      fl_method_call_respond_error(method_call, "wayland", "failed to create socket", NULL, NULL);
      wlr_backend_destroy(disp->backend);
      free(disp);
      return;
    }

    // FIXME: EGL swap issues
    disp->renderer = wlr_renderer_autocreate(disp->backend);
    // disp->renderer = wlr_pixman_renderer_create();
    wlr_renderer_init_wl_display(disp->renderer, wl_display);

    disp->allocator = wlr_allocator_autocreate(disp->backend, disp->renderer);

    if (!wlr_backend_start(disp->backend)) {
      fl_method_call_respond_error(method_call, "wlroots", "failed to start backend", NULL, NULL);
      wlr_backend_destroy(disp->backend);
      free(disp);
      return;
    }

    disp->outputs = NULL;
    disp->toplevel_id = 1;
    disp->toplevels = g_hash_table_new_full(g_int_hash, g_int_equal, NULL, NULL);
    disp->channel = self;

    disp->compositor = wlr_compositor_create(wl_display, 5, NULL);
    wlr_subcompositor_create(wl_display);
    wlr_data_device_manager_create(wl_display);

    disp->seat = wlr_seat_create(wl_display, session_name);
    disp->xdg_shell = wlr_xdg_shell_create(wl_display, 3);

    disp->xdg_surface_new.notify = xdg_surface_new;
    wl_signal_add(&disp->xdg_shell->events.new_surface, &disp->xdg_surface_new);

    disp->prev_wl_disp = getenv("WAYLAND_DISPLAY");
    setenv("WAYLAND_DISPLAY", disp->socket, true);

    pthread_create(&disp->thread, NULL, (void *(*)(void*))wl_display_run, wl_display);
    g_hash_table_insert(self->displays, (gpointer)g_strdup(disp->socket), (gpointer)disp);

    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_string(disp->socket)));
  } else if (strcmp(fl_method_call_get_name(method_call), "stop") == 0) {
    FlValue* args = fl_method_call_get_args(method_call);
    const gchar* name = fl_value_get_string(args);

    if (!g_hash_table_contains(self->displays, name)) {
      fl_method_call_respond_error(method_call, "Linux", "Display server does not exist", NULL, NULL);
      return;
    }

    g_hash_table_remove(self->displays, name);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(NULL));
  } else if (strcmp(fl_method_call_get_name(method_call), "list") == 0) {
    g_autoptr(FlValue) list = fl_value_new_list();

    GHashTableIter iter;
    g_hash_table_iter_init(&iter, self->displays);

    gpointer key, value;
    while (g_hash_table_iter_next(&iter, &key, &value)) {
      fl_value_append(list, fl_value_new_string(g_strdup((const char*)key)));
    }

    response = FL_METHOD_RESPONSE(fl_method_success_response_new(list));
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

      struct wlr_output* output = display_channel_backend_add_output(disp->backend, width, height);
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
  } else if (strcmp(fl_method_call_get_name(method_call), "getToplevel") == 0) {
    FlValue* args = fl_method_call_get_args(method_call);
    const gchar* name = fl_value_get_string(fl_value_lookup_string(args, "name"));
    int id = fl_value_get_int(fl_value_lookup_string(args, "id"));

    if (!g_hash_table_contains(self->displays, name)) {
      fl_method_call_respond_error(method_call, "Linux", "Display server does not exist", NULL, NULL);
      return;
    }

    DisplayChannelDisplay* disp = g_hash_table_lookup(self->displays, name);

    if (!g_hash_table_contains(disp->toplevels, &id)) {
      fl_method_call_respond_error(method_call, "Linux", "Toplevel does not exist", NULL, NULL);
      return;
    }

    DisplayChannelToplevel* toplevel = g_hash_table_lookup(disp->toplevels, &id);
    g_assert(toplevel->id == id);

    g_autoptr(FlValue) value = fl_value_new_map();
    fl_value_set(value, fl_value_new_string("title"), new_string(toplevel->xdg->title));
    fl_value_set(value, fl_value_new_string("appId"), new_string(toplevel->xdg->app_id));

    if (toplevel->xdg->parent != NULL && toplevel->xdg->parent->base->data != NULL) {
      DisplayChannelToplevel* parent = (DisplayChannelToplevel*)toplevel->xdg->parent->base->data;
      fl_value_set(value, fl_value_new_string("parent"), fl_value_new_int(parent->id));
    } else {
      fl_value_set(value, fl_value_new_string("parent"), fl_value_new_null());
    }

    response = FL_METHOD_RESPONSE(fl_method_success_response_new(value));
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  g_autoptr(GError) error = NULL;
  if (!fl_method_call_respond(method_call, response, &error)) {
    g_warning("Failed to send response: %s", error->message);
  }
}

static void destroy_display(DisplayChannelDisplay* self) {
 struct wl_display* wl_display = display_channel_backend_get_display(self->backend);

  wl_display_terminate(wl_display);
  pthread_join(self->thread, NULL);

  g_clear_list(&self->outputs, (GDestroyNotify)wlr_output_destroy_global);
  g_hash_table_unref(self->toplevels);

  wlr_backend_destroy(self->backend);

  setenv("WAYLAND_DISPLAY", self->prev_wl_disp, true);
  free(self);
}

void display_channel_init(DisplayChannel* self, FlView* view) {
  self->displays = g_hash_table_new_full(g_str_hash, g_str_equal, g_free, (GDestroyNotify)destroy_display);

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  self->channel = fl_method_channel_new(fl_engine_get_binary_messenger(fl_view_get_engine(view)), "com.expidusos.genesis.shell/display", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(self->channel, method_call_handler, self, NULL);
}

void display_channel_deinit(DisplayChannel* self) {
  g_clear_object(&self->channel);
  g_hash_table_unref(self->displays);
}
