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
  free(self);
}

uint32_t* display_channel_backend_get_shm_formats(DisplayChannelBackend* self, size_t* len) {
  if (self->get_shm_formats == NULL) {
    if (len != NULL) *len = 0;
    return NULL;
  }
  return self->get_shm_formats(self, len);
}
