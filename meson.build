project('genesis-shell', 'vala', 'c', license: 'GPL-3.0-only', version: '0.1.0-prealpha')

vapi_dir = meson.current_source_dir() / 'vapi'
add_project_arguments(['--vapidir', vapi_dir], language: 'vala')
add_project_arguments(['--vapidir', vapi_dir / 'vala-extra-vapis'], language: 'vala')
add_project_arguments(['--vapidir', '/usr/share/vala/vapi'], language: 'vala')

gnome = import('gnome')

x11 = get_option('x11')
wayland = get_option('wayland')

prefix = get_option('prefix')
bindir = prefix / get_option('bindir')
datadir = prefix / get_option('datadir')

accountsservice = dependency('accountsservice')
gobject = dependency('gobject-2.0')
gtk = [dependency('gtk+-3.0')]
lua = dependency('lua')
gio = [dependency('gio-2.0'), dependency('gio-unix-2.0')]
mutter = [dependency('libmutter-8'), dependency('mutter-cogl-8'), dependency('mutter-clutter-8'),
	dependency('gsettings-desktop-schemas')]
devident = dependency('devident-1.0')
hdy = dependency('libhandy-1')
dbusmenugtk = [dependency('dbusmenu-gtk3-0.4'), dependency('dbusmenu-glib-0.4')]
posix = meson.get_compiler('vala').find_library('posix')

conf_data = configuration_data()
conf_data.set('PREFIX', prefix)
conf_data.set('BINDIR', bindir)
conf_data.set('DATADIR', datadir)
conf_data.set('VERSION', meson.project_version())
conf_data.set('BUILD_X11', x11)
conf_data.set('BUILD_WAYLAND', wayland)

if x11
	gtk += [dependency('gdk-x11-3.0'), dependency('x11')]
	add_project_arguments('-D', 'BUILD_X11', language: 'vala')

	configure_file(input: 'data/xsessions/genesis.desktop.in', output: 'genesis.desktop',
		configuration: conf_data,
		install: true,
		install_dir: join_paths(datadir, 'xsessions'))
endif

if wayland
	gtk += [dependency('gdk-wayland-3.0'), dependency('gtk-layer-shell-0')]
	add_project_arguments('-D', 'BUILD_WAYLAND', language: 'vala')
	configure_file(input: 'data/wayland-sessions/genesis.desktop.in', output: 'genesis.desktop',
		configuration: conf_data,
		install: true,
		install_dir: join_paths(datadir, 'wayland-sessions'))
endif

subdir('po')

build_conf_h = configure_file(input: 'src/build.h.in', output: 'build.h',
	configuration: conf_data)
build_conf = configure_file(input: 'src/build.vala.in', output: 'build.vala',
	configuration: conf_data)

libgenesis_component = shared_library('genesis-component', ['src/lib/component/component.vala', build_conf],
	dependencies: [gobject, gtk],
	vala_gir: 'GenesisComponent-1.0.gir',
	install: true,
	install_dir: [true, true, true, true])
libgenesis_component_dep = declare_dependency(link_with: libgenesis_component, dependencies: [gobject, gtk])

libgenesis_notifications = shared_library('genesis-notifications', ['src/lib/notifications/client.vala', 'src/lib/notifications/iface.vala',
		'src/lib/notifications/server.vala'],
	dependencies: [gobject, gio],
	vala_gir: 'GenesisNotifications-1.0.gir',
	install: true,
	install_dir: [true, true, true, true])
libgenesis_notifications_dep = declare_dependency(link_with: libgenesis_notifications, dependencies: [gobject, gio])

libgenesis_shell = shared_library('genesis-shell', [build_conf, 'src/lib/shell/component.vala', 'src/lib/shell/error.vala',
		'src/lib/shell/misd.vala', 'src/lib/shell/shell.vala'],
	dependencies: [gobject, gio, lua, devident, posix],
	vala_gir: 'GenesisShell-1.0.gir',
	install: true,
	install_dir: [true, true, true, true])
