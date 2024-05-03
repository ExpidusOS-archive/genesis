#include <drm_fourcc.h>

#include "display.h"
#include "session.h"
#include "../application-priv.h"
#include "../messaging.h"

static gchar* get_string(FlValue* value) {
  if (fl_value_get_type(value) != FL_VALUE_TYPE_STRING) return g_strdup("Unknown");
  return g_strdup(fl_value_get_string(value));
}

static FlValue* new_string(const gchar* str) {
  if (str == NULL || g_utf8_strlen(str, -1) == 0) return fl_value_new_null();
  return fl_value_new_string(g_strdup(str));
}

static void xdg_toplevel_emit_request(DisplayChannelToplevel* self, const char* name) {
  g_autoptr(FlValue) value = fl_value_new_map();
  fl_value_set(value, fl_value_new_string("name"), fl_value_new_string(self->display->socket));
  fl_value_set(value, fl_value_new_string("id"), fl_value_new_int(self->id));
  fl_value_set(value, fl_value_new_string("reqName"), fl_value_new_string(name));
  invoke_method(self->display->channel->channel, "requestToplevel", value);
}

static void xdg_toplevel_emit_prop(DisplayChannelToplevel* self, const char* name, FlValue* pvalue) {
  g_autoptr(FlValue) value = fl_value_new_map();
  fl_value_set(value, fl_value_new_string("name"), fl_value_new_string(self->display->socket));
  fl_value_set(value, fl_value_new_string("id"), fl_value_new_int(self->id));
  fl_value_set(value, fl_value_new_string("propName"), fl_value_new_string(name));
  fl_value_set(value, fl_value_new_string("propValue"), pvalue);
  invoke_method(self->display->channel->channel, "notifyToplevel", value);
}

static void xdg_toplevel_map(struct wl_listener* listener, void* data) {
  (void)data;

  DisplayChannelToplevel* self = wl_container_of(listener, self, map);
  xdg_toplevel_emit_request(self, "map");
}

static void xdg_toplevel_unmap(struct wl_listener* listener, void* data) {
  (void)data;

  DisplayChannelToplevel* self = wl_container_of(listener, self, unmap);
  xdg_toplevel_emit_request(self, "unmap");
}

static void xdg_toplevel_destroy(struct wl_listener* listener, void* data) {
  (void)data;

  DisplayChannelToplevel* self = wl_container_of(listener, self, destroy);

  wl_list_remove(&self->map.link);
  wl_list_remove(&self->unmap.link);
  wl_list_remove(&self->destroy.link);
  wl_list_remove(&self->commit.link);

  wl_list_remove(&self->request_maximize.link);
  wl_list_remove(&self->request_fullscreen.link);
  wl_list_remove(&self->request_minimize.link);
  wl_list_remove(&self->request_move.link);
  wl_list_remove(&self->request_resize.link);
  wl_list_remove(&self->request_show_window_menu.link);
  wl_list_remove(&self->set_parent.link);
  wl_list_remove(&self->set_title.link);
  wl_list_remove(&self->set_app_id.link);

  g_hash_table_remove(self->display->toplevels, &self->id);

  g_autoptr(FlValue) value = fl_value_new_map();
  fl_value_set(value, fl_value_new_string("name"), fl_value_new_string(self->display->socket));
  fl_value_set(value, fl_value_new_string("id"), fl_value_new_int(self->id));
  invoke_method(self->display->channel->channel, "removeToplevel", value);

  free(self);
}

static void xdg_toplevel_commit(struct wl_listener* listener, void* data) {
  DisplayChannelToplevel* self = wl_container_of(listener, self, commit);

  if (self->xdg->base->initial_commit) {
    wlr_xdg_surface_schedule_configure(self->xdg->base);
    return;
  }

  g_message("%p", self->xdg->base->surface->buffer);
}

static void xdg_toplevel_request_maximize(struct wl_listener* listener, void* data) {
  (void)data;

  DisplayChannelToplevel* self = wl_container_of(listener, self, request_maximize);
  xdg_toplevel_emit_request(self, "maximize");
}

static void xdg_toplevel_request_fullscreen(struct wl_listener* listener, void* data) {
  (void)data;

  DisplayChannelToplevel* self = wl_container_of(listener, self, request_fullscreen);
  xdg_toplevel_emit_request(self, "fullscreen");
}

static void xdg_toplevel_request_minimize(struct wl_listener* listener, void* data) {
  (void)data;

  DisplayChannelToplevel* self = wl_container_of(listener, self, request_minimize);
  xdg_toplevel_emit_request(self, "minimize");
}

static void xdg_toplevel_request_move(struct wl_listener* listener, void* data) {
  (void)data;

  DisplayChannelToplevel* self = wl_container_of(listener, self, request_move);
  xdg_toplevel_emit_request(self, "move");
}

static void xdg_toplevel_request_resize(struct wl_listener* listener, void* data) {
  (void)data;

  DisplayChannelToplevel* self = wl_container_of(listener, self, request_resize);
  xdg_toplevel_emit_request(self, "resize");
}

static void xdg_toplevel_request_show_window_menu(struct wl_listener* listener, void* data) {
  (void)data;

  DisplayChannelToplevel* self = wl_container_of(listener, self, request_show_window_menu);
  xdg_toplevel_emit_request(self, "showWindowMenu");
}

