#include <drm_fourcc.h>

#include <EGL/egl.h>

#include "display/surface.h"
#include "display.h"
#include "session.h"
#include "../application-priv.h"

static gchar* get_string(FlValue* value) {
  if (fl_value_get_type(value) != FL_VALUE_TYPE_STRING) return g_strdup("Unknown");
  return g_strdup(fl_value_get_string(value));
}

static FlValue* new_string(const gchar* str) {
  if (str == NULL || g_utf8_strlen(str, -1) == 0) return fl_value_new_null();
  return fl_value_new_string(g_strdup(str));
}

static void toplevel_decor_new(struct wl_listener* listener, void* data) {
  DisplayChannelDisplay* self = wl_container_of(listener, self, toplevel_decor_new);
  struct wlr_xdg_toplevel_decoration_v1* decor = data;

  DisplayChannelSurface* surface = decor->toplevel->base->data;
  surface->decor = decor;
  wl_signal_add(&decor->events.request_mode, &surface->decor_request_mode);

  if (decor->requested_mode != WLR_XDG_TOPLEVEL_DECORATION_V1_MODE_NONE) {
    wlr_xdg_toplevel_decoration_v1_set_mode(decor, decor->requested_mode);
    surface->has_decor = decor->requested_mode == WLR_XDG_TOPLEVEL_DECORATION_V1_MODE_CLIENT_SIDE;
  } else {
    surface->has_decor = false;
  }

  xdg_toplevel_emit_prop(surface, "hasDecorations", fl_value_new_bool(surface->has_decor));
}

