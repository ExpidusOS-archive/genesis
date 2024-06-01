#pragma once

#include <flutter_linux/flutter_linux.h>

typedef struct _SystemChannel {
  FlMethodChannel* channel;
} SystemChannel;

void system_channel_init(SystemChannel* self, FlView* view);
void system_channel_deinit(SystemChannel* self);
