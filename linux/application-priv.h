#pragma once

struct _GenesisShellApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
  FlMethodChannel* outputs;
  FlMethodChannel* auth;
  GtkWindow* win;
};
