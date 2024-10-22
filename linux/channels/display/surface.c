#include "surface.h"
#include "../display.h"
#include "../../application.h"
#include "../../application-priv.h"

static void xdg_toplevel_decor_request_mode(struct wl_listener* listener, void* data);

static FlValue* new_string(const gchar* str) {
  if (str == NULL || g_utf8_strlen(str, -1) == 0) return fl_value_new_null();
  return fl_value_new_string(g_strdup(str));
}

static void xdg_toplevel_emit_request(DisplayChannelSurface* self, const char* name) {
  g_autoptr(FlValue) value = fl_value_new_map();
  fl_value_set(value, fl_value_new_string("name"), fl_value_new_string(self->display->socket));
  fl_value_set(value, fl_value_new_string("id"), fl_value_new_int(self->id));
  fl_value_set(value, fl_value_new_string("reqName"), fl_value_new_string(name));
  fl_method_channel_invoke_method(self->display->channel->channel, "requestSurface", value, NULL, NULL, NULL);
}

void xdg_toplevel_emit_prop(DisplayChannelSurface* self, const char* name, FlValue* pvalue) {
  g_autoptr(FlValue) value = fl_value_new_map();
  fl_value_set(value, fl_value_new_string("name"), fl_value_new_string(self->display->socket));
  fl_value_set(value, fl_value_new_string("id"), fl_value_new_int(self->id));
  fl_value_set(value, fl_value_new_string("propName"), fl_value_new_string(name));
  fl_value_set(value, fl_value_new_string("propValue"), pvalue);
  fl_method_channel_invoke_method(self->display->channel->channel, "notifySurface", value, NULL, NULL, NULL);
}

static void xdg_toplevel_map(struct wl_listener* listener, void* data) {
  (void)data;

  DisplayChannelSurface* self = wl_container_of(listener, self, map);
  g_hash_table_insert(self->display->surfaces, &self->id, self);
  xdg_toplevel_emit_request(self, "map");
}

static void xdg_toplevel_unmap(struct wl_listener* listener, void* data) {
  (void)data;

  DisplayChannelSurface* self = wl_container_of(listener, self, unmap);
  xdg_toplevel_emit_request(self, "unmap");
}

static void xdg_toplevel_destroy(struct wl_listener* listener, void* data) {
  (void)data;

  DisplayChannelSurface* self = wl_container_of(listener, self, destroy);

  g_autoptr(FlValue) value = fl_value_new_map();
  fl_value_set(value, fl_value_new_string("name"), fl_value_new_string(self->display->socket));
  fl_value_set(value, fl_value_new_string("id"), fl_value_new_int(self->id));
  fl_method_channel_invoke_method(self->display->channel->channel, "removeSurface", value, NULL, NULL, NULL);

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

  g_hash_table_remove(self->display->surfaces, &self->id);

  if (self->texture != NULL) {
    bool has_init;
    g_object_get(G_OBJECT(self->texture), "has-init", &has_init, NULL);

    if (has_init) {
      GenesisShellApplication* app = wl_container_of(self->display->channel, app, display);
      FlEngine* engine = fl_view_get_engine(app->view);
      FlTextureRegistrar* tex_reg = fl_engine_get_texture_registrar(engine);
      // FIXME: Sometimes this causes a SIGSEV
      fl_texture_registrar_unregister_texture(tex_reg, FL_TEXTURE(self->texture));
    }
  }

  g_clear_object(&self->texture);

  free(self);
}

