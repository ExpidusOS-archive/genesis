#include "backend/wayland.h"
#include "backend.h"

DisplayChannelBackend* display_channel_backend_init(GdkDisplay* display) {
  if (GDK_IS_WAYLAND_DISPLAY(display)) {
    return display_channel_backend_wayland_init(GDK_WAYLAND_DISPLAY(display));
  }
  return NULL;
}

void display_channel_backend_deinit(DisplayChannelBackend* self) {
  if (self != NULL) self->deinit(self);
}