libgenesis_shell_dep = declare_dependency(link_with: libgenesis_shell, dependencies: [gobject, gio, lua, devident])

libgenesis_widgets = shared_library('genesis-widgets', ['src/lib/widgets/app-grid.vala', 'src/lib/widgets/app-launcher.vala',
		'src/lib/widgets/clock.vala', 'src/lib/widgets/global-menu.vala', 'src/lib/widgets/lua.vala', 'src/lib/widgets/misc.vala',
		'src/lib/widgets/tray.vala', 'src/lib/widgets/user.vala', 'src/lib/widgets/wallpaper.vala'],
	dependencies: [gobject, gio, gtk, lua, hdy, dbusmenugtk, accountsservice, posix, libgenesis_shell_dep],
	vala_gir: 'GenesisWidgets-1.0.gir',
	install: true,
	install_dir: [true, true, true, true])
libgenesis_widgets_dep = declare_dependency(link_with: libgenesis_widgets, dependencies: [gobject, gio, gtk, lua, hdy, dbusmenugtk, accountsservice])

components = {
	'genesis-desktop': [[
		'src/components/desktop/desktop.vala', 'src/components/desktop/window.vala'
	], [libgenesis_component_dep, libgenesis_widgets_dep], true, 'com.expidus.GenesisDesktop'],

	'genesis-notifications': [[
		'src/components/notifications/daemon.vala', 'src/components/notifications/notification.vala',
		'src/components/notifications/notifications.vala'
	], [libgenesis_component_dep, libgenesis_widgets_dep, libgenesis_notifications_dep], true, 'com.expidus.GenesisNotifications'],

	'genesis-panel': [[
		'src/components/panel/panel.vala', 'src/components/panel/utils.vala',
		'src/components/panel/window.vala'
	], [libgenesis_component_dep, libgenesis_widgets_dep, meson.get_compiler('c').find_library('m')], true, 'com.expidus.GenesisPanel']
}

executable('genesis-shell', ['src/shell/shell.vala', 'src/shell/wm.vala'],
	dependencies: [mutter, libgenesis_shell_dep],
	install_rpath: mutter[0].get_pkgconfig_variable('libdir') / 'mutter-' + mutter[0].get_pkgconfig_variable('apiversion'),
	build_rpath: mutter[0].get_pkgconfig_variable('libdir') / 'mutter-' + mutter[0].get_pkgconfig_variable('apiversion'),
	install: true)

foreach name, c : components
	sources = c[0]
	deps = c[1]
	has_dbus = c[2]

	configure_file(input: 'data/components/' + name + '.ini.in', output: name + '.ini',
		configuration: conf_data,
		install: true,
		install_dir: join_paths(datadir, 'genesis', 'components'))

	executable(name, sources,
		dependencies: deps,
		install: true)
	
	if (has_dbus)
		configure_file(input: 'data/dbus/' + c[3] + '.service.in', output: c[3] + '.service',
			configuration: conf_data,
			install: true,
			install_dir: join_paths(datadir, 'dbus-1', 'services'))
	endif
endforeach

genesis_about_res = gnome.compile_resources('genesis-about-res', 'data/res/applications/about/res.gresource.xml',
	source_dir: 'data/res/applications/about',
	c_name: 'genesis_about')

executable('genesis-about', ['src/applications/about/application.vala', 'src/applications/about/window.vala', build_conf, genesis_about_res],
	dependencies: [hdy, gtk],
	install: true)

install_subdir('data/wallpaper',
	install_dir: join_paths(get_option('datadir'), 'backgrounds', 'expidus'),
	strip_directory: true)
install_subdir('data/ui',
	install_dir: join_paths(get_option('datadir'), 'genesis', 'ui'),
	strip_directory: true)
install_subdir('src/misd',
	install_dir: join_paths(get_option('datadir'), 'genesis', 'misd'),
	strip_directory: true)
install_subdir('data/schemas/settings',
	install_dir: gio[0].get_pkgconfig_variable('schemasdir'),
	strip_directory: true)