static void xdg_toplevel_commit(struct wl_listener* listener, void* data) {
  DisplayChannelSurface* self = wl_container_of(listener, self, commit);

  if (self->xdg->base->initial_commit) {
    if (self->decor != NULL) {
      xdg_toplevel_decor_request_mode(&self->decor_request_mode, NULL);
    }

    wlr_xdg_surface_schedule_configure(self->xdg->base);
    return;
  }

  if (!wlr_surface_has_buffer(self->xdg->base->surface) || self->xdg->base->surface->current.buffer == NULL) {
    return;
  }

  struct wlr_buffer* buffer = self->xdg->base->surface->current.buffer;
  GenesisShellApplication* app = wl_container_of(self->display->channel, app, display);
  GdkWindow* win = gtk_widget_get_window(GTK_WIDGET(app->view));

  FlEngine* engine = fl_view_get_engine(app->view);
  FlTextureRegistrar* tex_reg = fl_engine_get_texture_registrar(engine);

  bool is_new = self->texture == NULL;

  if (is_new) {
    GError* error = NULL;
    GdkGLContext* ctx = gdk_window_create_gl_context(win, &error);
    self->texture = display_channel_texture_new(ctx, buffer);
    fl_texture_registrar_register_texture(tex_reg, FL_TEXTURE(self->texture));
  } else {
    display_channel_texture_update(self->texture, buffer);
  }

  bool has_init;
  g_object_get(G_OBJECT(self->texture), "has-init", &has_init, NULL);

  if (has_init) {
    fl_texture_registrar_mark_texture_frame_available(tex_reg, FL_TEXTURE(self->texture));

    if (is_new) {
      xdg_toplevel_emit_prop(self, "texture", fl_value_new_int((uintptr_t)FL_TEXTURE(self->texture)));
    }

    xdg_toplevel_emit_request(self, "commit");
  }
}

static void xdg_toplevel_request_maximize(struct wl_listener* listener, void* data) {
  (void)data;

  DisplayChannelSurface* self = wl_container_of(listener, self, request_maximize);
  xdg_toplevel_emit_request(self, "maximize");
}

static void xdg_toplevel_request_fullscreen(struct wl_listener* listener, void* data) {
  (void)data;

  DisplayChannelSurface* self = wl_container_of(listener, self, request_fullscreen);
  xdg_toplevel_emit_request(self, "fullscreen");
}

static void xdg_toplevel_request_minimize(struct wl_listener* listener, void* data) {
  (void)data;

  DisplayChannelSurface* self = wl_container_of(listener, self, request_minimize);
  xdg_toplevel_emit_request(self, "minimize");
}

static void xdg_toplevel_request_move(struct wl_listener* listener, void* data) {
  (void)data;

  DisplayChannelSurface* self = wl_container_of(listener, self, request_move);
  xdg_toplevel_emit_request(self, "move");
}

static void xdg_toplevel_request_resize(struct wl_listener* listener, void* data) {
  (void)data;

  DisplayChannelSurface* self = wl_container_of(listener, self, request_resize);
  xdg_toplevel_emit_request(self, "resize");
}

static void xdg_toplevel_request_show_window_menu(struct wl_listener* listener, void* data) {
  (void)data;

  DisplayChannelSurface* self = wl_container_of(listener, self, request_show_window_menu);
  xdg_toplevel_emit_request(self, "showWindowMenu");
}

static void xdg_toplevel_set_parent(struct wl_listener* listener, void* data) {
  (void)data;

  DisplayChannelSurface* self = wl_container_of(listener, self, set_parent);

  if (self->xdg->parent != NULL && self->xdg->parent->base->data != NULL) {
    DisplayChannelSurface* parent = (DisplayChannelSurface*)self->xdg->parent->base->data;
    xdg_toplevel_emit_prop(self, "parent", fl_value_new_int(parent->id));
  } else {
    xdg_toplevel_emit_prop(self, "parent", fl_value_new_null());
  }
}

static void xdg_toplevel_set_title(struct wl_listener* listener, void* data) {
  (void)data;

  DisplayChannelSurface* self = wl_container_of(listener, self, set_title);
  xdg_toplevel_emit_prop(self, "title", new_string(self->xdg->title));
}

static void xdg_toplevel_set_app_id(struct wl_listener* listener, void* data) {
  (void)data;

  DisplayChannelSurface* self = wl_container_of(listener, self, set_app_id);
  xdg_toplevel_emit_prop(self, "appId", new_string(self->xdg->app_id));
}

static void xdg_toplevel_decor_request_mode(struct wl_listener* listener, void* data) {
  (void)data;

  DisplayChannelSurface* self = wl_container_of(listener, self, decor_request_mode);
  if (self->decor->requested_mode != WLR_XDG_TOPLEVEL_DECORATION_V1_MODE_NONE) {
    wlr_xdg_toplevel_decoration_v1_set_mode(self->decor, self->decor->requested_mode);
    self->has_decor = self->decor->requested_mode == WLR_XDG_TOPLEVEL_DECORATION_V1_MODE_CLIENT_SIDE;
  } else {
    self->has_decor = false;
  }

  xdg_toplevel_emit_prop(self, "hasDecorations", fl_value_new_bool(self->has_decor));
}

