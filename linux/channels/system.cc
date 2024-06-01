#include <flutter_linux/flutter_linux.h>
#include "system.h"
#include "../icons.h"

static FlValue* new_string(const gchar* str) {
  if (str == nullptr || g_utf8_strlen(str, -1) == 0) return fl_value_new_null();
  return fl_value_new_string(str);
}

static void method_call_handler(FlMethodChannel* channel, FlMethodCall* method_call, gpointer user_data) {
  g_autoptr(FlMethodResponse) response = nullptr;
  if (strcmp(fl_method_call_get_name(method_call), "getMetadata") == 0) {
    FlValue* value = fl_value_new_map();

    const char* logo_name = g_get_os_info("LOGO");
    const char* os_name = g_get_os_info("NAME");
    const char* os_id = g_get_os_info("ID");
    const char* ver_id = g_get_os_info("VERSION_ID");
    const char* ver_code = g_get_os_info("VERSION_CODENAME");
    const char* pretty_name = g_get_os_info("PRETTY_NAME");

    GtkIconTheme* icon_theme = gtk_icon_theme_get_default();
    GtkIconInfo* icon_info = gtk_icon_theme_lookup_icon(icon_theme, logo_name, 48, (GtkIconLookupFlags)0);

    fl_value_set(value, fl_value_new_string("logo"), new_string(gtk_icon_info_get_filename(icon_info)));
    fl_value_set(value, fl_value_new_string("osName"), new_string(os_name));
    fl_value_set(value, fl_value_new_string("osId"), new_string(os_id));
    fl_value_set(value, fl_value_new_string("osId"), new_string(os_id));
    fl_value_set(value, fl_value_new_string("versionId"), new_string(ver_id));
    fl_value_set(value, fl_value_new_string("versionCodename"), new_string(ver_code));
    fl_value_set(value, fl_value_new_string("prettyName"), new_string(pretty_name));

    response = FL_METHOD_RESPONSE(fl_method_success_response_new(value));
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  g_autoptr(GError) error = nullptr;
  if (!fl_method_call_respond(method_call, response, &error)) {
    g_warning("Failed to send response: %s", error->message);
  }
}

void system_channel_init(SystemChannel* self, FlView* view) {
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  self->channel = fl_method_channel_new(fl_engine_get_binary_messenger(fl_view_get_engine(view)), "com.expidusos.genesis.shell/system", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(self->channel, method_call_handler, self, nullptr);
}

void system_channel_deinit(SystemChannel* self) {
  g_clear_object(&self->channel);
}
