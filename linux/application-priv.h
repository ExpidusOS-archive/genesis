#pragma once

#include "channels/auth.h"
#include "channels/display.h"
#include "channels/outputs.h"
#include "channels/session.h"

struct _GenesisShellApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
  GtkWindow* win;

  FlMethodChannel* account;
  AuthChannel auth;
  DisplayChannel display;
  OutputsChannel outputs;
  SessionChannel session;
};
