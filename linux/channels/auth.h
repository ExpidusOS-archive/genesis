#pragma once

#include <flutter_linux/flutter_linux.h>

#include "../application.h"

typedef struct _AuthChannel {
  GHashTable* sessions;
  FlMethodChannel* channel;
} AuthChannel;

void auth_channel_init(AuthChannel* self, FlView* view);
void auth_channel_deinit(AuthChannel* self);
