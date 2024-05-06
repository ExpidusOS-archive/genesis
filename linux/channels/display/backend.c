#include "backend/dummy.h"
#include "backend/wayland.h"
#include "backend.h"

struct wlr_backend* display_channel_backend_create(GdkDisplay* display) {
  if (GDK_IS_WAYLAND_DISPLAY(display)) {
    return display_channel_backend_wayland_create(GDK_WAYLAND_DISPLAY(display));
  }

  return display_channel_backend_dummy_create();
}

struct wl_display* display_channel_backend_get_display(struct wlr_backend* backend) {
  DisplayChannelBackend* self = (DisplayChannelBackend*)backend;
  return self->get_display(self);
}

struct wlr_output* display_channel_backend_add_output(struct wlr_backend* backend, unsigned int width, unsigned int height) {
  DisplayChannelBackend* self = (DisplayChannelBackend*)backend;
  return self->add_output(self, width, height);
}
