#include <epoxy/egl.h>
#include <epoxy/gl.h>
#include <drm_fourcc.h>
#include "pixel-format.h"
#include "texture.h"

typedef struct _DisplayChannelTexturePrivate {
  GdkGLContext* gl_context;
  uint32_t name;
  uint32_t width;
  uint32_t height;
  bool has_init;
} DisplayChannelTexturePrivate;

enum {
  PROP_0 = 0,
  PROP_GL_CONTEXT,
  PROP_HAS_INIT,
  N_PROPERTIES,
};

static GParamSpec* obj_props[N_PROPERTIES] = { NULL, };

G_DEFINE_TYPE_WITH_PRIVATE(DisplayChannelTexture, display_channel_texture, fl_texture_gl_get_type());

static void display_channel_texture_set_property(GObject* obj, guint prop_id, const GValue* value, GParamSpec* pspec) {
  DisplayChannelTexture* self = DISPLAY_CHANNEL_TEXTURE(obj);
  DisplayChannelTexturePrivate* priv = display_channel_texture_get_instance_private(self);

  switch (prop_id) {
    case PROP_GL_CONTEXT:
      g_clear_object(&priv->gl_context);
      priv->gl_context = g_value_dup_object(value);
      break;
    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID(obj, prop_id, pspec);
      break;
  }
}

static void display_channel_texture_get_property(GObject* obj, guint prop_id, GValue* value, GParamSpec* pspec) {
  DisplayChannelTexture* self = DISPLAY_CHANNEL_TEXTURE(obj);
  DisplayChannelTexturePrivate* priv = display_channel_texture_get_instance_private(self);

  switch (prop_id) {
    case PROP_GL_CONTEXT:
      g_value_set_object(value, priv->gl_context);
      break;
    case PROP_HAS_INIT:
      g_value_set_boolean(value, priv->has_init);
      break;
    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID(obj, prop_id, pspec);
      break;
  }
}

static void display_channel_texture_dispose(GObject* obj) {
  DisplayChannelTexture* self = DISPLAY_CHANNEL_TEXTURE(obj);
  DisplayChannelTexturePrivate* priv = display_channel_texture_get_instance_private(self);

  g_clear_object(&priv->gl_context);

  G_OBJECT_CLASS(display_channel_texture_parent_class)->dispose(obj);
}

static gboolean display_channel_texture_populate(FlTextureGL* tex, uint32_t* target, uint32_t* name, uint32_t* width, uint32_t* height, GError** error) {
  DisplayChannelTexture* self = DISPLAY_CHANNEL_TEXTURE(tex);
  DisplayChannelTexturePrivate* priv = display_channel_texture_get_instance_private(self);

  *target = GL_TEXTURE_2D;
  *name = priv->name;
  *width = priv->width;
  *height = priv->height;
  return TRUE;
}

static void display_channel_texture_class_init(DisplayChannelTextureClass* klass) {
  GObjectClass* obj_class = G_OBJECT_CLASS(klass);

  obj_class->set_property = display_channel_texture_set_property;
  obj_class->get_property = display_channel_texture_get_property;
  obj_class->dispose = display_channel_texture_dispose;

  FL_TEXTURE_GL_CLASS(klass)->populate = display_channel_texture_populate;

  obj_props[PROP_GL_CONTEXT] = g_param_spec_object("gl-context", "GL Context", "The OpenGL context in GDK to use", GDK_TYPE_GL_CONTEXT, G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY);
  obj_props[PROP_HAS_INIT] = g_param_spec_boolean("has-init", "Has initial update", "Whether the texture has done an initial update", false, G_PARAM_READABLE);
  g_object_class_install_properties(obj_class, N_PROPERTIES, obj_props);
}

static void display_channel_texture_init(DisplayChannelTexture* self) {}

DisplayChannelTexture* display_channel_texture_new(GdkGLContext* gl_context, struct wlr_buffer* buffer) {
  DisplayChannelTexture* self = DISPLAY_CHANNEL_TEXTURE(g_object_new(display_channel_texture_get_type(), "gl-context", gl_context, NULL));
  g_return_val_if_fail(self != NULL, NULL);

  DisplayChannelTexturePrivate* priv = display_channel_texture_get_instance_private(self);
  gdk_gl_context_make_current(priv->gl_context);
  glGenTextures(1, &priv->name);
  gdk_gl_context_clear_current();

  priv->has_init = false;
  display_channel_texture_update(self, buffer);
  return self;
}

