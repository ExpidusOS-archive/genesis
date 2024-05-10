#pragma once

#include <flutter_linux/flutter_linux.h>

#include "../application.h"

typedef struct _ApplicationsChannel {
  guint changed;

  GAppInfoMonitor* monitor;
  FlMethodChannel* channel;
} ApplicationsChannel;

void applications_channel_init(ApplicationsChannel* self, FlView* view);
void applications_channel_deinit(ApplicationsChannel* self);
