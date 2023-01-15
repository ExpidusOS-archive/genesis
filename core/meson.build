conf_data_core = configuration_data()
conf_data_core.merge_from(conf_data)

libgenesis_core_vala_args = []
libgenesis_core_inc = []

if dbus.found()
  conf_data_core.set('HAS_DBUS', 'true')
  libgenesis_core_vala_args += ['--define=HAS_DBUS']
else
  conf_data_core.set('HAS_DBUS', 'false')
endif

if libgvc.found()
  conf_data_core.set('HAS_LIBGVC', 'true')
  libgenesis_core_vala_args += ['--define=HAS_LIBGVC']
endif

if libcallaudio.found()
  conf_data_core.set('HAS_LIBCALLAUDIO', 'true')
  libgenesis_core_vala_args += ['--define=HAS_LIBCALLAUDIO']
endif

build_conf_core = configure_file(input: 'lib/build.vala.in', output: 'build.vala',
  configuration: conf_data_core)

libgenesis_core_docs_args = ['--package-name=libgenesis', '--package-version=@0@'.format(shortver)]
libgenesis_core_rel_sources = ['lib/context.vala', 'lib/math.vala', 'lib/monitor.vala',
  'lib/plugin.vala', 'lib/ui.vala', 'lib/window-manager.vala', 'lib/window.vala', 'lib/workspace.vala',
  'lib/provider/monitor.vala', 'lib/provider/ui.vala', 'lib/provider/window.vala', 'lib/provider/workspace.vala']
libgenesis_core_sources = []

if dbus.found()
  libgenesis_core_rel_sources += ['lib/dbus/context.vala', 'lib/dbus/monitor.vala',
    'lib/dbus/window.vala', 'lib/dbus/workspace.vala']
endif

foreach src : libgenesis_core_rel_sources
  libgenesis_core_sources += [join_paths(meson.current_source_dir(), src)]
endforeach

if uncrustify.found()
  run_target('core-prettier',
    command: [uncrustify, '--no-backup', libgenesis_core_sources])
endif

libgenesis_core_sources += [build_conf_core]

libgenesis_core_deps = [gio, vadi, libpeas, libdevident, libintl, libmath]

if libgvc.found()
  libgenesis_core_deps += [libgvc, libgvc_vapi]
  libgenesis_core_inc += [libgvc_inc]
  libgenesis_core_docs_args += ['--pkg=gvc']
endif

if libcallaudio.found()
  libgenesis_core_deps += [libcallaudio]
  libgenesis_core_docs_args += ['--pkg=libcallaudio-0.1']
endif

libgenesis_core_shlib = shared_library('genesis', build_conf_core, libgenesis_core_rel_sources,
  c_args: ['-DG_LOG_DOMAIN="GenesisShell"', '-DGETTEXT_PACKAGE="genesis-shell"'],
  vala_args: ['--define=GETTEXT_PACKAGE="genesis-shell"', '--define=TARGET_SYSTEM_@0@'.format(target_machine.system().to_upper()), libgenesis_core_vala_args],
  vala_gir: 'Tokyo-@0@.gir'.format(shortver.split('-')[0]),
  dependencies: libgenesis_core_deps,
  include_directories: libgenesis_core_inc,
  version: shortver.split('-')[0],
  install: true,
  install_rpath: join_paths(libdir, 'genesis-shell', 'libs'),
  install_dir: [true, true, true, true])
libgenesis_core = declare_dependency(link_with: libgenesis_core_shlib, dependencies: libgenesis_core_deps,
  compile_args: ['-I' + join_paths(meson.project_build_root(), 'core')])
pkg.generate(libgenesis_core_shlib,
  name: 'genesis-shell',
  requires: ['gio-2.0', 'vadi-0.0'],
  description: 'The core of the Genesis Shell',
  url: 'https://github.com/ExpidusOS/genesis',
  version: longver)

subdir('docs', if_found: [valadoc])
subdir('data')
