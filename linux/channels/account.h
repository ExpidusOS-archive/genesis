#pragma once

#include <flutter_linux/flutter_linux.h>

#ifdef __cplusplus
extern "C" {
#endif
#include <act/act.h>
#ifdef __cplusplus
}
#endif

#include "../application.h"

typedef struct _AccountChannel {
  guint is_loaded;

  ActUserManager* mngr;
  FlMethodChannel* channel;
} AccountChannel;

void account_channel_init(AccountChannel* self, FlView* view);
void account_channel_deinit(AccountChannel* self);
