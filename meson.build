project('genesis-shell', 'vala', 'c', license: 'GPL-3.0-only', version: '0.1.0-prealpha')

vapi_dir = meson.current_source_dir() / 'vapi'
add_project_arguments(['--vapidir', vapi_dir], language: 'vala')
add_project_arguments(['--vapidir', vapi_dir / 'vala-extra-vapis'], language: 'vala')

prefix = get_option('prefix')
bindir = prefix / get_option('bindir')
datadir = prefix / get_option('datadir')

gobject = dependency('gobject-2.0')
gtk = dependency('gtk+-3.0')
lua = dependency('lua')

subdir('po')

conf_data = configuration_data()
conf_data.set('PREFIX', prefix)
conf_data.set('BINDIR', bindir)
conf_data.set('DATADIR', datadir)
conf_data.set('VERSION', meson.project_version())

build_conf_h = configure_file(input: 'src/build.h.in', output: 'build.h',
	configuration: conf_data)
build_conf = configure_file(input: 'src/build.vala.in', output: 'build.vala',
	configuration: conf_data)

components = [
	'genesis-desktop'
]

foreach name : components
	configure_file(input: 'data/components/' + name + '.ini.in', output: name + '.ini',
		configuration: conf_data,
		install: true,
		install_dir: join_paths(datadir, 'genesis', 'components'))
endforeach

shared_library('genesis-component', ['src/libcomponent/component.vala'],
	dependencies: [gobject, gtk],
	vala_gir: 'GenesisComponent-1.0.gir',
	install: true,
	install_dir: [true, true, true, true])

shared_library('genesis-shell', [build_conf, 'src/libshell/component.vala', 'src/libshell/error.vala', 'src/libshell/misd.vala', 'src/libshell/shell.vala'],
	dependencies: [gobject, gtk, lua],
	vala_gir: 'GenesisShell-1.0.gir',
	install: true,
	install_dir: [true, true, true, true])

install_subdir('data/wallpaper',
	install_dir: join_paths(get_option('datadir'), 'backgrounds', 'expidus'),
	strip_directory: true)