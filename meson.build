project('genesis-shell', 'vala', 'c', 'cpp', license: 'GPL-3.0-only', version: '0.1.0-prealpha', default_options: [
	'cpp_std=c++17',
	'c_std=c11',
	'warning_level=2',
	'werror=false'
])

vapi_dir = meson.current_source_dir() / 'vapi'
add_project_arguments(['--vapidir', vapi_dir], language: 'vala')
add_project_arguments(['--vapidir', vapi_dir / 'vala-extra-vapis'], language: 'vala')
add_project_arguments(['--vapidir', '/usr/share/vala/vapi'], language: 'vala')
add_project_arguments(['-DWLR_USE_UNSTABLE', '-DWAYFIRE_PLUGIN'], language: ['cpp', 'c'])

gnome = import('gnome')

prefix = get_option('prefix')
bindir = prefix / get_option('bindir')
datadir = prefix / get_option('datadir')
libdir = prefix / get_option('libdir')
libexecdir = prefix / get_option('libexecdir')

adwaita = dependency('libadwaita-1')
accountsservice = dependency('accountsservice')
gobject = dependency('gobject-2.0')
gtk = [dependency('gtk+-3.0'), dependency('gtk-layer-shell-0')]
gtk4 = dependency('gtk4')
dazzel = dependency('libdazzle-1.0')
gio = [dependency('gio-2.0'), dependency('gio-unix-2.0')]
libpeas = dependency('libpeas-1.0')
libpulse = [dependency('libpulse'), dependency('libpulse-mainloop-glib')]
devident_client = dependency('devident-client-1.0')
networkmanager = dependency('libnm')
modemmanager = dependency('libmm-glib')
polkit = [dependency('polkit-agent-1'), dependency('polkit-gobject-1')]
libhandy = dependency('libhandy-1')
wayfire = dependency('wayfire')
wlroots = dependency('wlroots')
giomm = dependency('giomm-2.4')
posix = [meson.get_compiler('vala').find_library('posix'), meson.get_compiler('vala').find_library('linux')]
math = meson.get_compiler('c').find_library('m')
wayland_client = meson.get_compiler('c').find_library('wayland-client')

add_project_arguments('-DPOLKIT_AGENT_I_KNOW_API_IS_SUBJECT_TO_CHANGE', language: 'c')

version = '"@0@"'.format(meson.project_version())
git = find_program('git', native: true, required: false)
if git.found()
	git_commit = run_command([git, 'rev-parse', '--short', 'HEAD'])
	git_branch = run_command([git, 'rev-parse', '--abbrev-ref', 'HEAD'])
	if git_commit.returncode() == 0 and git_branch.returncode() == 0
		version = '"@0@-@1@ (branch \'@2@\')"'.format(meson.project_version(), git_commit.stdout().strip(), git_branch.stdout().strip())
	endif
endif

