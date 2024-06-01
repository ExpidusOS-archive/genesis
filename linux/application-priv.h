#pragma once

#include "channels/account.h"
#include "channels/applications.h"
#include "channels/auth.h"
#include "channels/display.h"
#include "channels/outputs.h"
#include "channels/session.h"
#include "channels/system.h"

struct _GenesisShellApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;

  GtkWindow* win;
  FlView* view;

  AccountChannel account;
  ApplicationsChannel applications;
  AuthChannel auth;
  DisplayChannel display;
  OutputsChannel outputs;
  SessionChannel session;
  SystemChannel system;
};
