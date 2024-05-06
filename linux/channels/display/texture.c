#include <epoxy/gl.h>
#include "texture.h"

typedef struct _DisplayChannelTexturePrivate {
  GdkGLContext* gl_context;
  uint32_t name;
  uint32_t width;
  uint32_t height;
} DisplayChannelTexturePrivate;

enum {
  PROP_0 = 0,
  PROP_GL_CONTEXT,
  N_PROPERTIES,
};

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
    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID(obj, prop_id, pspec);
      break;
  }
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

  FL_TEXTURE_GL_CLASS(klass)->populate = display_channel_texture_populate;
}

static void display_channel_texture_init(DisplayChannelTexture* self) {}