static gboolean display_channel_wl_poll(GIOChannel* src, GIOCondition cond, gpointer user_data) {
  DisplayChannelDisplay* self = (DisplayChannelDisplay*)user_data;
  struct wl_display* wl_display = display_channel_backend_get_display(self->backend);
  struct wl_event_loop* wl_event_loop = wl_display_get_event_loop(wl_display);

  wl_event_loop_dispatch(wl_event_loop, -1);
  wl_display_flush_clients(wl_display);
  return TRUE;
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
    GdkWindow* win = gtk_widget_get_window(GTK_WIDGET(app->view));

    GError* error = NULL;
    GdkGLContext* ctx = gdk_window_create_gl_context(win, &error);
    if (ctx == NULL) {
      fl_method_call_respond_error(method_call, "GTK", "failed to create OpenGL context", NULL, NULL);
      g_clear_object(&ctx);
      return;
    }

    gdk_gl_context_set_use_es(ctx, true);
    gdk_gl_context_make_current(ctx);

    DisplayChannelDisplay* disp = (DisplayChannelDisplay*)malloc(sizeof (DisplayChannelDisplay));
    disp->backend = display_channel_backend_create(gdk_disp);

    struct wl_display* wl_display = display_channel_backend_get_display(disp->backend);

    disp->socket = wl_display_add_socket_auto(wl_display);
    if (disp->socket == NULL) {
      fl_method_call_respond_error(method_call, "wayland", "failed to create socket", NULL, NULL);
      wlr_backend_destroy(disp->backend);
      g_clear_object(&ctx);
      free(disp);
      return;
    }

    struct wlr_renderer* renderer = display_channel_backend_get_renderer(disp->backend);
    wlr_renderer_init_wl_display(renderer, wl_display);

    disp->allocator = wlr_allocator_autocreate(disp->backend, renderer);
    gdk_gl_context_clear_current();

    if (!wlr_backend_start(disp->backend)) {
      fl_method_call_respond_error(method_call, "wlroots", "failed to start backend", NULL, NULL);
      wlr_backend_destroy(disp->backend);
      free(disp);
      return;
    }

    disp->outputs = NULL;
    disp->surface_id = 1;
    disp->surfaces = g_hash_table_new_full(g_int_hash, g_int_equal, NULL, NULL);
    disp->channel = self;

    disp->compositor = wlr_compositor_create(wl_display, 5, NULL);
    wlr_subcompositor_create(wl_display);
    wlr_data_device_manager_create(wl_display);

    disp->seat = wlr_seat_create(wl_display, session_name);
    wlr_seat_set_capabilities(disp->seat, WL_SEAT_CAPABILITY_POINTER | WL_SEAT_CAPABILITY_KEYBOARD | WL_SEAT_CAPABILITY_TOUCH);
    disp->xdg_shell = wlr_xdg_shell_create(wl_display, 6);

    disp->xdg_decor = wlr_xdg_decoration_manager_v1_create(wl_display);

    disp->toplevel_decor_new.notify = toplevel_decor_new;
    wl_signal_add(&disp->xdg_decor->events.new_toplevel_decoration, &disp->toplevel_decor_new);

    disp->xdg_surface_new.notify = xdg_surface_new;
    wl_signal_add(&disp->xdg_shell->events.new_surface, &disp->xdg_surface_new);

    disp->prev_wl_disp = getenv("WAYLAND_DISPLAY");
    setenv("WAYLAND_DISPLAY", disp->socket, true);

    disp->wl_poll = g_io_channel_unix_new(wl_event_loop_get_fd(wl_display_get_event_loop(wl_display)));
    disp->wl_poll_id = g_io_add_watch(disp->wl_poll, G_IO_IN | G_IO_OUT, display_channel_wl_poll, disp);

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
  } else if (strcmp(fl_method_call_get_name(method_call), "getSurface") == 0) {
    FlValue* args = fl_method_call_get_args(method_call);
    const gchar* name = fl_value_get_string(fl_value_lookup_string(args, "name"));
    int id = fl_value_get_int(fl_value_lookup_string(args, "id"));

    if (!g_hash_table_contains(self->displays, name)) {
      fl_method_call_respond_error(method_call, "Linux", "Display server does not exist", NULL, NULL);
      return;
    }

    DisplayChannelDisplay* disp = g_hash_table_lookup(self->displays, name);

    if (!g_hash_table_contains(disp->surfaces, &id)) {
      fl_method_call_respond_error(method_call, "Linux", "Surface does not exist", NULL, NULL);
      return;
    }

    DisplayChannelSurface* surface = g_hash_table_lookup(disp->surfaces, &id);
    g_assert(surface->id == id);

    g_autoptr(FlValue) value = fl_value_new_map();
    fl_value_set(value, fl_value_new_string("title"), new_string(surface->xdg->title));
    fl_value_set(value, fl_value_new_string("appId"), new_string(surface->xdg->app_id));
    fl_value_set(value, fl_value_new_string("monitor"), fl_value_new_int(surface->monitor));

    if (surface->xdg->parent != NULL && surface->xdg->parent->base->data != NULL) {
      DisplayChannelSurface* parent = (DisplayChannelSurface*)surface->xdg->parent->base->data;
      fl_value_set(value, fl_value_new_string("parent"), fl_value_new_int(parent->id));
    } else {
      fl_value_set(value, fl_value_new_string("parent"), fl_value_new_null());
    }

    if (surface->texture != NULL) {
      bool has_init;
      g_object_get(G_OBJECT(surface->texture), "has-init", &has_init, NULL);

      if (has_init) {
        fl_value_set(value, fl_value_new_string("texture"), fl_value_new_int((uintptr_t)FL_TEXTURE(surface->texture)));
      } else {
        fl_value_set(value, fl_value_new_string("texture"), fl_value_new_null());
      }
    } else {
      fl_value_set(value, fl_value_new_string("texture"), fl_value_new_null());
    }

    struct wlr_box geom;
    wlr_xdg_surface_get_geometry(surface->xdg->base, &geom);

    FlValue* value_size = fl_value_new_map();
    fl_value_set(value_size, fl_value_new_string("width"), fl_value_new_int(geom.width));
    fl_value_set(value_size, fl_value_new_string("height"), fl_value_new_int(geom.height));
    fl_value_set(value, fl_value_new_string("size"), value_size);

    FlValue* value_size_max = fl_value_new_map();
    fl_value_set(value_size_max, fl_value_new_string("width"), fl_value_new_int(surface->xdg->current.max_width));
    fl_value_set(value_size_max, fl_value_new_string("height"), fl_value_new_int(surface->xdg->current.max_height));
    fl_value_set(value, fl_value_new_string("maxSize"), value_size_max);

    FlValue* value_size_min = fl_value_new_map();
    fl_value_set(value_size_min, fl_value_new_string("width"), fl_value_new_int(surface->xdg->current.min_width));
    fl_value_set(value_size_min, fl_value_new_string("height"), fl_value_new_int(surface->xdg->current.min_height));
    fl_value_set(value, fl_value_new_string("minSize"), value_size_min);

    fl_value_set(value, fl_value_new_string("maximized"), fl_value_new_bool(surface->xdg->current.maximized));
    fl_value_set(value, fl_value_new_string("fullscreen"), fl_value_new_bool(surface->xdg->current.fullscreen));
    fl_value_set(value, fl_value_new_string("resizing"), fl_value_new_bool(surface->xdg->current.resizing));
    fl_value_set(value, fl_value_new_string("active"), fl_value_new_bool(surface->xdg->current.activated));
    fl_value_set(value, fl_value_new_string("suspended"), fl_value_new_bool(surface->xdg->current.suspended));
    fl_value_set(value, fl_value_new_string("hasDecorations"), fl_value_new_bool(surface->has_decor));

    response = FL_METHOD_RESPONSE(fl_method_success_response_new(value));
  } else if (strcmp(fl_method_call_get_name(method_call), "setSurface") == 0) {
    FlValue* args = fl_method_call_get_args(method_call);
    const gchar* name = fl_value_get_string(fl_value_lookup_string(args, "name"));
    int id = fl_value_get_int(fl_value_lookup_string(args, "id"));

    if (!g_hash_table_contains(self->displays, name)) {
      fl_method_call_respond_error(method_call, "Linux", "Display server does not exist", NULL, NULL);
      return;
    }

    DisplayChannelDisplay* disp = g_hash_table_lookup(self->displays, name);

    if (!g_hash_table_contains(disp->surfaces, &id)) {
      fl_method_call_respond_error(method_call, "Linux", "Surface does not exist", NULL, NULL);
      return;
    }

    DisplayChannelSurface* surface = g_hash_table_lookup(disp->surfaces, &id);
    g_assert(surface->id == id);

    uint32_t i = 0;

    FlValue* value_monitor = fl_value_lookup_string(args, "monitor");
    if (value_monitor != NULL) {
      surface->monitor = fl_value_get_int(value_monitor);
    }

    FlValue* value_size = fl_value_lookup_string(args, "size");
    if (value_size != NULL) {
      i += wlr_xdg_toplevel_set_size(surface->xdg, fl_value_get_int(fl_value_lookup_string(value_size, "width")), fl_value_get_int(fl_value_lookup_string(value_size, "height")));
    }

    FlValue* value_maximized = fl_value_lookup_string(args, "maximized");
    if (value_maximized != NULL) {
      i += wlr_xdg_toplevel_set_maximized(surface->xdg, fl_value_get_bool(value_maximized));
    }

    FlValue* value_fullscreen = fl_value_lookup_string(args, "fullscreen");
    if (value_fullscreen != NULL) {
      i += wlr_xdg_toplevel_set_fullscreen(surface->xdg, fl_value_get_bool(value_fullscreen));
    }

    FlValue* value_resizing = fl_value_lookup_string(args, "resizing");
    if (value_resizing != NULL) {
      i += wlr_xdg_toplevel_set_resizing(surface->xdg, fl_value_get_bool(value_resizing));
    }

    FlValue* value_active = fl_value_lookup_string(args, "active");
    if (value_active != NULL) {
      i += wlr_xdg_toplevel_set_activated(surface->xdg, fl_value_get_bool(value_active));
    }

    FlValue* value_suspended = fl_value_lookup_string(args, "suspended");
    if (value_suspended != NULL) {
      i += wlr_xdg_toplevel_set_suspended(surface->xdg, fl_value_get_bool(value_suspended));
    }

    if (i > 0) {
      struct wl_display* wl_display = display_channel_backend_get_display(disp->backend);
      struct wl_event_loop* wl_event_loop = wl_display_get_event_loop(wl_display);

      wl_event_loop_dispatch(wl_event_loop, 0);
      wl_display_flush_clients(wl_display);
    }

    response = FL_METHOD_RESPONSE(fl_method_success_response_new(NULL));
  } else if (strcmp(fl_method_call_get_name(method_call), "requestSurface") == 0) {
    FlValue* args = fl_method_call_get_args(method_call);
    const gchar* name = fl_value_get_string(fl_value_lookup_string(args, "name"));
    int id = fl_value_get_int(fl_value_lookup_string(args, "id"));

    if (!g_hash_table_contains(self->displays, name)) {
      fl_method_call_respond_error(method_call, "Linux", "Display server does not exist", NULL, NULL);
      return;
    }

    DisplayChannelDisplay* disp = g_hash_table_lookup(self->displays, name);

    if (!g_hash_table_contains(disp->surfaces, &id)) {
      fl_method_call_respond_error(method_call, "Linux", "Surface does not exist", NULL, NULL);
      return;
    }

    DisplayChannelSurface* surface = g_hash_table_lookup(disp->surfaces, &id);
    g_assert(surface->id == id);

    const gchar* req_name = fl_value_get_string(fl_value_lookup_string(args, "reqName"));
    if (strcmp(req_name, "close") == 0) {
      wlr_xdg_toplevel_send_close(surface->xdg);
      response = FL_METHOD_RESPONSE(fl_method_success_response_new(NULL));
    } else {
      response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
    }
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  g_autoptr(GError) error = NULL;
  if (!fl_method_call_respond(method_call, response, &error)) {
    g_warning("Failed to send response: %s", error->message);
  }
}

static void destroy_display(DisplayChannelDisplay* self) {
  g_source_remove(self->wl_poll_id);
  g_io_channel_unref(self->wl_poll);

  g_clear_list(&self->outputs, (GDestroyNotify)wlr_output_destroy_global);
  g_hash_table_unref(self->surfaces);

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
