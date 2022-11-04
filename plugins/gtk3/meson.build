conf_data_plugin_gtk3 = configuration_data()
conf_data_plugin_gtk3.merge_from(conf_data)

plugin_gtk3_args = []

if libnm.found()
  plugin_gtk3_args += ['--define=HAS_LIBNM']
  conf_data_plugin_gtk3.set('HAS_LIBNM', 'true')
endif

if upower.found()
  plugin_gtk3_args += ['--define=HAS_UPOWER']
  conf_data_plugin_gtk3.set('HAS_UPOWER', 'true')
endif

if libgvc.found()
  plugin_gtk3_args += ['--define=HAS_LIBGVC']
  conf_data_plugin_gtk3.set('HAS_LIBGVC', 'true')
endif

if libcall_ui.found()
  plugin_gtk3_args += ['--define=HAS_LIBCALL_UI']
  conf_data_plugin_gtk3.set('HAS_LIBCALL_UI', 'true')
endif

if ibus.found()
  plugin_gtk3_args += ['--define=HAS_IBUS']
  conf_data_plugin_gtk3.set('HAS_IBUS', 'true')
endif

if gio_unix.found()
  plugin_gtk3_args += ['--define=HAS_GIO_UNIX']
  conf_data_plugin_gtk3.set('HAS_GIO_UNIX', 'true')
endif

if libecal.found()
  plugin_gtk3_args += ['--define=HAS_LIBECAL']
  conf_data_plugin_gtk3.set('HAS_LIBECAL', 'true')
endif

build_conf_plugin_gtk3 = configure_file(input: 'src/build.vala.in', output: 'build.vala',
  configuration: conf_data_plugin_gtk3)
configure_file(input: 'src/gtk3.plugin.in', output: 'genesis-shell-gtk3.plugin',
  configuration: conf_data_plugin_gtk3,
  install: true,
  install_dir: join_paths(libdir, 'genesis-shell', 'plugins'))

plugin_gtk3_rel_sources = ['src/plugin.vala', 'src/monitor.vala',
  'src/provider/monitor.vala', 'src/provider/ui.vala',
  'src/widgets/button.vala', 'src/widgets/dash.vala',
  'src/widgets/desktop.vala', 'src/widgets/icon.vala',
  'src/widgets/lock.vala', 'src/widgets/panel.vala',
  'src/windows/dash.vala', 'src/windows/desktop.vala',
  'src/windows/lock.vala', 'src/windows/panel.vala',
  'src/panel-applets/apps.vala', 'src/panel-applets/clock.vala']
plugin_gtk3_sources = []

if libnm.found()
  plugin_gtk3_rel_sources += ['src/panel-applets/networks.vala',
    'src/indicators/wifi.vala']
endif

if upower.found()
  plugin_gtk3_rel_sources += ['src/panel-applets/power.vala']
endif

if libgvc.found()
  plugin_gtk3_rel_sources += ['src/panel-applets/sound.vala']
endif

if ibus.found()
  plugin_gtk3_rel_sources += ['src/panel-applets/keyboard.vala']
endif

foreach src : plugin_gtk3_rel_sources
  plugin_gtk3_sources += [join_paths(meson.current_source_dir(), src)]
endforeach

if uncrustify.found()
  run_target('plugin-gtk3-prettier',
    command: [uncrustify, '--no-backup', plugin_gtk3_sources])
endif

plugin_gtk3_sources += [build_conf_plugin_gtk3]
plugin_gtk3_deps = [libgenesis_core, gtk3, libtokyo]
plugin_gtk3_inc = []

if libnm.found()
  plugin_gtk3_deps += [libnm]
endif

if upower.found()
  plugin_gtk3_deps += [upower]
endif

if libgvc.found()
  plugin_gtk3_deps += [libgvc, libgvc_vapi]
  plugin_gtk3_inc += [libgvc_inc]
endif

if libcall_ui.found()
  plugin_gtk3_deps += [libcall_ui, libcall_ui_vapi]
  plugin_gtk3_inc += [libcall_ui_inc]
endif

if ibus.found()
  plugin_gtk3_deps += [ibus]
endif

if gio_unix.found()
  plugin_gtk3_deps += [gio_unix]
endif

if libecal.found()
  plugin_gtk3_deps += [libecal]
endif

plugin_gtk3_lib = static_library('libgenesis-shell-gtk3', build_conf_plugin_gtk3, plugin_gtk3_rel_sources,
  c_args: ['-DG_LOG_DOMAIN="GenesisShellGtk3"', '-DGETTEXT_PACKAGE="genesis-shell"', '-DLIBICAL_GLIB_UNSTABLE_API=1'],
  vala_args: ['--define=GETTEXT_PACKAGE="genesis-shell"', plugin_gtk3_args],
  vala_gir: 'GenesisShellGtk3-@0@.gir'.format(shortver.split('-')[0]),
  name_prefix: '',
  dependencies: plugin_gtk3_deps,
  include_directories: plugin_gtk3_inc,
  install: true,
  install_dir: [false, join_paths(datadir, 'include', 'genesis-shell', 'plugins'),
    join_paths(datadir, 'genesis-shell', 'plugins', 'vapi'), join_paths(datadir, 'genesis-shell', 'plugins', 'gir-1.0')])

plugin_gtk3 = declare_dependency(link_whole: [plugin_gtk3_lib],
  dependencies: plugin_gtk3_deps,
  compile_args: ['-I' + join_paths(meson.project_build_root(), 'plugins', 'gtk3')])

plugins += [shared_module('genesis-shell-gtk3', 'src/main.vala',
  c_args: ['-DG_LOG_DOMAIN="GenesisShellGtk3"', '-DGETTEXT_PACKAGE="genesis-shell"', '-DLIBICAL_GLIB_UNSTABLE_API=1'],
  vala_args: ['--define=GETTEXT_PACKAGE="genesis-shell"'],
  dependencies: [plugin_gtk3],
  name_suffix: 'so',
  install: true,
  install_rpath: join_paths(libdir, 'genesis-shell', 'libs'),
  install_dir: [join_paths(libdir, 'genesis-shell', 'plugins'), false, false])]

if get_option('tests')
  subdir('tests')
endif
