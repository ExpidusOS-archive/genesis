i18n = import('i18n')

add_project_arguments('-DGETTEXT_PACKAGE="genesis-shell"', language: 'c')
i18n.gettext(meson.project_name(), args: '--directory=' + meson.source_root())