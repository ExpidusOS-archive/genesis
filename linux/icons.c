#include "icons.h"

const gchar* icon_get_filename(GIcon* icon, size_t size) {
  if (icon != NULL) {
    if (G_IS_FILE_ICON(icon)) {
      GFile* file = g_file_icon_get_file(G_FILE_ICON(icon));
      return g_file_get_path(file);
    } else if (G_IS_THEMED_ICON(icon)) {
      GtkIconTheme* theme = gtk_icon_theme_get_default();
      GtkIconInfo* icon_info = gtk_icon_theme_lookup_by_gicon(theme, icon, size, (GtkIconLookupFlags)0);
      if (icon_info != NULL) {
        return gtk_icon_info_get_filename(icon_info);
      }
    }
  }
  return NULL;
}
