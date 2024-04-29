#pragma once

#include <flutter_linux/flutter_linux.h>

#include "../application.h"

void outputs_method_call_handler(FlMethodChannel* channel, FlMethodCall* method_call, gpointer user_data);
