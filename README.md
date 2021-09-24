# Genesis

Gensis, formerly known as ExpidusOS Shell, is a next-gen desktop environment for mobile devices, desktops, laptops, and many other devices. This desktop environment is highly configurable and programmable with the ExpidusOS Settings application and Lua. New "UI modes" can be programmed and implemented via Lua. Since Lua is used, support for using LGI is built in. In the future, Genesis will be able to interact with services provided by Midstall Software for ExpidusOS to improve usability and quality of life features.

## Dependencies
* `valac` (build)
* meson (build)
* Mutter 8
* gtk3
* gtk-layer-shell (if `wayland`)
* lua
* SystemRT
* devident
* lgi (*optional*)