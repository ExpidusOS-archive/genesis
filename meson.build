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
gtk = [dependency('gtk4')]
lua = dependency('lua')
gio = [dependency('gio-2.0'), dependency('gio-unix-2.0')]
gsettings_ddesktop_schemas = dependency('gsettings-desktop-schemas')
mutter = [dependency('libmutter-8'), dependency('mutter-cogl-8'), dependency('mutter-clutter-8'), gsettings_ddesktop_schemas]
devident = dependency('devident-1.0')
adwaita = dependency('libadwaita-1')
lightdm_gobject = dependency('liblightdm-gobject-1')
posix = meson.get_compiler('vala').find_library('posix')

version = '"@0@"'.format(meson.project_version())
git = find_program('git', native: true, required: false)
if git.found()
	git_commit = run_command([git, 'rev-parse', '--short', 'HEAD'])
	git_branch = run_command([git, 'rev-parse', '--abbrev-ref', 'HEAD'])
	if git_commit.returncode() == 0 and git_branch.returncode() == 0
		version = '"@0@-@1@ (branch \'@2@\')"'.format(meson.project_version(), git_commit.stdout().strip(), git_branch.stdout().strip())
	endif
endif

conf_data = configuration_data()
conf_data.set('PREFIX', prefix)
conf_data.set('BINDIR', bindir)
conf_data.set('DATADIR', datadir)
conf_data.set('VERSION', version)
conf_data.set('BUILD_X11', x11)
conf_data.set('BUILD_WAYLAND', wayland)

if x11
	gtk += [dependency('x11')]
	add_project_arguments('-D', 'BUILD_X11', language: 'vala')

	configure_file(input: 'data/xsessions/genesis.desktop.in', output: 'genesis-x11.desktop',
		configuration: conf_data,
		install: true,
		install_dir: join_paths(datadir, 'xsessions'))
endif

libgenesis_display_deps = []
if wayland
	gtk += [dependency('gtk-layer-shell-0')]
	add_project_arguments('-D', 'BUILD_WAYLAND', language: 'vala')
	configure_file(input: 'data/wayland-sessions/genesis.desktop.in', output: 'genesis-wl.desktop',
		configuration: conf_data,
		install: true,
		install_dir: join_paths(datadir, 'wayland-sessions'))

	wayland_protocols = [
		['xdg-output', 'unstable', 'v1', ],
	]

	wayland_scanner = find_program('wayland-scanner')
	wayland_protocols_dep = dependency('wayland-protocols')
	wayland_protocol_server_headers = []
	wayland_protocol_client_headers = []
	wayland_protocol_private_sources = []
	wayland_protocol_public_sources = []
	protocols_dir = wayland_protocols_dep.get_pkgconfig_variable('pkgdatadir')

	foreach p : wayland_protocols
		protocol_name = p.get(0)
		protocol_type = p.get(1)

		if protocol_type == 'stable'
			output_base = protocol_name
      input = join_paths(protocols_dir, '@0@/@1@/@2@.xml'.format(protocol_type, protocol_name, output_base))
		elif protocol_type == 'staging'
			protocol_version = p.get(2)
      output_base = '@0@-@1@'.format(protocol_name, protocol_version)
      input = join_paths(protocols_dir, '@0@/@1@/@2@.xml'.format(protocol_type, protocol_name, output_base))
		else
			protocol_version = p.get(2)
      output_base = '@0@-@1@-@2@'.format(protocol_name, protocol_type, protocol_version)
      input = join_paths(protocols_dir, '@0@/@1@/@2@.xml'.format(protocol_type, protocol_name, output_base))
		endif

		wayland_protocol_server_headers += custom_target('@0@ server header'.format(output_base),
			input: input,
			output: '@0@-server-protocol.h'.format(output_base),
			command: [wayland_scanner, 'server-header', '@INPUT@', '@OUTPUT@'])

    wayland_protocol_client_headers += custom_target('@0@ client header'.format(output_base),
			input: input,
			output: '@0@-client-protocol.h'.format(output_base),
			command: [wayland_scanner, 'client-header', '@INPUT@', '@OUTPUT@'])

		wayland_protocol_private_sources += custom_target('@0@ private source'.format(output_base),
			input: input,
			output: '@0@-private-protocol.c'.format(output_base),
			command: [wayland_scanner, 'private-code', '@INPUT@', '@OUTPUT@'])

		wayland_protocol_public_sources += custom_target('@0@ public source'.format(output_base),
			input: input,
			output: '@0@-public-protocol.c'.format(output_base),
			command: [wayland_scanner, 'public-code', '@INPUT@', '@OUTPUT@'])
	endforeach

	libgenesis_display_deps += meson.get_compiler('c').find_library('wayland-client')
