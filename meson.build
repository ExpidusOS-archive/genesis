project('genesis-shell', 'vala', 'c', license: 'GPL-3.0-only', version: '0.1.0-prealpha')

vapi_dir = meson.current_source_dir() / 'vapi'
add_project_arguments(['--vapidir', vapi_dir], language: 'vala')
add_project_arguments(['--vapidir', vapi_dir / 'vala-extra-vapis'], language: 'vala')

prefix = get_option('prefix')
datadir = prefix / get_option('datadir')

gobject = dependency('gobject-2.0')
gtk = dependency('gtk4')
lua = dependency('lua')
xcb = [dependency('xcb'), dependency('xcb-randr')]

subdir('po')

conf_data = configuration_data()
conf_data.set('PREFIX', prefix)
conf_data.set('DATADIR', datadir)
conf_data.set('VERSION', meson.project_version())

build_conf_h = configure_file(input: 'src/build.h.in', output: 'build.h',
	configuration: conf_data)
build_conf = configure_file(input: 'src/build.vala.in', output: 'build.vala',
	configuration: conf_data)

executable('genesis-shell', [build_conf, 'src/shell/x11/backend.vala', 'src/shell/x11/monitor.vala',
    'src/shell/backend.vala', 'src/shell/shell.vala'],
    dependencies: [gobject, gtk, lua, xcb],
    install: true)