# Genesis

Genesis Shell is a modular Wayland compositor based on Wayfire. The name "Genesis" was chosen as the shell is designed to be a "next-generation"
desktop environment. It is designed to be modular, the core of the shell is designed to not rely on any display backends. This means Genesis can be ported
between any display technology with little hassle. However, Genesis's component side depend on Wayland. This will be patched in the future to allow any
display backend work between instances.

Wallpaper free from **[unsplash.com](https://unsplash.com)**.

## Dependencies
* `valac` (build)
* `valadoc` (build)
* `meson` (build)
* Wayfire
* Wayfire Plugins Extra
* gtk4
* gtk+3.0
* gtk-layer-shell
* [devident](https://github.com/ExpidusOS/libdevident)
* NetworkManager
* ModemManager
* libgweather 3.0
* accountsservice
* libadwaita 1.0
* Libhandy 1.0
* Polkit Agent
* libpeas
* libdazzle

**Note**: as of 2021-12-23, Genesis Shell requires the [ExpidusOS fork of Wayfire](https://github.com/ExpidusOS/wayfire) until pull request [1392](https://github.com/WayfireWM/wayfire/pull/1392) is merged.

## Implemented Features & Components
* IBus
* XDG Desktop Portal
* Panel
* Desktop

## Needed Features & Components
* Notifications
* Lock Screen
* LightDM Greeter
* Application launcher
* Power menu