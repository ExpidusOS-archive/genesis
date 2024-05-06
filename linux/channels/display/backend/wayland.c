#include <sys/mman.h>
#include <sys/types.h>
#include <wlr/backend/headless.h>
#include <wlr/types/wlr_linux_dmabuf_v1.h>
#include <wlr/types/wlr_shm.h>
#include <wlr/render/egl.h>
#include <wlr/render/gles2.h>
#include <wlr/render/drm_format_set.h>
#include <drm_fourcc.h>
#include <fcntl.h>
#include <unistd.h>
#include <xf86drm.h>

#include <linux-dmabuf-v1-client-protocol.h>
#include "../backend.h"
#include "wayland.h"

struct backend {
  DisplayChannelBackend base;

  struct wl_display* display;
  struct wlr_backend* headless;
  struct wlr_renderer* renderer;

  char* drm_render_name;
  int drm_fd;

  struct wl_shm* shm;
  struct zwp_linux_dmabuf_v1* zwp_linux_dmabuf_v1;

  struct wlr_drm_format_set shm_formats;
  struct wlr_drm_format_set linux_dmabuf_v1_formats;

  struct wlr_linux_dmabuf_feedback_v1 default_feedback;
};

struct dmabuf_feedback_data {
  struct backend* backend;

  dev_t main_device_id;
	struct dmabuf_feedback_data_table_entry* format_table;
	size_t format_table_size;

	dev_t tranche_target_device_id;

  size_t tranches_done;
};

struct dmabuf_feedback_data_table_entry {
  uint32_t format;
	uint32_t pad;
	uint64_t modifier;
};

uint32_t convert_wl_shm_format_to_drm(enum wl_shm_format fmt) {
	switch (fmt) {
    case WL_SHM_FORMAT_XRGB8888: return DRM_FORMAT_XRGB8888;
    case WL_SHM_FORMAT_ARGB8888: return DRM_FORMAT_ARGB8888;
    default: return (uint32_t)fmt;
	}
}

static void linux_dmabuf_v1_handle_format(void* data, struct zwp_linux_dmabuf_v1* linux_dmabuf_v1, uint32_t format) {
  struct backend* self = data;
	wlr_drm_format_set_add(&self->linux_dmabuf_v1_formats, format, DRM_FORMAT_MOD_INVALID);
}

static void linux_dmabuf_v1_handle_modifier(void* data, struct zwp_linux_dmabuf_v1* linux_dmabuf_v1, uint32_t format, uint32_t modifier_hi, uint32_t modifier_lo) {
  struct backend* self = data;

  uint64_t modifier = ((uint64_t)modifier_hi << 32) | modifier_lo;
	wlr_drm_format_set_add(&self->linux_dmabuf_v1_formats, format, modifier);
}

static const struct zwp_linux_dmabuf_v1_listener linux_dmabuf_v1_listener = {
	.format = linux_dmabuf_v1_handle_format,
	.modifier = linux_dmabuf_v1_handle_modifier,
};

static void linux_dmabuf_feedback_v1_handle_done(void* data, struct zwp_linux_dmabuf_feedback_v1* feedback) {}

static void linux_dmabuf_feedback_v1_handle_format_table(void* data, struct zwp_linux_dmabuf_feedback_v1* feedback, int fd, uint32_t size) {
  struct dmabuf_feedback_data* feedback_data = data;

  feedback_data->format_table = NULL;

	void* table_data = mmap(NULL, size, PROT_READ, MAP_PRIVATE, fd, 0);
	if (table_data == MAP_FAILED) {
		g_error("failed to mmap DMA-BUF format table");
	} else {
		feedback_data->format_table = table_data;
		feedback_data->format_table_size = size;
	}
	close(fd);
}

static void linux_dmabuf_feedback_v1_handle_main_device(void* data, struct zwp_linux_dmabuf_feedback_v1* feedback, struct wl_array* dev_id_arr) {
  struct dmabuf_feedback_data* feedback_data = data;

  dev_t dev_id;
	g_assert(dev_id_arr->size == sizeof(dev_id));
	memcpy(&dev_id, dev_id_arr->data, sizeof(dev_id));

  feedback_data->backend->default_feedback.main_device = dev_id;
	feedback_data->main_device_id = dev_id;

	drmDevice* device = NULL;
	if (drmGetDeviceFromDevId(dev_id, 0, &device) != 0) {
		g_error("drmGetDeviceFromDevId failed");
		return;
	}

	const char* name = NULL;
	if (device->available_nodes & (1 << DRM_NODE_RENDER)) {
		name = device->nodes[DRM_NODE_RENDER];
	} else {
		// Likely a split display/render setup. Pick the primary node and hope
		// Mesa will open the right render node under-the-hood.
		g_assert(device->available_nodes & (1 << DRM_NODE_PRIMARY));
		name = device->nodes[DRM_NODE_PRIMARY];
		g_debug("DRM device %s has no render node, falling back to primary node", name);
	}

	feedback_data->backend->drm_render_name = strdup(name);

	drmFreeDevice(&device);
}