endif

configure_file(input: 'data/genesis-greeter.desktop.in', output: 'genesis-greeter.desktop',
	configuration: conf_data,
	install: true,
	install_dir: join_paths(datadir, 'xgreeters'))

subdir('po')

build_conf_h = configure_file(input: 'src/build.h.in', output: 'build.h',
	configuration: conf_data)
build_conf = configure_file(input: 'src/build.vala.in', output: 'build.vala',
	configuration: conf_data)

libgenesis_display_src = []
if x11
	libgenesis_display_src += ['src/lib/display/x11/display.vala', 'src/lib/display/x11/monitor.vala', 'src/lib/display/x11/window.vala']
endif
if wayland
	libgenesis_display_src += ['src/lib/display/wayland/display.c', 'src/lib/display/wayland/display.vala', 'src/lib/display/wayland/monitor.c', 'src/lib/display/wayland/monitor.vala']
	libgenesis_display_src += wayland_protocol_public_sources
	libgenesis_display_src += wayland_protocol_client_headers
endif
libgenesis_display = shared_library('genesis-display-base', ['src/lib/display/display.vala', 'src/lib/display/monitor.vala', 'src/lib/display/window.vala', libgenesis_display_src],
	dependencies: [gobject, gtk, meson.get_compiler('c').find_library('m'), libgenesis_display_deps],
	vala_gir: 'GenesisDisplay-1.0.gir',
	install: true,
	install_dir: [true, true, true, true])
libgenesis_display_dep = declare_dependency(link_with: libgenesis_display, dependencies: [gobject, gtk])

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

libgenesis_widgets_res = gnome.compile_resources('libgenesis-widgets-res', 'data/res/lib/widgets/res.gresource.xml',
	source_dir: 'data/res/lib/widgets',
	c_name: 'genesis_widgets')
libgenesis_widgets = shared_library('genesis-widgets', ['src/lib/widgets/models/global-menu.vala', 'src/lib/widgets/models/launcher-apps.vala',
		'src/lib/widgets/models/settings-apps.vala', 'src/lib/widgets/models/user-menu.vala', 'src/lib/widgets/bin.vala', 'src/lib/widgets/app-button.vala',
		'src/lib/widgets/app-grid.vala', 'src/lib/widgets/clock.vala', 'src/lib/widgets/global-menu-bar.vala', 'src/lib/widgets/misc.vala',
		'src/lib/widgets/panel.vala', 'src/lib/widgets/user-bin.vala', 'src/lib/widgets/user-button.vala', 'src/lib/widgets/user-icon.vala',
		'src/lib/widgets/wallpaper.vala', 'src/lib/widgets/widget.vala', 'src/lib/widgets/window.vala', libgenesis_widgets_res],
	dependencies: [gobject, gio, gtk, lua, adwaita, accountsservice, posix, libgenesis_shell_dep, libgenesis_display_dep],
	vala_gir: 'GenesisWidgets-1.0.gir',
	install: true,
	install_dir: [true, true, true, true])
libgenesis_widgets_dep = declare_dependency(link_with: libgenesis_widgets, dependencies: [gobject, gio, gtk, lua, adwaita, accountsservice, libgenesis_display_dep])

components = {
	'genesis-desktop': [[
		'src/components/desktop/desktop.vala', 'src/components/desktop/window.vala'
	], [libgenesis_component_dep, libgenesis_widgets_dep], true, 'com.expidus.GenesisDesktop'],

	'genesis-panel': [[
		'src/components/panel/panel.vala'
	], [libgenesis_component_dep, libgenesis_widgets_dep], true, 'com.expidus.GenesisPanel']
}

executable('genesis-shell', ['src/shell/shell.vala', 'src/shell/wm.vala'],
	dependencies: [mutter, libgenesis_shell_dep],
	install_rpath: mutter[0].get_pkgconfig_variable('libdir') / 'mutter-' + mutter[0].get_pkgconfig_variable('apiversion'),
	build_rpath: mutter[0].get_pkgconfig_variable('libdir') / 'mutter-' + mutter[0].get_pkgconfig_variable('apiversion'),
	install: true)

executable('genesis-greeter', ['src/greeter/greeter.vala'],
	dependencies: [libgenesis_shell_dep, lightdm_gobject, gtk],
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
	dependencies: [adwaita, gtk],
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