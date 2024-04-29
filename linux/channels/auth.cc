#include <flutter_linux/flutter_linux.h>

#include <security/pam_appl.h>
#include <security/pam_misc.h>

#include "outputs.h"
#include "../application-priv.h"

static void message_callback(GObject* obj, GAsyncResult* result, gpointer user_data) {
  GArray* array_resp = (GArray*)user_data;

  g_autoptr(FlMethodResponse) response = fl_method_channel_invoke_method_finish(FL_METHOD_CHANNEL(obj), result, nullptr);
  g_autoptr(FlValue) resp_value = fl_method_response_get_result(response, nullptr);

  struct pam_response resp;
  resp.resp_retcode = 0;
  resp.resp = g_strdup(fl_value_get_string(resp_value));
  g_array_append_val(array_resp, resp);
}

static int conversation(int num_msg, const struct pam_message** msg, struct pam_response** resp, void* appdata_ptr) {
  GenesisShellApplication* self = GENESIS_SHELL_APPLICATION(appdata_ptr);

  GArray* array_resp = g_array_new(false, true, sizeof (struct pam_response));

  for (int i = 0; i < num_msg; i++) {
		const char* msg_content = msg[i]->msg;

    fl_method_channel_invoke_method(self->auth, "ask", fl_value_new_string(msg_content), nullptr, message_callback, array_resp);
  }

  while (true) {
    if ((array_resp->len / sizeof (struct pam_response)) == num_msg) {
      break;
    }
  }

  *resp = static_cast<struct pam_response*>(g_array_steal(array_resp, nullptr));
  return PAM_SUCCESS;
}

void auth_method_call_handler(FlMethodChannel* channel, FlMethodCall* method_call, gpointer user_data) {
  g_autoptr(FlMethodResponse) response = nullptr;
  if (strcmp(fl_method_call_get_name(method_call), "start") == 0) {
    FlValue* args = fl_method_call_get_args(method_call);
    
    gchar* username = nullptr;
    if (fl_value_lookup_string(args, "username") != nullptr) {
      username = (gchar*)fl_value_get_string(fl_value_lookup_string(args, "username"));
    }

    struct pam_conv* conv = (struct pam_conv*)malloc(sizeof(struct pam_conv));
    conv->conv = conversation;
    conv->appdata_ptr = user_data;

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

    r = pam_acct_mgmt(handle, PAM_SILENT);
    if (r != PAM_SUCCESS) {
      fl_method_call_respond_error(method_call, "PAM", "pam_acct_mgmt failed", fl_value_new_string(pam_strerror(handle, r)), NULL);
      pam_end(handle, r);
      free(conv);
      return;
    }

    pam_get_item(handle, PAM_USER, (const void**)&username);
    pam_end(handle, r);
    free(conv);

    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_string(username)));
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  g_autoptr(GError) error = nullptr;
  if (!fl_method_call_respond(method_call, response, &error)) {
    g_warning("Failed to send response: %s", error->message);
  }
}
