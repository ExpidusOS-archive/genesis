conf_data_shell = configuration_data()
conf_data_shell.merge_from(conf_data)

build_conf_shell = configure_file(input: 'src/build.vala.in', output: 'build.vala',
  configuration: conf_data_shell)

shell_rel_sources = ['src/main.vala']
shell_sources = []

foreach src : shell_rel_sources
  shell_sources += [join_paths(meson.current_source_dir(), src)]
endforeach

if uncrustify.found()
  run_target('shell-prettier',
    command: [uncrustify, '--no-backup', shell_sources])
endif

shell_sources += [build_conf_shell]

executable('genesis-shell', build_conf_shell, shell_rel_sources,
  c_args: ['-DG_LOG_DOMAIN="GenesisShell"', '-DGETTEXT_PACKAGE="genesis-shell"'],
  vala_args: ['--define=GETTEXT_PACKAGE="genesis-shell"'],
  dependencies: [libgenesis_core],
  install: true)
