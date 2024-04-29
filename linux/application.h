#pragma once

#include <gtk/gtk.h>

G_DECLARE_FINAL_TYPE(GenesisShellApplication, genesis_shell_application, GENESIS_SHELL, APPLICATION,
                     GtkApplication)

/**
 * genesis_shell_application_new:
 *
 * Creates a new Flutter-based application.
 *
 * Returns: a new #GenesisShellApplication.
 */
GenesisShellApplication* genesis_shell_application_new();
