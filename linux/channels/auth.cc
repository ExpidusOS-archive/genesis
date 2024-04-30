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

void auth_method_call_handler(FlMethodChannel* channel, FlMethodCall* method_call, gpointer user_data) {
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
      fl_method_call_respond_error(method_call, "PAM", "pam_acct_mgmt failed", fl_value_new_string(pam_strerror(handle, r)), NULL);
      pam_end(handle, r);
      free(conv);
      return;
    }

    pam_end(handle, r);
    free(conv);

    response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  g_autoptr(GError) error = nullptr;
  if (!fl_method_call_respond(method_call, response, &error)) {
    g_warning("Failed to send response: %s", error->message);
  }
}
