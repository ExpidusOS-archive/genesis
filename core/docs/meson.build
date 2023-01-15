libgenesis_core_docs_devhelp = custom_target('core-docs-devhelp',
  input: libgenesis_core_sources,
  output: 'devhelp',
  depends: libgenesis_core_shlib,
  command: [valadoc, '-o', join_paths(meson.current_build_dir(), 'devhelp'),
    '--doclet', 'devhelp', '@INPUT@', '--force',
    '--pkg', 'vadi-0.0', '--pkg', 'gio-2.0', '--pkg', 'libpeas-1.0',
    '--pkg', 'devident', '--pkg', 'gmodule-2.0',
    '--vapidir', meson.project_build_root(),
    '--vapidir', join_paths(meson.project_source_root(), 'vapi'),
    '--vapidir', join_paths(meson.project_build_root(), 'subprojects', 'libdevident', 'core'),
    '--vapidir', join_paths(meson.project_build_root(), 'subprojects', 'gxml', 'gxml'),
    '--vapidir', join_paths(meson.project_build_root(), 'subprojects', 'vadi', 'lib'),
    libgenesis_core_vala_args, libgenesis_core_docs_args],
  build_by_default: true)

install_subdir(join_paths(meson.current_build_dir(), 'devhelp', 'libgenesis'), install_dir: join_paths(datadir, 'devhelp', 'books'))
