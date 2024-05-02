#include <flutter_linux/flutter_linux.h>

extern "C" {
#include <libseat.h>
}

#include "session.h"
#include "../application-priv.h"

static void handle_enable(struct libseat* backend, void* data) {
	(void)backend;
  (void)data;
}

static void handle_disable(struct libseat* backend, void* data) {
	(void)data;
	libseat_disable_seat(backend);
}

struct libseat_seat_listener listener = {
  .enable_seat = handle_enable,
	.disable_seat = handle_disable,
};

static void method_call_handler(FlMethodChannel* channel, FlMethodCall* method_call, gpointer user_data) {
  SessionChannel* self = (SessionChannel*)user_data;
  g_autoptr(FlMethodResponse) response = nullptr;

  if (strcmp(fl_method_call_get_name(method_call), "open") == 0) {
    struct libseat* seat = libseat_open_seat(&listener, user_data);
    if (seat == nullptr) {
      fl_method_call_respond_error(method_call, "libseat", "libseat_open_seat returned null", nullptr, nullptr);
      return;
    }

    const char* name = g_strdup(libseat_seat_name(seat));
    g_hash_table_insert(self->seats, (gpointer)name, (gpointer)seat);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_string(name)));
  } else if (strcmp(fl_method_call_get_name(method_call), "close") == 0) {
    FlValue* args = fl_method_call_get_args(method_call);
    const gchar* name = fl_value_get_string(args);

    if (g_hash_table_contains(self->seats, name)) {
      g_hash_table_remove(self->seats, name);
      response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(true)));
    } else {
      response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(false)));
    }
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  g_autoptr(GError) error = nullptr;
  if (!fl_method_call_respond(method_call, response, &error)) {
    g_warning("Failed to send response: %s", error->message);
  }
}

void session_channel_init(SessionChannel* self, FlView* view) {
  self->seats = g_hash_table_new_full(g_str_hash, g_str_equal, g_free, (GDestroyNotify)libseat_close_seat);

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  self->channel = fl_method_channel_new(fl_engine_get_binary_messenger(fl_view_get_engine(view)), "com.expidusos.genesis.shell/session", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(self->channel, method_call_handler, self, nullptr);
}

void session_channel_deinit(SessionChannel* self) {
  g_clear_object(&self->channel);
  g_hash_table_unref(self->seats);
}
