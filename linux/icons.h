#pragma once

#include <gio/gio.h>
#include <gtk/gtk.h>

#ifdef __cplusplus
extern "C" {
#endif

const gchar* icon_get_filename(GIcon* icon, size_t size);

#ifdef __cplusplus
}
#endif