static struct wlr_linux_dmabuf_feedback_v1_tranche* get_tranche(struct dmabuf_feedback_data* feedback_data) {
  size_t feedback_tranches_size = feedback_data->backend->default_feedback.tranches.size;
  size_t done_count = feedback_data->tranches_done;
  size_t feedback_tranches_done = feedback_tranches_size / sizeof (struct wlr_linux_dmabuf_feedback_v1_tranche);

  if ((feedback_tranches_done != done_count) || (feedback_tranches_size == 0 && done_count == 0)) {
    struct wlr_linux_dmabuf_feedback_v1_tranche* entry = wl_array_add(&feedback_data->backend->default_feedback.tranches, sizeof (struct wlr_linux_dmabuf_feedback_v1_tranche));
    memset(entry, 0, sizeof (struct wlr_linux_dmabuf_feedback_v1_tranche));
    entry->target_device = feedback_data->main_device_id;
    return entry;
  }

  return feedback_data->backend->default_feedback.tranches.data + (sizeof (struct wlr_linux_dmabuf_feedback_v1_tranche) * done_count);
}

static void linux_dmabuf_feedback_v1_handle_tranche_done(void* data, struct zwp_linux_dmabuf_feedback_v1* feedback) {
  struct dmabuf_feedback_data* feedback_data = data;
  feedback_data->tranche_target_device_id = 0;
  feedback_data->tranches_done += 1;
}

static void linux_dmabuf_feedback_v1_handle_tranche_target_device(void* data, struct zwp_linux_dmabuf_feedback_v1* feedback, struct wl_array* dev_id_arr) {
  struct dmabuf_feedback_data* feedback_data = data;
  struct wlr_linux_dmabuf_feedback_v1_tranche* tranche = get_tranche(feedback_data);

  dev_t dev_id;
	g_assert(dev_id_arr->size == sizeof(dev_id));
	memcpy(&dev_id, dev_id_arr->data, sizeof(dev_id));

  tranche->target_device = dev_id;
	feedback_data->tranche_target_device_id = dev_id;
}

static void linux_dmabuf_feedback_v1_handle_tranche_formats(void* data, struct zwp_linux_dmabuf_feedback_v1* feedback, struct wl_array* indices_arr) {
  struct dmabuf_feedback_data* feedback_data = data;
  struct wlr_linux_dmabuf_feedback_v1_tranche* tranche = get_tranche(feedback_data);

  if (feedback_data->format_table == NULL) return;
	if (feedback_data->tranche_target_device_id != feedback_data->main_device_id) return;

	size_t table_cap = feedback_data->format_table_size / sizeof(struct dmabuf_feedback_data_table_entry);
	uint16_t* index_ptr;
	wl_array_for_each(index_ptr, indices_arr) {
		g_assert(*index_ptr < table_cap);
		const struct dmabuf_feedback_data_table_entry* entry = &feedback_data->format_table[*index_ptr];
		wlr_drm_format_set_add(&feedback_data->backend->linux_dmabuf_v1_formats, entry->format, entry->modifier);
		wlr_drm_format_set_add(&tranche->formats, entry->format, entry->modifier);
	}
}

static void linux_dmabuf_feedback_v1_handle_tranche_flags(void* data, struct zwp_linux_dmabuf_feedback_v1* feedback, uint32_t flags) {
  struct dmabuf_feedback_data* feedback_data = data;
  struct wlr_linux_dmabuf_feedback_v1_tranche* tranche = get_tranche(feedback_data);
  tranche->flags = flags;
}

static const struct zwp_linux_dmabuf_feedback_v1_listener linux_dmabuf_feedback_v1_listener = {
  .done = linux_dmabuf_feedback_v1_handle_done,
  .format_table = linux_dmabuf_feedback_v1_handle_format_table,
  .main_device = linux_dmabuf_feedback_v1_handle_main_device,
  .tranche_done = linux_dmabuf_feedback_v1_handle_tranche_done,
  .tranche_target_device = linux_dmabuf_feedback_v1_handle_tranche_target_device,
  .tranche_formats = linux_dmabuf_feedback_v1_handle_tranche_formats,
  .tranche_flags = linux_dmabuf_feedback_v1_handle_tranche_flags,
};

static void shm_handle_format(void* data, struct wl_shm* shm, uint32_t shm_format) {
	struct backend* self = data;
	uint32_t drm_format = convert_wl_shm_format_to_drm(shm_format);
	wlr_drm_format_set_add(&self->shm_formats, drm_format, DRM_FORMAT_MOD_INVALID);
}