void display_channel_texture_update(DisplayChannelTexture* self, struct wlr_buffer* buffer) {
  DisplayChannelTexturePrivate* priv = display_channel_texture_get_instance_private(self);
  gdk_gl_context_make_current(priv->gl_context);

  struct wlr_dmabuf_attributes dmabuf;
  if (wlr_buffer_get_dmabuf(buffer, &dmabuf)) {
    unsigned int atti = 0;
    EGLint attribs[50];
    attribs[atti++] = EGL_WIDTH;
    attribs[atti++] = dmabuf.width;
    attribs[atti++] = EGL_HEIGHT;
    attribs[atti++] = dmabuf.height;
    attribs[atti++] = EGL_LINUX_DRM_FOURCC_EXT;
    attribs[atti++] = dmabuf.format;

    struct {
		  EGLint fd;
		  EGLint offset;
		  EGLint pitch;
		  EGLint mod_lo;
		  EGLint mod_hi;
	  } attr_names[WLR_DMABUF_MAX_PLANES] = {
		  {
			  EGL_DMA_BUF_PLANE0_FD_EXT,
			  EGL_DMA_BUF_PLANE0_OFFSET_EXT,
			  EGL_DMA_BUF_PLANE0_PITCH_EXT,
			  EGL_DMA_BUF_PLANE0_MODIFIER_LO_EXT,
			  EGL_DMA_BUF_PLANE0_MODIFIER_HI_EXT
  		}, {
	  		EGL_DMA_BUF_PLANE1_FD_EXT,
		  	EGL_DMA_BUF_PLANE1_OFFSET_EXT,
			  EGL_DMA_BUF_PLANE1_PITCH_EXT,
  			EGL_DMA_BUF_PLANE1_MODIFIER_LO_EXT,
	  		EGL_DMA_BUF_PLANE1_MODIFIER_HI_EXT
		  }, {
  			EGL_DMA_BUF_PLANE2_FD_EXT,
	  		EGL_DMA_BUF_PLANE2_OFFSET_EXT,
		  	EGL_DMA_BUF_PLANE2_PITCH_EXT,
			  EGL_DMA_BUF_PLANE2_MODIFIER_LO_EXT,
  			EGL_DMA_BUF_PLANE2_MODIFIER_HI_EXT
	  	}, {
		  	EGL_DMA_BUF_PLANE3_FD_EXT,
			  EGL_DMA_BUF_PLANE3_OFFSET_EXT,
  			EGL_DMA_BUF_PLANE3_PITCH_EXT,
	  		EGL_DMA_BUF_PLANE3_MODIFIER_LO_EXT,
		  	EGL_DMA_BUF_PLANE3_MODIFIER_HI_EXT
		  }
	  };

	  for (int i = 0; i < dmabuf.n_planes; i++) {
  		attribs[atti++] = attr_names[i].fd;
		  attribs[atti++] = dmabuf.fd[i];
	  	attribs[atti++] = attr_names[i].offset;
  		attribs[atti++] = dmabuf.offset[i];
		  attribs[atti++] = attr_names[i].pitch;
	  	attribs[atti++] = dmabuf.stride[i];
  		if (dmabuf.modifier != DRM_FORMAT_MOD_INVALID) {
			  attribs[atti++] = attr_names[i].mod_lo;
		  	attribs[atti++] = dmabuf.modifier & 0xFFFFFFFF;
	  		attribs[atti++] = attr_names[i].mod_hi;
  			attribs[atti++] = dmabuf.modifier >> 32;
		  }
	  }

    attribs[atti++] = EGL_IMAGE_PRESERVED_KHR;
    attribs[atti++] = EGL_TRUE;
    attribs[atti++] = EGL_NONE;

    EGLImageKHR img = eglCreateImageKHR(eglGetCurrentDisplay(), EGL_NO_CONTEXT, EGL_LINUX_DMA_BUF_EXT, NULL, attribs);
    if (img == EGL_NO_IMAGE_KHR) {
      gdk_gl_context_clear_current();
      g_return_if_fail(false);
      return;
    }

    glBindTexture(GL_TEXTURE_2D, priv->name);

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glEGLImageTargetTexture2DOES(GL_TEXTURE_2D, img);

    glBindTexture(GL_TEXTURE_2D, 0);
    eglDestroyImage(eglGetCurrentDisplay(), img);
    gdk_gl_context_clear_current();

    priv->has_init = true;
    return;
  }

  size_t stride = 0;
  uint32_t fmt = 0;
  void* data = NULL;
  wlr_buffer_begin_data_ptr_access(buffer, WLR_BUFFER_DATA_PTR_ACCESS_READ, &data, &fmt, &stride);

  const struct wlr_gles2_pixel_format* gles2_fmt = get_gles2_format_from_drm(fmt);
  g_return_if_fail(gles2_fmt != NULL);

  const struct wlr_pixel_format_info* drm_fmt = drm_get_pixel_format_info(fmt);
  g_return_if_fail(drm_fmt != NULL);

  glBindTexture(GL_TEXTURE_2D, priv->name);

  priv->width = buffer->width;
  priv->height = buffer->height;

  GLint internal_format = gles2_fmt->gl_internalformat;
	if (!internal_format) internal_format = gles2_fmt->gl_format;

  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	glPixelStorei(GL_UNPACK_ROW_LENGTH_EXT, stride / drm_fmt->bytes_per_block);
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, priv->width, priv->height, 0, gles2_fmt->gl_format, gles2_fmt->gl_type, data);
	glPixelStorei(GL_UNPACK_ROW_LENGTH_EXT, 0);

  glBindTexture(GL_TEXTURE_2D, 0);

  wlr_buffer_end_data_ptr_access(buffer);
  gdk_gl_context_clear_current();

  priv->has_init = true;
}
