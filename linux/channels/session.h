#pragma once

#include <flutter_linux/flutter_linux.h>

#include "../application.h"

typedef struct _SessionChannel {
  GHashTable* seats;
  FlMethodChannel* channel;
} SessionChannel;

void session_channel_init(SessionChannel* self, FlView* view);
void session_channel_deinit(SessionChannel* self);
