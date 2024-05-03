import 'dart:io' show exit;
import 'package:args/args.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:system_theme/system_theme.dart';

import 'logic/outputs.dart';
import 'logic/route_args.dart';
import 'logic/theme.dart' show buildThemeData;

import 'views/desktop.dart';
import 'views/lock.dart';
import 'views/login.dart';

void main(List<String> argsList) async {
  final argsParser = ArgParser()
    ..addFlag('init-locked', help: 'Adding this option will start Genesis Shell in a locked state')
    ..addFlag('display-manager', help: 'Start as a display manager')
    ..addFlag('help', abbr: 'h', negatable: false);

  final args = argsParser.parse(argsList);

  if (args.flag('help')) {
    print(argsParser.usage);
    exit(0);
  }

  if (args.flag('display-manager') && args.flag('init-locked')) {
    print('Cannot run as a display manager and start locked');
    exit(1);
  }

  WidgetsFlutterBinding.ensureInitialized();
  await SystemTheme.accentColor.load();

  runApp(GenesisShellApp(
    initLocked: args.flag('init-locked'),
    displayManager: args.flag('display-manager'),
  ));

  doWhenWindowReady(() {
    const initialSize = Size(600, 450);
    appWindow.size = initialSize;
    appWindow.alignment = Alignment.center;
    appWindow.show();
  });
}

class GenesisShellApp extends StatefulWidget {
  const GenesisShellApp({
    super.key,
    this.initLocked = false,
    this.displayManager = false,
  });

  final bool initLocked;
  final bool displayManager;

  @override
  State<GenesisShellApp> createState() => _GenesisShellAppState();
}

class _GenesisShellAppState extends State<GenesisShellApp> {
  late OutputManager _outputManager;

  @override
  void initState() {
    super.initState();

    _outputManager = OutputManager();
  }

  @override
  Widget build(BuildContext context) {
    return SystemThemeBuilder(
      builder: (context, accent) =>
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => _outputManager),
          ],
          child: MaterialApp(
            title: 'Genesis Shell',
            theme: buildThemeData(
              accent: accent,
              brightness: Brightness.light,
            ),
            darkTheme: buildThemeData(
              accent: accent,
              brightness: Brightness.dark,
            ),
            themeMode: ThemeMode.dark,
            routes: {
              '/': (context) {
                final args = AuthedRouteArguments.of(context);
                return DesktopView(
                  userName: args.userName,
                  isSession: args.isSession,
                );
              },
              '/lock': (context) => LockView(userName: AuthedRouteArguments.of(context).userName),
              '/login': (_) => const LoginView(),
            },
            initialRoute: widget.initLocked ? '/lock' : (widget.displayManager ? '/login' : '/'),
          ),
        ),
      );
  }
}
