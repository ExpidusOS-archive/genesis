#pragma once
#include "channels/auth.h"
#include "channels/session.h"

struct _GenesisShellApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
  FlMethodChannel* outputs;
  FlMethodChannel* account;
  AuthChannel auth;
  SessionChannel session;
  GtkWindow* win;
};
