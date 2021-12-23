valadoc = find_program('valadoc')

basic_command = [
	valadoc,
	'--force',
	'--verbose',
	'--package-name',meson.project_name(),
	'--package-version', meson.project_version(),
	'--pkg', 'gio-2.0',
	'--pkg', 'glib-2.0',
	'--pkg', 'gobject-2.0',
	'--pkg', 'libpeas-1.0',
	'--pkg', 'gtk+-3.0',
	'--pkg', 'devident-client-1.0',
	'--pkg', 'polkit-agent-1',
	'--pkg', 'polkit-gobject-1',
	'--pkg', 'gtk-layer-shell-0',
	'--pkg', 'libhandy-1',
	'--vapidir=' + join_paths(meson.source_root(), 'vapi'),
	'--vapidir=' + meson.project_build_root(),
	'--importdir=' + join_paths(get_option('prefix'), get_option('datadir'), 'gtk-doc', 'html'),
	'--doclet=html',
	'--use-svg-images'
]

libgenesis_docs = custom_target(
	'library documentation',
	command: [basic_command, '-o', '@OUTPUT@', '@INPUT@'],
	build_by_default: true,
	input: libgenesis_common_files + libgenesis_component_files + libgenesis_shell_files + libgenesis_widgets_files + files(join_paths(meson.project_build_root(), 'build.vala')),
	output: 'libgenesis')