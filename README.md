# Genesis Shell

A next-gen compositor designed to adapt between mobile and desktop devices.
Genesis Shell is built using wlroots and Flutter. It runs a Wayland server inside
of the shell with the help of wlroots. To use it as a regular compositor, it is
recommended to use cage. Genesis Shell also supports multiple monitors with the
help of cage.

## Building

#### Linux

##### Dependencies

- `zig` (host)
- `flutter` (host, v3.23)
- `accountsservice` (target)
- `wlroots` v0.17 (target)
- Flutter Engine (target, v3.23)

### Compiling

Compiling Genesis Shell is done with Zig. It requires a build of the Flutter Engine.
To build, you will run `zig build`. It required `-Dengine-src=` to be the path to
your Flutter Engine source directory which contains `out`. You then specify `-Dengine-out=`
to be the name of the directory under `out` in the Flutter Engine source directory.
Then Zig will compile Genesis Shell and output it to `zig-out/bin/genesis-shell`.

## Status

### Completed

#### Tested

- Login / lock
- Power management

#### Untested

- Monitor management

### In-progress

- Window management

### Needed

- Brightness indicator
- Network indicator
- Polkit popup
- Wayland inputs
- User settings
- Xwayland server
