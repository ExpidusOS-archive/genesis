#include "texture.h"

typedef struct _DisplayChannelTexturePrivate {
  int padding[1];
} DisplayChannelTexturePrivate;

G_DEFINE_TYPE_WITH_PRIVATE(DisplayChannelTexture, display_channel_texture, display_channel_texture_get_type());

static void display_channel_texture_class_init(DisplayChannelTextureClass* klass) {}
static void display_channel_texture_init(DisplayChannelTexture* self) {}
