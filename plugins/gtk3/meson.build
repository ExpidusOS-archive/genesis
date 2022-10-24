conf_data_plugin_gtk3 = configuration_data()
conf_data_plugin_gtk3.merge_from(conf_data)

build_conf_plugin_gtk3 = configure_file(input: 'src/build.vala.in', output: 'build.vala',
  configuration: conf_data_plugin_gtk3)
configure_file(input: 'src/gtk3.plugin.in', output: 'genesis-shell-gtk3.plugin',
  configuration: conf_data_plugin_gtk3,
  install: true,
  install_dir: join_paths(libdir, 'genesis-shell', 'plugins'))

plugin_gtk3_rel_sources = ['src/plugin.vala', 'src/monitor.vala', 'src/provider/monitor.vala',
  'src/widgets/desktop.vala', 'src/widgets/panel.vala', 'src/windows/desktop.vala']
plugin_gtk3_sources = []

foreach src : plugin_gtk3_rel_sources
  plugin_gtk3_sources += [join_paths(meson.current_source_dir(), src)]
endforeach

if uncrustify.found()
  run_target('plugin-gtk3-prettier',
    command: [uncrustify, '--no-backup', plugin_gtk3_sources])
endif

plugin_gtk3_sources += [build_conf_plugin_gtk3]
plugin_gtk3_deps = [libgenesis_core, gtk3, libtokyo]

plugin_gtk3_lib = static_library('libgenesis-shell-gtk3', build_conf_plugin_gtk3, plugin_gtk3_rel_sources,
  c_args: ['-DG_LOG_DOMAIN="GenesisShellGtk3"', '-DGETTEXT_PACKAGE="genesis-shell"'],
  vala_args: ['--define=GETTEXT_PACKAGE="genesis-shell"'],
  vala_gir: 'GenesisShellGtk3-@0@.gir'.format(shortver.split('-')[0]),
  name_prefix: '',
  dependencies: plugin_gtk3_deps,
  install: true,
  install_dir: [false, join_paths(datadir, 'include', 'genesis-shell', 'plugins'),
    join_paths(datadir, 'genesis-shell', 'plugins', 'vapi'), join_paths(datadir, 'genesis-shell', 'plugins', 'gir-1.0')])

plugin_gtk3 = declare_dependency(link_whole: [plugin_gtk3_lib],
  dependencies: plugin_gtk3_deps,
  compile_args: ['-I' + join_paths(meson.project_build_root(), 'plugins', 'gtk3')])

plugins += [shared_module('genesis-shell-gtk3', 'src/main.vala',
  c_args: ['-DG_LOG_DOMAIN="GenesisShellGtk3"', '-DGETTEXT_PACKAGE="genesis-shell"'],
  vala_args: ['--define=GETTEXT_PACKAGE="genesis-shell"'],
  dependencies: [plugin_gtk3],
  name_suffix: 'so',
  install: true,
  install_dir: [join_paths(libdir, 'genesis-shell', 'plugins'), false, false])]

if get_option('tests')
  subdir('tests')
endif