wayland_protocols = [
	['wlr-layer-shell-unstable-v1', 'private'],
	['xdg-shell', 'stable']
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
	elif protocol_type == 'private'
		output_base = protocol_name
		input = 'protocols/@0@.xml'.format(protocol_name)
	else
		protocol_version = p.get(2)
		output_base = '@0@-@1@-@2@'.format(protocol_name, protocol_type, protocol_version)
		input = join_paths(protocols_dir, '@0@/@1@/@2@.xml'.format(protocol_type, protocol_name, output_base))
	endif

	client_header = custom_target('@0@ client header'.format(output_base),
		input: input,
		output: '@0@-client-protocol.h'.format(output_base),
		command: [wayland_scanner, 'client-header', '@INPUT@', '@OUTPUT@'])
	
	wayland_protocol_public_sources += custom_target('@0@ public source'.format(output_base),
		depends: client_header,
		input: input,
		output: '@0@-public-protocol.c'.format(output_base),
		command: [wayland_scanner, 'public-code', '@INPUT@', '@OUTPUT@'])

	wayland_protocol_client_headers += client_header
endforeach

conf_data = configuration_data()
conf_data.set('PREFIX', prefix)
conf_data.set('BINDIR', bindir)
conf_data.set('DATADIR', datadir)
conf_data.set('LIBDIR', libdir)
conf_data.set('LIBEXECDIR', libexecdir)
conf_data.set('VERSION', version)

configure_file(input: 'data/wayland-sessions/genesis.desktop.in', output: 'genesis.desktop',
	configuration: conf_data,
	install: true,
	install_dir: join_paths(datadir, 'wayland-sessions'))

configure_file(input: 'data/org.freedesktop.impl.portal.desktop.genesis.service.in', output: 'org.freedesktop.impl.portal.desktop.genesis.service',
	configuration: conf_data,
	install: true,
	install_dir: join_paths(datadir, 'dbus-1', 'services'))

subdir('po')

build_conf_h = configure_file(input: 'src/build.h.in', output: 'build.h',
	configuration: conf_data)
build_conf = configure_file(input: 'src/build.vala.in', output: 'build.vala',
	configuration: conf_data)

libgenesis_common_files = files('src/lib/common/layout.vala', 'src/lib/common/module.vala', 'src/lib/common/monitor.vala', 'src/lib/common/shell.vala', 'src/lib/common/window.vala')
libgenesis_common = shared_library('genesis-common', libgenesis_common_files, build_conf,
	dependencies: [gobject, gio, gtk, libpeas, polkit, devident_client, math],
	vala_gir: 'GenesisCommon-1.0.gir',
	install: true,
	install_dir: [true, true, true, true])
libgenesis_common_dep = declare_dependency(link_with: libgenesis_common, dependencies: [gobject, gio, gtk, libpeas, polkit, devident_client])

libgenesis_component_files = files('src/lib/component/module.vala', 'src/lib/component/monitor.vala', 'src/lib/component/shell.vala', 'src/lib/component/window.vala')
libgenesis_component = shared_library('genesis-component', libgenesis_component_files,
	dependencies: [gobject, gtk, libgenesis_common_dep],
	vala_gir: 'GenesisComponent-1.0.gir',
	install: true,
	install_dir: [true, true, true, true])
libgenesis_component_dep = declare_dependency(link_with: libgenesis_component, dependencies: [gobject, gtk, libgenesis_common_dep])

libgenesis_shell_files = files('src/lib/shell/layout.vala', 'src/lib/shell/module.vala',
	'src/lib/shell/monitor.vala', 'src/lib/shell/shell.vala', 'src/lib/shell/window.vala')
libgenesis_shell = shared_library('genesis-shell', libgenesis_shell_files,
	dependencies: [gobject, gtk, libgenesis_common_dep],
	vala_gir: 'GenesisShell-1.0.gir',
	install: true,
	install_dir: [true, true, true, true])
libgenesis_shell_dep = declare_dependency(link_with: libgenesis_shell, dependencies: [gobject, gtk, libgenesis_common_dep])

libgenesis_widgets_files = files('src/lib/widgets/application.vala', 'src/lib/widgets/clock.vala', 'src/lib/widgets/global-menu.vala',
		'src/lib/widgets/init.vala', 'src/lib/widgets/net.vala', 'src/lib/widgets/volume.vala', 'src/lib/widgets/wallpaper.vala',
		'src/lib/widgets/widget.vala', 'src/lib/widgets/window.vala')
libgenesis_widgets = shared_library('genesis-widgets', libgenesis_widgets_files,
	dependencies: [gobject, gtk, libhandy, libgenesis_common_dep, libgenesis_component_dep, libgenesis_shell_dep, libpulse, networkmanager, modemmanager],
	vala_gir: 'GenesisWidgets-1.0.gir',
	install: true,
	install_dir: [true, true, true, true])
libgenesis_widgets_dep = declare_dependency(link_with: libgenesis_widgets, dependencies: [gobject, gtk, libhandy, libgenesis_common_dep, libpulse, networkmanager, modemmanager])

shared_module('genesis-shell-wayfire', ['src/plugins/genesis-shell/decoration.cpp', 'src/plugins/genesis-shell/genesis-shell.cpp',
		'src/plugins/genesis-shell/monitor.cpp', 'src/plugins/genesis-shell/window.cpp'],
	dependencies: [giomm, gobject, libgenesis_shell_dep, wayfire, wlroots],
	install: true,
	install_dir: join_paths(libdir, 'wayfire'))

executable('xdg-desktop-portal-genesis', ['src/portal/main.vala', 'src/portal/settings.vala'],
	dependencies: [gio, gobject],
	install: true,
	install_dir: libexecdir)
install_data('data/genesis.portal', install_dir: join_paths(datadir, 'xdg-desktop-portal', 'portals'))

executable('genesis-shell', ['src/shell/desktop.vala', 'src/shell/panel.vala', 'src/shell/polkit.vala', 'src/shell/shell.vala'],
	dependencies: [gio, gobject, polkit, libgenesis_component_dep, posix, dazzel, libgenesis_widgets_dep],
	install: true)

expidus_desktop_res = gnome.compile_resources('expidus-desktop-res', 'data/res/modules/expidus-desktop/res.gresource.xml',
	source_dir: 'data/res/modules/expidus-desktop',
	export: true,
	c_name: 'expidus_desktop')

modules = {
	'expidus-desktop': [['src/modules/expidus-desktop/apps.vala', 'src/modules/expidus-desktop/layout.vala',
		'src/modules/expidus-desktop/module.vala', 'src/modules/expidus-desktop/ui.vala', expidus_desktop_res], [libgenesis_shell_dep, libgenesis_component_dep, libgenesis_widgets_dep]],
	'expidus-mobile': [['src/modules/expidus-mobile/layout.vala', 'src/modules/expidus-mobile/module.vala'], [libgenesis_shell_dep,
		libgenesis_component_dep, libgenesis_widgets_dep, dazzel]]
}

foreach name, c : modules
	sources = c[0]
	deps = c[1]

	configure_file(input: 'data/modules/' + name + '.plugin.in', output: name + '.plugin',
		configuration: conf_data,
		install: true,
		install_dir: join_paths(libdir, 'genesis', 'modules', name))

	shared_module(name, sources,
		dependencies: deps,
		install: true,
		install_dir: join_paths(libdir, 'genesis', 'modules', name))
endforeach

genesis_about_res = gnome.compile_resources('genesis-about-res', 'data/res/applications/about/res.gresource.xml',
	source_dir: 'data/res/applications/about',
	c_name: 'genesis_about')

executable('genesis-about', ['src/applications/about/application.vala', 'src/applications/about/window.vala', build_conf, genesis_about_res],
	dependencies: [adwaita, gtk4],
	install: true)

install_subdir('data/wallpaper',
	install_dir: join_paths(datadir, 'backgrounds', 'expidus'),
	strip_directory: true)
install_subdir('data/schemas/settings',
	install_dir: gio[0].get_pkgconfig_variable('schemasdir'),
	strip_directory: true)

install_data('data/genesis-shell.xml', install_dir: join_paths(datadir, 'wayfire', 'metadata'))

subdir('docs')