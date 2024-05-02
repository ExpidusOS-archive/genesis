#include <flutter_linux/flutter_linux.h>

#include <security/pam_appl.h>
#include <security/pam_misc.h>

#include <pwd.h>

#include "outputs.h"
#include "../application-priv.h"

static int conversation(int num_msg, const struct pam_message** msg, struct pam_response** resp, void* appdata_ptr) {
  struct pam_response* array_resp = (struct pam_response*)malloc(num_msg * sizeof(struct pam_response));
  for (int i = 0; i < num_msg; i++) {
    array_resp[i].resp_retcode = 0;
    array_resp[i].resp = g_strdup((const gchar*)appdata_ptr);
  }

  *resp = array_resp;
  return PAM_SUCCESS;
}

static void method_call_handler(FlMethodChannel* channel, FlMethodCall* method_call, gpointer user_data) {
  AuthChannel* self = (AuthChannel*)user_data;

  g_autoptr(FlMethodResponse) response = nullptr;
  if (strcmp(fl_method_call_get_name(method_call), "auth") == 0) {
    FlValue* args = fl_method_call_get_args(method_call);
    
    gchar* username = nullptr;
    if (fl_value_lookup_string(args, "username") != nullptr) {
      username = (gchar*)fl_value_get_string(fl_value_lookup_string(args, "username"));
    } else {
      struct passwd* pw = nullptr;
      if ((pw = getpwuid(getuid())) == NULL) {
        fl_method_call_respond_error(method_call, "shadow", "failed to get the username", NULL, NULL);
        return;
      }

      username = pw->pw_name;
    }

    const gchar* password = fl_value_get_string(fl_value_lookup_string(args, "password"));

    struct pam_conv* conv = (struct pam_conv*)malloc(sizeof(struct pam_conv));
    conv->conv = conversation;
    conv->appdata_ptr = (void*)password;

    pam_handle_t* handle = NULL;
    int r = pam_start("genesis-shell", username, conv, &handle);
    if (r != PAM_SUCCESS) {
      fl_method_call_respond_error(method_call, "PAM", "pam_start failed", fl_value_new_string(pam_strerror(handle, r)), NULL);
      pam_end(handle, r);
      free(conv);
      return;
    }

    r = pam_authenticate(handle, PAM_SILENT);
    if (r != PAM_SUCCESS) {
      fl_method_call_respond_error(method_call, "PAM", "pam_authenticate failed", fl_value_new_string(pam_strerror(handle, r)), NULL);
      pam_end(handle, r);
      free(conv);
      return;
    }

    r = pam_setcred(handle, PAM_REFRESH_CRED);
    if (r != PAM_SUCCESS) {
      fl_method_call_respond_error(method_call, "PAM", "pam_setcred failed", fl_value_new_string(pam_strerror(handle, r)), NULL);
      pam_end(handle, r);
      free(conv);
      return;
    }

    bool isSession = false;

    if (fl_value_lookup_string(args, "session") != nullptr) {
      isSession = fl_value_get_bool(fl_value_lookup_string(args, "session"));
    }

    if (isSession) {
      if (g_hash_table_contains(self->sessions, username)) {
        fl_method_call_respond_error(method_call, "Linux", "User session is already running", NULL, NULL);
        pam_end(handle, r);
        free(conv);
        return;
      }

      r = pam_open_session(handle, PAM_SILENT);
      if (r != PAM_SUCCESS) {
        fl_method_call_respond_error(method_call, "PAM", "pam_open_session failed", fl_value_new_string(pam_strerror(handle, r)), NULL);
        pam_end(handle, r);
        free(conv);
        return;
      }

      g_hash_table_insert(self->sessions, (gpointer)username, (gpointer)handle);
    } else {
      pam_end(handle, r);
      free(conv);
    }

    response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  } else if (strcmp(fl_method_call_get_name(method_call), "deauth") == 0) {
    FlValue* args = fl_method_call_get_args(method_call);
    const gchar* name = fl_value_get_string(args);

    if (!g_hash_table_contains(self->sessions, name)) {
      fl_method_call_respond_error(method_call, "Linux", "User does not have a session", NULL, NULL);
      return;
    }

    g_hash_table_remove(self->sessions, name);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  } else if (strcmp(fl_method_call_get_name(method_call), "hasSession") == 0) {
    FlValue* args = fl_method_call_get_args(method_call);
    const gchar* name = fl_value_get_string(args);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(g_hash_table_contains(self->sessions, name))));
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  g_autoptr(GError) error = nullptr;
  if (!fl_method_call_respond(method_call, response, &error)) {
    g_warning("Failed to send response: %s", error->message);
  }
}

static void destory_session(pam_handle_t* handle) {
  pam_close_session(handle, PAM_SILENT);
  pam_end(handle, PAM_SUCCESS);
}

void auth_channel_init(AuthChannel* self, FlView* view) {
  self->sessions = g_hash_table_new_full(g_str_hash, g_str_equal, g_free, (GDestroyNotify)destory_session);

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  self->channel = fl_method_channel_new(fl_engine_get_binary_messenger(fl_view_get_engine(view)), "com.expidusos.genesis.shell/auth", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(self->channel, method_call_handler, self, nullptr);
}

void auth_channel_deinit(AuthChannel* self) {
  g_clear_object(&self->channel);
  g_hash_table_unref(self->sessions);
}
