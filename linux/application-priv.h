#pragma once

struct _GenesisShellApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
  FlMethodChannel* outputs;
  FlMethodChannel* account;
  FlMethodChannel* auth;
  GtkWindow* win;
};
