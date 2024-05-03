#pragma once

#include "channels/account.h"
#include "channels/auth.h"
#include "channels/display.h"
#include "channels/outputs.h"
#include "channels/session.h"

struct _GenesisShellApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
  GtkWindow* win;

  AccountChannel account;
  AuthChannel auth;
  DisplayChannel display;
  OutputsChannel outputs;
  SessionChannel session;
};
