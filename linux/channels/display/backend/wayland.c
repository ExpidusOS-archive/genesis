#include <sys/mman.h>
#include <sys/types.h>
#include <wlr/render/drm_format_set.h>
#include <drm_fourcc.h>
#include <unistd.h>
#include <xf86drm.h>

#include <linux-dmabuf-v1-client-protocol.h>
#include "wayland.h"

struct Backend {
  DisplayChannelBackend base;
  char* drm_render_name;

  struct wl_shm* shm;
  struct zwp_linux_dmabuf_v1* zwp_linux_dmabuf_v1;

  struct wlr_drm_format_set shm_formats;
  struct wlr_drm_format_set linux_dmabuf_v1_formats;
};

struct DmabufFeedbackData {
  struct Backend* backend;

  dev_t main_device_id;
	struct DmabufFeedbackDataTableEntry* format_table;
	size_t format_table_size;

	dev_t tranche_target_device_id;
};

struct DmabufFeedbackDataTableEntry {
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
  struct Backend* self = data;
	wlr_drm_format_set_add(&self->linux_dmabuf_v1_formats, format, DRM_FORMAT_MOD_INVALID);
}

static void linux_dmabuf_v1_handle_modifier(void* data, struct zwp_linux_dmabuf_v1* linux_dmabuf_v1, uint32_t format, uint32_t modifier_hi, uint32_t modifier_lo) {
  struct Backend* self = data;

  uint64_t modifier = ((uint64_t)modifier_hi << 32) | modifier_lo;
	wlr_drm_format_set_add(&self->linux_dmabuf_v1_formats, format, modifier);
}

static const struct zwp_linux_dmabuf_v1_listener linux_dmabuf_v1_listener = {
	.format = linux_dmabuf_v1_handle_format,
	.modifier = linux_dmabuf_v1_handle_modifier,
};

static void linux_dmabuf_feedback_v1_handle_done(void* data, struct zwp_linux_dmabuf_feedback_v1* feedback) {}

