#include "messaging.h"

struct InvokeMethodData {
  FlMethodChannel* channel;
  gchar* method_name;
  FlValue* value;
};

static void invoke_method_handle(struct InvokeMethodData* data) {
  fl_method_channel_invoke_method(data->channel, data->method_name, data->value, NULL, NULL, NULL);
  g_message("%s: %s", data->method_name, fl_value_to_string(data->value));

  g_clear_object(&data->channel);
  g_clear_pointer(&data->method_name, g_free);
  g_clear_pointer(&data->value, fl_value_unref);
  free(data);
}

void invoke_method(FlMethodChannel* channel, const gchar* name, FlValue* value) {
  struct InvokeMethodData* data = (struct InvokeMethodData*)malloc(sizeof (struct InvokeMethodData));
  data->channel = FL_METHOD_CHANNEL(g_object_ref(G_OBJECT(channel)));
  data->method_name = g_strdup(name);
  data->value = fl_value_ref(value);
  g_timeout_add_once(1, (GSourceOnceFunc)invoke_method_handle, data);
}
