test('plugins/gtk3', executable('test-main', 'main.vala', dependencies: [libgenesis_core, plugin_gtk3]),
  env: [
    'G_TEST_SRCDIR=@0@'.format(meson.current_source_dir()),
    'G_TEST_BUILDDIR=@0@'.format(meson.current_build_dir())
  ], protocol: 'tap')
