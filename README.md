# Genesis

**NOTE**: This branch is the WIP refactored version.

Genesis Shell is the next-generation fully featured desktop environment for ExpidusOS. At its core,
Genesis Shell can be ported to many different devices and display technologies due to its modular design.
Another feature of Genesis Shell is it is able to work on mobile devices and not just desktops.

Wallpaper free from **[unsplash.com](https://unsplash.com)**.

## Dependencies

If building from source, **must** pull the git submodules or allow meson to use the wrap files.

### Host

* `valac`
* `meson`
* `pkg-config`
* `valadoc` (if `docs` is **enabled**)

### Target

* `libdevident`
* `dbus-1` (if target is **linux**)
* `gio-2.0`
* `vadi`
* `libtokyo` (if `libtokyo-gtk3` or `libtokyo-gtk4` is present)
* `libtokyo-gtk3` (**optional**)
* `libtokyo-gtk4` (**optional**)
* `gtk+-wayland-3.0` (if `libtokyo-gtk3` is present, target is linux, and `wayland` is **enabled**)
* `gtk+-x11-3.0` (if `libtokyo-gtk3` is present, target is linux, and `wayland` is **enabled**)
* `gtk-layer-shell` (if `gtk+-wayland-3.0` is present)
* `libcallaudio` (**optional**)
* `libecal-2.0` (**optional**)
* `libnm` (**optional**)
* `upower-glib` (**optional**)
* `ibus-1.0` (**optional**)
