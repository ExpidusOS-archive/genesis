#include <flutter_linux/flutter_linux.h>

#include <sys/types.h>
#include <unistd.h>

#include "account.h"
#include "../application-priv.h"

static FlValue* new_string(const gchar* str) {
  if (str == nullptr || g_utf8_strlen(str, -1) == 0) return fl_value_new_null();
  return fl_value_new_string(str);
}

static FlValue* from_user(ActUser* usr) {
  if (usr == nullptr) return fl_value_new_null();

  FlValue* value = fl_value_new_map();
  fl_value_set(value, fl_value_new_string("name"), new_string(act_user_get_user_name(usr)));
  fl_value_set(value, fl_value_new_string("displayName"), new_string(act_user_get_real_name(usr)));
  fl_value_set(value, fl_value_new_string("icon"), new_string(act_user_get_icon_file(usr)));
  fl_value_set(value, fl_value_new_string("home"), new_string(act_user_get_home_dir(usr)));
  fl_value_set(value, fl_value_new_string("passwordHint"), new_string(act_user_get_password_hint(usr)));
  return value;
}

static void method_call_handler(FlMethodChannel* channel, FlMethodCall* method_call, gpointer user_data) {
  AccountChannel* self = (AccountChannel*)user_data;
  g_autoptr(FlMethodResponse) response = nullptr;

  if (act_user_manager_no_service(self->mngr)) {
      fl_method_call_respond_error(method_call, "AccountsService", "Service has not started.", nullptr, nullptr);
      return;
  }

  if (strcmp(fl_method_call_get_name(method_call), "get") == 0) {
    FlValue* args = fl_method_call_get_args(method_call);
    switch (fl_value_get_type(args)) {
      case FL_VALUE_TYPE_NULL:
        response = FL_METHOD_RESPONSE(fl_method_success_response_new(from_user(act_user_manager_get_user_by_id(self->mngr, geteuid()))));
        break;
      case FL_VALUE_TYPE_INT:
        response = FL_METHOD_RESPONSE(fl_method_success_response_new(from_user(act_user_manager_get_user_by_id(self->mngr, fl_value_get_int(args)))));
        break;
      case FL_VALUE_TYPE_STRING:
        response = FL_METHOD_RESPONSE(fl_method_success_response_new(from_user(act_user_manager_get_user(self->mngr, fl_value_get_string(args)))));
        break;
      default:
        fl_method_call_respond_error(method_call, "AccountsService", "Unknown type", args, nullptr);
        return;
    }
  } else if (strcmp(fl_method_call_get_name(method_call), "list") == 0) {
    g_autoptr(FlValue) value = fl_value_new_list();

    GSList* list = act_user_manager_list_users(self->mngr);
    while (list != nullptr) {
      fl_value_append(value, from_user(ACT_USER(list->data)));
      list = list->next;
    }

    response = FL_METHOD_RESPONSE(fl_method_success_response_new(value));
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  g_autoptr(GError) error = nullptr;
  if (!fl_method_call_respond(method_call, response, &error)) {
    g_warning("Failed to send response: %s", error->message);
  }
}

static void is_loaded(ActUserManager* mngr, GParamSpec* pspec, AccountChannel* self) {
  (void)mngr;
  (void)pspec;

  fl_method_channel_invoke_method(self->channel, "loaded", nullptr, nullptr, nullptr, nullptr);
}

void account_channel_init(AccountChannel* self, FlView* view) {
  self->mngr = g_object_ref(act_user_manager_get_default());
  self->is_loaded = g_signal_connect(self->mngr, "notify::is-loaded", G_CALLBACK(is_loaded), self);

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  self->channel = fl_method_channel_new(fl_engine_get_binary_messenger(fl_view_get_engine(view)), "com.expidusos.genesis.shell/account", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(self->channel, method_call_handler, self, nullptr);
}

void account_channel_deinit(AccountChannel* self) {
  g_clear_object(&self->mngr);
  g_clear_object(&self->channel);
}
