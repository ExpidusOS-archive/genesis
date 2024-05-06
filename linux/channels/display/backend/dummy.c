#include <wlr/backend/headless.h>
#include <wlr/render/pixman.h>
#include "../backend.h"
#include "dummy.h"

struct backend {
  DisplayChannelBackend base;
  struct wl_display* display;
  struct wlr_backend* headless;
  struct wlr_renderer* renderer;
};

static struct wl_display* base_get_display(DisplayChannelBackend* base) {
  struct backend* self = (struct backend*)base;
  return self->display;
}

static struct wlr_output* base_add_output(DisplayChannelBackend* base, unsigned int width, unsigned int height) {
  struct backend* self = (struct backend*)base;
  return wlr_headless_add_output(self->headless, width, height);
}

static struct wlr_renderer* base_get_renderer(DisplayChannelBackend* base) {
  struct backend* self = (struct backend*)base;
  return self->renderer;
}

static bool backend_start(struct wlr_backend* backend) {
  struct backend* self = (struct backend*)backend;
  return wlr_backend_start(self->headless);
}

static void backend_destroy(struct wlr_backend* backend) {
  struct backend* self = (struct backend*)backend;
  wlr_backend_finish(backend);
  wlr_backend_destroy(self->headless);
  wl_display_destroy(self->display);
}

static uint32_t get_buffer_caps(struct wlr_backend* backend) {
  return WLR_BUFFER_CAP_DATA_PTR | WLR_BUFFER_CAP_DMABUF | WLR_BUFFER_CAP_SHM;
}

static const struct wlr_backend_impl backend_impl = {
	.start = backend_start,
	.destroy = backend_destroy,
	.get_buffer_caps = get_buffer_caps,
};

struct wlr_backend* display_channel_backend_dummy_create() {
  struct backend* self = malloc(sizeof (struct backend));

  wlr_backend_init(&self->base.backend, &backend_impl);

  self->base.get_display = base_get_display;
  self->base.add_output = base_add_output;
  self->base.get_renderer = base_get_renderer;

  self->display = wl_display_create();
  self->headless = wlr_headless_backend_create(self->display);

  self->renderer = wlr_pixman_renderer_create();
  return &self->base.backend;
}
