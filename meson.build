project('genesis-shell', 'vala', 'c', license: 'GPL-3.0-only', version: '0.2.0-alpha')

gnome = import('gnome')
i18n = import('i18n')
pkg = import('pkgconfig')
fs = import('fs')

prefix = get_option('prefix')
bindir = prefix / get_option('bindir')
datadir = prefix / get_option('datadir')
libdir = prefix / get_option('libdir')
libexecdir = prefix / get_option('libexecdir')

longver = '@0@'.format(meson.project_version())
shortver = longver
git = find_program('git', native: true, required: false)
conf_data = configuration_data()
i18n_args = ['--package-version=@0@'.format(longver), '--copyright-holder=Midstall Software']

add_project_arguments([
  '--hide-internal',
  '--vapidir', join_paths(meson.project_source_root(), 'vapi'),
  '--vapidir', meson.project_build_root()
], language: 'vala')

if git.found()
  git_commit = run_command([git, 'rev-parse', '--short', 'HEAD'])
  git_branch = run_command([git, 'rev-parse', '--abbrev-ref', 'HEAD'])
  git_config_username = run_command([git, 'config', '--get', 'user.name'])

  if git_commit.returncode() == 0 and git_branch.returncode() == 0
    shortver = '@0@-@1@'.format(meson.project_version(), git_commit.stdout().strip())
    longver = '@0@ (branch \'@1@\')'.format(shortver, git_branch.stdout().strip())
  endif

  if git_config_username.returncode() == 0
    git_username = git_config_username.stdout().strip()
    conf_data.set('BUILD_USER', git_username)
  endif
endif

sdk = dependency('expidus-sdk', native: false, required: false, include_type: 'system', method: 'pkg-config')
if sdk.found()
  uncrustify = find_program('uncrustify', sdk.get_variable('bindir'))
else
  uncrustify = disabler()
endif

enable_wayland = get_option('wayland').disable_auto_if(target_machine.system() != 'linux')
enable_x11 = get_option('x11').disable_auto_if(target_machine.system() != 'linux')

valadoc = find_program('valadoc', required: get_option('docs'), native: true)

libmath = meson.get_compiler('c').find_library('m', required: false)
libdevident = dependency('devident', fallback: ['libdevident', 'libdevident_core'], required: true)

if dependency('libpulse', required: false).found()
  gvc = subproject('gvc', default_options: [
    'package_name=' + meson.project_name(),
    'package_version=' + meson.project_version(),
    'pkgdatadir=' + join_paths(datadir, 'genesis-shell', 'libs'),
    'pkglibdir=' + join_paths(libdir, 'genesis-shell', 'libs'),
    'alsa=false',
    'static=false',
    'introspection=true'
  ])

  libgvc = gvc.get_variable('libgvc_dep')
  libgvc_vapi = gnome.generate_vapi('gvc',
    metadata_dirs: [join_paths(meson.project_source_root(), 'vapi')],
    packages: ['gio-2.0'],
    sources: [gvc.get_variable('libgvc_gir')[0]],
    install: true,
    install_dir: join_paths(datadir, 'genesis-shell', 'libs'))
  libgvc_inc = include_directories(join_paths('subprojects', 'gvc'))
else
  libgvc = disabler()
endif

ibus = dependency('ibus-1.0', required: false)
libnm = dependency('libnm', required: false)
upower = dependency('upower-glib', required: false)
gio_unix = dependency('gio-unix-2.0', required: false)

libtokyo = dependency('tokyo', fallback: ['libtokyo', 'libtokyo_core_dep'], required: false)
libtokyo_gtk3 = dependency('tokyo-gtk3', fallback: ['libtokyo', 'libtokyo_gtk3_dep'], disabler: not libtokyo.found(), required: false)
libtokyo_gtk4 = dependency('tokyo-gtk4', fallback: ['libtokyo', 'libtokyo_gtk4_dep'], disabler: not libtokyo.found(), required: false)

gtk3_wayland = dependency('gtk+-wayland-3.0', disabler: not libtokyo_gtk3.found(), required: enable_wayland)
gtk3_x11 = dependency('gtk+-x11-3.0', disabler: not libtokyo_gtk3.found(), required: enable_x11)
gtk_layer_shell = dependency('gtk-layer-shell-0', disabler: not gtk3_wayland.found(), required: false)

if gtk3_wayland.found()
  add_project_arguments(['--define=HAS_GTK3_WAYLAND'], language: 'vala')
endif

if gtk3_x11.found()
  add_project_arguments(['--define=HAS_GTK3_X11'], language: 'vala')
endif

if gtk_layer_shell.found()
  add_project_arguments(['--define=HAS_GTK_LAYER_SHELL'], language: 'vala')
endif

gtk4_wayland = dependency('gtk4-wayland', disabler: not libtokyo_gtk4.found(), required: enable_wayland)
gtk4_x11 = dependency('gtk4-x11', disabler: not libtokyo_gtk4.found(), required: enable_x11)

if gtk4_wayland.found()
  add_project_arguments(['--define=HAS_GTK4_WAYLAND'], language: 'vala')
endif

if gtk4_x11.found()
  add_project_arguments(['--define=HAS_GTK4_X11'], language: 'vala')
endif

vadi = dependency('vadi-0.0', required: true)
gio = dependency('gio-2.0', required: true)
libpeas = dependency('libpeas-1.0', required: true)

dbus = dependency('dbus-1', required: get_option('dbus').disable_auto_if(target_machine.system() != 'linux'))

libintl = meson.get_compiler('c').find_library('intl', required: false)

gtk3 = [dependency('gtk+-3.0', disabler: not libtokyo_gtk3.found(), required: libtokyo_gtk3.found()),
  libtokyo_gtk3]

if gtk3_x11.found()
  gtk3 += [gtk3_x11, dependency('x11', required: true)]
endif

if gtk3_wayland.found()
  gtk3 += [gtk3_wayland]
endif

if gtk_layer_shell.found()
  gtk3 += [gtk_layer_shell]
endif

gtk4 = [dependency('gtk4', disabler: not libtokyo_gtk4.found(), required: libtokyo_gtk4.found()),
  libtokyo_gtk4]

if gtk4_x11.found()
  gtk4 += [gtk4_x11]
endif

if gtk4_wayland.found()
  gtk4 += [gtk4_wayland]
endif

conf_data.set('PREFIX', prefix)
conf_data.set('BINDIR', bindir)
conf_data.set('DATADIR', datadir)
conf_data.set('LIBDIR', libdir)
conf_data.set('LIBEXECDIR', libexecdir)
conf_data.set('VERSION', longver)
conf_data.set('LOCALDIR', join_paths(datadir, 'locale'))
conf_data.set('BUILDDIR', meson.current_build_dir())
conf_data.set('SOURCEDIR', meson.current_source_dir())

plugins = []

subdir('data')
subdir('po')
subdir('core')
subdir('shell')
subdir('plugins')

gnome.post_install(glib_compile_schemas: true)

plugin_names = []
foreach tgt : plugins
  plugin_names += [fs.name(tgt.full_path()).replace('lib', '').replace('.so', '')]
endforeach

summary({
  'Plugins': ', '.join(plugin_names)
})
