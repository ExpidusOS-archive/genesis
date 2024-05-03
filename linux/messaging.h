#pragma once

#include <flutter_linux/flutter_linux.h>

#ifdef __cplusplus
extern "C" {
#endif

void invoke_method(FlMethodChannel* channel, const gchar* name, FlValue* value);

#ifdef __cplusplus
}
#endif