static void xdg_toplevel_set_parent(struct wl_listener* listener, void* data) {
  (void)data;

  DisplayChannelToplevel* self = wl_container_of(listener, self, set_parent);

  if (self->xdg->parent != NULL && self->xdg->parent->base->data != NULL) {
    DisplayChannelToplevel* parent = (DisplayChannelToplevel*)self->xdg->parent->base->data;
    xdg_toplevel_emit_prop(self, "parent", fl_value_new_int(parent->id));
  } else {
    xdg_toplevel_emit_prop(self, "parent", fl_value_new_null());
  }
}

static void xdg_toplevel_set_title(struct wl_listener* listener, void* data) {
  (void)data;

  DisplayChannelToplevel* self = wl_container_of(listener, self, set_title);
  xdg_toplevel_emit_prop(self, "title", new_string(self->xdg->title));
}

static void xdg_toplevel_set_app_id(struct wl_listener* listener, void* data) {
  (void)data;

  DisplayChannelToplevel* self = wl_container_of(listener, self, set_app_id);
  xdg_toplevel_emit_prop(self, "appId", new_string(self->xdg->app_id));
}

static void xdg_surface_new(struct wl_listener* listener, void* data) {
  DisplayChannelDisplay* self = wl_container_of(listener, self, xdg_surface_new);
  struct wlr_xdg_surface* xdg_surface = data;

  if (xdg_surface->role == WLR_XDG_SURFACE_ROLE_TOPLEVEL) {
    struct wlr_xdg_toplevel* xdg_toplevel = wlr_xdg_toplevel_try_from_wlr_surface(xdg_surface->surface);

    DisplayChannelToplevel* toplevel = (DisplayChannelToplevel*)malloc(sizeof (DisplayChannelToplevel));
    toplevel->display = self;
    toplevel->xdg = xdg_toplevel;
    toplevel->id = self->toplevel_id++;
    g_hash_table_insert(self->toplevels, &toplevel->id, self);

    g_autoptr(FlValue) value = fl_value_new_map();
    fl_value_set(value, fl_value_new_string("name"), fl_value_new_string(self->socket));
    fl_value_set(value, fl_value_new_string("id"), fl_value_new_int(toplevel->id));
    invoke_method(self->channel->channel, "newToplevel", value);

    toplevel->map.notify = xdg_toplevel_map;
    wl_signal_add(&xdg_surface->surface->events.map, &toplevel->map);

    toplevel->unmap.notify = xdg_toplevel_unmap;
    wl_signal_add(&xdg_surface->surface->events.unmap, &toplevel->unmap);

    toplevel->destroy.notify = xdg_toplevel_destroy;
    wl_signal_add(&xdg_surface->surface->events.destroy, &toplevel->destroy);

    toplevel->commit.notify = xdg_toplevel_commit;
    wl_signal_add(&xdg_surface->surface->events.commit, &toplevel->commit);

    toplevel->request_maximize.notify = xdg_toplevel_request_maximize;
    wl_signal_add(&xdg_toplevel->events.request_maximize, &toplevel->request_maximize);

    toplevel->request_fullscreen.notify = xdg_toplevel_request_fullscreen;
    wl_signal_add(&xdg_toplevel->events.request_fullscreen, &toplevel->request_fullscreen);

    toplevel->request_minimize.notify = xdg_toplevel_request_minimize;
    wl_signal_add(&xdg_toplevel->events.request_minimize, &toplevel->request_minimize);

    toplevel->request_move.notify = xdg_toplevel_request_move;
    wl_signal_add(&xdg_toplevel->events.request_move, &toplevel->request_move);

    toplevel->request_resize.notify = xdg_toplevel_request_resize;
    wl_signal_add(&xdg_toplevel->events.request_resize, &toplevel->request_resize);

    toplevel->request_show_window_menu.notify = xdg_toplevel_request_show_window_menu;
    wl_signal_add(&xdg_toplevel->events.request_show_window_menu, &toplevel->request_show_window_menu);

    toplevel->set_parent.notify = xdg_toplevel_set_parent;
    wl_signal_add(&xdg_toplevel->events.set_parent, &toplevel->set_parent);

    toplevel->set_title.notify = xdg_toplevel_set_title;
    wl_signal_add(&xdg_toplevel->events.set_title, &toplevel->set_title);

    toplevel->set_app_id.notify = xdg_toplevel_set_app_id;
    wl_signal_add(&xdg_toplevel->events.set_app_id, &toplevel->set_app_id);
  }
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

    disp->socket = wl_display_add_socket_auto(disp->display);
    if (disp->socket == NULL) {
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
    disp->toplevel_id = 1;
    disp->toplevels = g_hash_table_new_full(g_int_hash, g_int_equal, NULL, NULL);
    disp->channel = self;

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

    disp->xdg_surface_new.notify = xdg_surface_new;
    wl_signal_add(&disp->xdg_shell->events.new_surface, &disp->xdg_surface_new);

    disp->prev_wl_disp = getenv("WAYLAND_DISPLAY");
    setenv("WAYLAND_DISPLAY", disp->socket, true);

    pthread_create(&disp->thread, NULL, (void *(*)(void*))wl_display_run, disp->display);
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

static void destory_display(DisplayChannelDisplay* self) {
  wl_display_terminate(self->display);
  pthread_join(self->thread, NULL);

  g_clear_list(&self->outputs, (GDestroyNotify)wlr_output_destroy_global);
  g_hash_table_unref(self->toplevels);

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
