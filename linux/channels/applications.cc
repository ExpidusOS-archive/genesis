#include "applications.h"

static FlValue* new_string(const gchar* str) {
  if (str == nullptr || g_utf8_strlen(str, -1) == 0) return fl_value_new_null();
  return fl_value_new_string(str);
}

static FlValue* from_app_info(GAppInfo* appinfo) {
  FlValue* value = fl_value_new_map();

  fl_value_set(value, fl_value_new_string("id"), new_string(g_app_info_get_id(appinfo)));
  fl_value_set(value, fl_value_new_string("name"), new_string(g_app_info_get_name(appinfo)));
  fl_value_set(value, fl_value_new_string("displayName"), new_string(g_app_info_get_display_name(appinfo)));
  fl_value_set(value, fl_value_new_string("description"), new_string(g_app_info_get_description(appinfo)));
  fl_value_set(value, fl_value_new_string("isHidden"), fl_value_new_bool(!g_app_info_should_show(appinfo)));

  GIcon* icon = g_app_info_get_icon(appinfo);
  if (icon == nullptr) {
    fl_value_set(value, fl_value_new_string("icon"), fl_value_new_null());
  } else {
    if (G_IS_FILE_ICON(icon)) {
      GFile* file = g_file_icon_get_file(G_FILE_ICON(icon));
      fl_value_set(value, fl_value_new_string("icon"), new_string(g_file_get_path(file)));
    } else if (G_IS_THEMED_ICON(icon)) {
      GtkIconTheme* theme = gtk_icon_theme_get_default();
      GtkIconInfo* icon_info = gtk_icon_theme_lookup_by_gicon(theme, icon, 48, (GtkIconLookupFlags)0);
      if (icon_info != nullptr) {
        fl_value_set(value, fl_value_new_string("icon"), new_string(gtk_icon_info_get_filename(icon_info)));
      } else {
        fl_value_set(value, fl_value_new_string("icon"), fl_value_new_null());
      }
    } else {
      fl_value_set(value, fl_value_new_string("icon"), fl_value_new_null());
    }
  }
  return value;
}

static void method_call_handler(FlMethodChannel* channel, FlMethodCall* method_call, gpointer user_data) {
  ApplicationsChannel* self = (ApplicationsChannel*)user_data;
  (void)self;

  g_autoptr(FlMethodResponse) response = nullptr;

  if (strcmp(fl_method_call_get_name(method_call), "list") == 0) {
    g_autoptr(FlValue) value = fl_value_new_list();

    GList* list = g_app_info_get_all();
    for (GList* entry = list; entry != NULL; entry = entry->next) {
      fl_value_append(value, from_app_info(G_APP_INFO(entry->data)));
    }

    g_clear_list(&list, g_object_unref);

    response = FL_METHOD_RESPONSE(fl_method_success_response_new(value));
  } else if (strcmp(fl_method_call_get_name(method_call), "launch") == 0) {
    FlValue* args = fl_method_call_get_args(method_call);
    const gchar* name = fl_value_get_string(args);

    GAppInfo* appinfo = nullptr;

    GList* list = g_app_info_get_all();
    for (GList* entry = list; entry != NULL; entry = entry->next) {
      GAppInfo* i = G_APP_INFO(entry->data);
      if (g_strcmp0(name, g_app_info_get_id(i)) == 0) {
        appinfo = G_APP_INFO(g_object_ref(G_OBJECT(i)));
        break;
      }
    }

    g_clear_list(&list, g_object_unref);

    if (appinfo == nullptr) {
      fl_method_call_respond_error(method_call, "Gio", "Application does not exist", args, nullptr);
      return;
    }

    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(g_app_info_launch(appinfo, nullptr, nullptr, nullptr))));
    g_object_unref(G_OBJECT(appinfo));
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  g_autoptr(GError) error = nullptr;
  if (!fl_method_call_respond(method_call, response, &error)) {
    g_warning("Failed to send response: %s", error->message);
  }
}

static void changed(GAppInfoMonitor* monitor, ApplicationsChannel* self) {
  (void)monitor;

  fl_method_channel_invoke_method(self->channel, "sync", nullptr, nullptr, nullptr, nullptr);
}

void applications_channel_init(ApplicationsChannel* self, FlView* view) {
  self->monitor = G_APP_INFO_MONITOR(g_object_ref(G_OBJECT(g_app_info_monitor_get())));
  self->changed = g_signal_connect(self->monitor, "changed", G_CALLBACK(changed), self);

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  self->channel = fl_method_channel_new(fl_engine_get_binary_messenger(fl_view_get_engine(view)), "com.expidusos.genesis.shell/applications", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(self->channel, method_call_handler, self, nullptr);
}

void applications_channel_deinit(ApplicationsChannel* self) {
  g_clear_object(&self->channel);
  g_clear_object(&self->monitor);
}