static void linux_dmabuf_feedback_v1_handle_format_table(void* data, struct zwp_linux_dmabuf_feedback_v1* feedback, int fd, uint32_t size) {
  struct DmabufFeedbackData* feedback_data = data;

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
  struct DmabufFeedbackData* feedback_data = data;

  dev_t dev_id;
	g_assert(dev_id_arr->size == sizeof(dev_id));
	memcpy(&dev_id, dev_id_arr->data, sizeof(dev_id));

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

static void linux_dmabuf_feedback_v1_handle_tranche_done(void* data, struct zwp_linux_dmabuf_feedback_v1* feedback) {
  struct DmabufFeedbackData* feedback_data = data;
  feedback_data->tranche_target_device_id = 0;
}

static void linux_dmabuf_feedback_v1_handle_tranche_target_device(void* data, struct zwp_linux_dmabuf_feedback_v1* feedback, struct wl_array* dev_id_arr) {
  struct DmabufFeedbackData* feedback_data = data;

  dev_t dev_id;
	g_assert(dev_id_arr->size == sizeof(dev_id));
	memcpy(&dev_id, dev_id_arr->data, sizeof(dev_id));

	feedback_data->tranche_target_device_id = dev_id;
}

static void linux_dmabuf_feedback_v1_handle_tranche_formats(void* data, struct zwp_linux_dmabuf_feedback_v1* feedback, struct wl_array* indices_arr) {
  struct DmabufFeedbackData* feedback_data = data;

  if (feedback_data->format_table == NULL) return;
	if (feedback_data->tranche_target_device_id != feedback_data->main_device_id) return;

	size_t table_cap = feedback_data->format_table_size / sizeof(struct DmabufFeedbackDataTableEntry);
	uint16_t* index_ptr;
	wl_array_for_each(index_ptr, indices_arr) {
		g_assert(*index_ptr < table_cap);
		const struct DmabufFeedbackDataTableEntry* entry = &feedback_data->format_table[*index_ptr];
		wlr_drm_format_set_add(&feedback_data->backend->linux_dmabuf_v1_formats, entry->format, entry->modifier);
	}
}

static void linux_dmabuf_feedback_v1_handle_tranche_flags(void* data, struct zwp_linux_dmabuf_feedback_v1* feedback, uint32_t flags) {
  // TODO: handle SCANOUT flag
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
	struct Backend* self = data;
	uint32_t drm_format = convert_wl_shm_format_to_drm(shm_format);
	wlr_drm_format_set_add(&self->shm_formats, drm_format, DRM_FORMAT_MOD_INVALID);
}

static const struct wl_shm_listener shm_listener = {
	.format = shm_handle_format,
};

static void handle_global(void* data, struct wl_registry* registry, uint32_t id, const char* interface, uint32_t version) {
  struct Backend* self = (struct Backend*)data;

  if (strcmp(interface, zwp_linux_dmabuf_v1_interface.name) == 0) {
    g_warn_if_fail(zwp_linux_dmabuf_v1_interface.version >= 4);

    self->zwp_linux_dmabuf_v1 = wl_registry_bind(registry, id, &zwp_linux_dmabuf_v1_interface, version >= 4 ? 4 : version);
		zwp_linux_dmabuf_v1_add_listener(self->zwp_linux_dmabuf_v1, &linux_dmabuf_v1_listener, self);
  } else if (strcmp(interface, wl_shm_interface.name) == 0) {
		self->shm = wl_registry_bind(registry, id, &wl_shm_interface, 1);
		wl_shm_add_listener(self->shm, &shm_listener, self);
  } else {
    g_message("%s:%d", interface, version);
  }
}

static void handle_global_remove(void* data, struct wl_registry* registry, uint32_t id) {}

static const struct wl_registry_listener wl_registry_listener = {
  .global = handle_global,
  .global_remove = handle_global_remove,
};

static void deinit(DisplayChannelBackend* base) {
  struct Backend* self = (struct Backend*)base;

  wlr_drm_format_set_finish(&self->shm_formats);
  wlr_drm_format_set_finish(&self->linux_dmabuf_v1_formats);

  g_clear_pointer(&self->shm, wl_shm_destroy);
  free(self->drm_render_name);
  free(self);
}

static uint32_t* get_shm_formats(DisplayChannelBackend* base, size_t* len) {
  struct Backend* self = (struct Backend*)base;

  if (len != NULL) *len = self->shm_formats.len;

  uint32_t* list = malloc(sizeof (uint32_t) * self->shm_formats.len);
  for (size_t i = 0; i < self->shm_formats.len; i++) {
    list[i] = self->shm_formats.formats[i].format;
  }
  return list;
}

DisplayChannelBackend* display_channel_backend_wayland_init(GdkWaylandDisplay* disp) {
  struct Backend* self = malloc(sizeof (struct Backend));
  memset(self, 0, sizeof (struct Backend));
  self->base.deinit = deinit;
  self->base.get_shm_formats = get_shm_formats;

  struct wl_display* wl_display = gdk_wayland_display_get_wl_display(disp);
  struct wl_registry* wl_registry_global = wl_display_get_registry(wl_display);
  wl_registry_add_listener(wl_registry_global, &wl_registry_listener, self);
  wl_display_roundtrip(wl_display);

  if (self->zwp_linux_dmabuf_v1 != NULL && zwp_linux_dmabuf_v1_get_version(self->zwp_linux_dmabuf_v1) >= ZWP_LINUX_DMABUF_V1_GET_DEFAULT_FEEDBACK_SINCE_VERSION) {
    struct zwp_linux_dmabuf_feedback_v1* linux_dmabuf_feedback_v1 = zwp_linux_dmabuf_v1_get_default_feedback(self->zwp_linux_dmabuf_v1);
    if (linux_dmabuf_feedback_v1 != NULL) {
      struct DmabufFeedbackData feedback_data = { .backend = self };
      zwp_linux_dmabuf_feedback_v1_add_listener(linux_dmabuf_feedback_v1, &linux_dmabuf_feedback_v1_listener, &feedback_data);
      wl_display_roundtrip(wl_display);

      if (feedback_data.format_table != NULL) {
        munmap(feedback_data.format_table, feedback_data.format_table_size);
      }

      zwp_linux_dmabuf_feedback_v1_destroy(linux_dmabuf_feedback_v1);
    }
  }

  g_message("%s", self->drm_render_name);
  return &self->base;
}
