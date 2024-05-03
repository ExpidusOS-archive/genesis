#pragma once

#include <flutter_linux/flutter_linux.h>

#include "../application.h"

typedef struct _OutputsChannel {
  guint monitor_added;
  guint monitor_removed;

  FlMethodChannel* channel;
} OutputsChannel;

void outputs_channel_init(OutputsChannel* self, FlView* view);
void outputs_channel_deinit(OutputsChannel* self);