static const struct wl_shm_listener shm_listener = {
	.format = shm_handle_format,
};

static void handle_global(void* data, struct wl_registry* registry, uint32_t id, const char* interface, uint32_t version) {
  struct backend* self = (struct backend*)data;

  if (strcmp(interface, zwp_linux_dmabuf_v1_interface.name) == 0) {
    g_warn_if_fail(zwp_linux_dmabuf_v1_interface.version >= 4);

    self->zwp_linux_dmabuf_v1 = wl_registry_bind(registry, id, &zwp_linux_dmabuf_v1_interface, version >= 4 ? 4 : version);
		zwp_linux_dmabuf_v1_add_listener(self->zwp_linux_dmabuf_v1, &linux_dmabuf_v1_listener, self);
  } else if (strcmp(interface, wl_shm_interface.name) == 0) {
		self->shm = wl_registry_bind(registry, id, &wl_shm_interface, 1);
		wl_shm_add_listener(self->shm, &shm_listener, self);
  }
}

static void handle_global_remove(void* data, struct wl_registry* registry, uint32_t id) {}

static const struct wl_registry_listener wl_registry_listener = {
  .global = handle_global,
  .global_remove = handle_global_remove,
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

  wlr_drm_format_set_finish(&self->shm_formats);
  wlr_drm_format_set_finish(&self->linux_dmabuf_v1_formats);

  g_clear_pointer(&self->shm, wl_shm_destroy);
  wl_array_release(&self->default_feedback.tranches);

  close(self->drm_fd);
  g_clear_pointer(&self->drm_render_name, g_free);

  wlr_backend_destroy(self->headless);
  wl_display_destroy(self->display);
}

static int backend_get_drm_fd(struct wlr_backend* backend) {
  struct backend* self = (struct backend*)backend;
  return self->drm_fd;
}

static uint32_t get_buffer_caps(struct wlr_backend* backend) {
  struct backend* self = (struct backend*)backend;
  return (self->zwp_linux_dmabuf_v1 ? WLR_BUFFER_CAP_DMABUF : 0) | (self->shm ? WLR_BUFFER_CAP_SHM : 0);
}

static const struct wlr_backend_impl backend_impl = {
	.start = backend_start,
	.destroy = backend_destroy,
  .get_drm_fd = backend_get_drm_fd,
	.get_buffer_caps = get_buffer_caps,
};

struct wlr_backend* display_channel_backend_wayland_create(GdkWaylandDisplay* disp) {
  struct backend* self = malloc(sizeof (struct backend));
  memset(self, 0, sizeof (struct backend));

  wlr_backend_init(&self->base.backend, &backend_impl);

  self->base.get_display = base_get_display;
  self->base.add_output = base_add_output;
  self->base.get_renderer = base_get_renderer;

  self->display = wl_display_create();
  self->headless = wlr_headless_backend_create(self->display);

  struct wl_display* wl_display = gdk_wayland_display_get_wl_display(disp);
  struct wl_registry* wl_registry_global = wl_display_get_registry(wl_display);
  wl_registry_add_listener(wl_registry_global, &wl_registry_listener, self);
  wl_display_roundtrip(wl_display);

  if (self->zwp_linux_dmabuf_v1 != NULL && zwp_linux_dmabuf_v1_get_version(self->zwp_linux_dmabuf_v1) >= ZWP_LINUX_DMABUF_V1_GET_DEFAULT_FEEDBACK_SINCE_VERSION) {
    struct zwp_linux_dmabuf_feedback_v1* linux_dmabuf_feedback_v1 = zwp_linux_dmabuf_v1_get_default_feedback(self->zwp_linux_dmabuf_v1);
    if (linux_dmabuf_feedback_v1 != NULL) {
      wl_array_init(&self->default_feedback.tranches);

      struct dmabuf_feedback_data feedback_data = { .backend = self };
      zwp_linux_dmabuf_feedback_v1_add_listener(linux_dmabuf_feedback_v1, &linux_dmabuf_feedback_v1_listener, &feedback_data);
      wl_display_roundtrip(wl_display);

      if (feedback_data.format_table != NULL) {
        munmap(feedback_data.format_table, feedback_data.format_table_size);
      }

      zwp_linux_dmabuf_feedback_v1_destroy(linux_dmabuf_feedback_v1);
    }
  }

  if (self->drm_render_name != NULL) {
		self->drm_fd = open(self->drm_render_name, O_RDWR | O_NONBLOCK | O_CLOEXEC);
    if (self->drm_fd < 0) {
      g_error("Failed to open %s", self->drm_render_name);
    }
	} else {
		self->drm_fd = -1;
	}

  self->renderer = wlr_gles2_renderer_create(wlr_egl_create_with_context(eglGetDisplay(wl_display), eglGetCurrentContext()));
  return &self->base.backend;
}