void xdg_surface_new(struct wl_listener* listener, void* data) {
  DisplayChannelDisplay* self = wl_container_of(listener, self, xdg_surface_new);
  struct wlr_xdg_surface* xdg_surface = data;

  if (xdg_surface->role == WLR_XDG_SURFACE_ROLE_TOPLEVEL) {
    struct wlr_xdg_toplevel* xdg_toplevel = wlr_xdg_toplevel_try_from_wlr_surface(xdg_surface->surface);
    wlr_xdg_toplevel_set_wm_capabilities(xdg_toplevel, WLR_XDG_TOPLEVEL_WM_CAPABILITIES_WINDOW_MENU | WLR_XDG_TOPLEVEL_WM_CAPABILITIES_MAXIMIZE | WLR_XDG_TOPLEVEL_WM_CAPABILITIES_FULLSCREEN | WLR_XDG_TOPLEVEL_WM_CAPABILITIES_MINIMIZE);

    DisplayChannelSurface* surface = (DisplayChannelSurface*)malloc(sizeof (DisplayChannelSurface));
    xdg_surface->data = surface;

    surface->display = self;
    surface->xdg = xdg_toplevel;
    surface->id = self->surface_id++;
    surface->texture = NULL;
    surface->decor = NULL;
    surface->has_decor = true;
    surface->monitor = 0;

    surface->map.notify = xdg_toplevel_map;
    wl_signal_add(&xdg_surface->surface->events.map, &surface->map);

    surface->unmap.notify = xdg_toplevel_unmap;
    wl_signal_add(&xdg_surface->surface->events.unmap, &surface->unmap);

    surface->destroy.notify = xdg_toplevel_destroy;
    wl_signal_add(&xdg_surface->surface->events.destroy, &surface->destroy);

    surface->commit.notify = xdg_toplevel_commit;
    wl_signal_add(&xdg_surface->surface->events.commit, &surface->commit);

    surface->request_maximize.notify = xdg_toplevel_request_maximize;
    wl_signal_add(&xdg_toplevel->events.request_maximize, &surface->request_maximize);

    surface->request_fullscreen.notify = xdg_toplevel_request_fullscreen;
    wl_signal_add(&xdg_toplevel->events.request_fullscreen, &surface->request_fullscreen);

    surface->request_minimize.notify = xdg_toplevel_request_minimize;
    wl_signal_add(&xdg_toplevel->events.request_minimize, &surface->request_minimize);

    surface->request_move.notify = xdg_toplevel_request_move;
    wl_signal_add(&xdg_toplevel->events.request_move, &surface->request_move);

    surface->request_resize.notify = xdg_toplevel_request_resize;
    wl_signal_add(&xdg_toplevel->events.request_resize, &surface->request_resize);

    surface->request_show_window_menu.notify = xdg_toplevel_request_show_window_menu;
    wl_signal_add(&xdg_toplevel->events.request_show_window_menu, &surface->request_show_window_menu);

    surface->set_parent.notify = xdg_toplevel_set_parent;
    wl_signal_add(&xdg_toplevel->events.set_parent, &surface->set_parent);

    surface->set_title.notify = xdg_toplevel_set_title;
    wl_signal_add(&xdg_toplevel->events.set_title, &surface->set_title);

    surface->set_app_id.notify = xdg_toplevel_set_app_id;
    wl_signal_add(&xdg_toplevel->events.set_app_id, &surface->set_app_id);

    surface->decor_request_mode.notify = xdg_toplevel_decor_request_mode;

    g_autoptr(FlValue) value = fl_value_new_map();
    fl_value_set(value, fl_value_new_string("name"), fl_value_new_string(self->socket));
    fl_value_set(value, fl_value_new_string("id"), fl_value_new_int(surface->id));

    g_hash_table_insert(self->surfaces, &surface->id, self);
    fl_method_channel_invoke_method(self->channel->channel, "newSurface", value, NULL, NULL, NULL);
  }
}
