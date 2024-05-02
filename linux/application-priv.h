#pragma once

#include "channels/session.h"

struct _GenesisShellApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
  FlMethodChannel* outputs;
  FlMethodChannel* account;
  FlMethodChannel* auth;
  SessionChannel session;
  GtkWindow* win;
};
