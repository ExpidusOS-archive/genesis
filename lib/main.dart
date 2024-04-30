import 'dart:io' show exit;
import 'package:args/args.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:system_theme/system_theme.dart';

import 'logic/theme.dart' show buildThemeData;
import 'views/desktop.dart';
import 'views/lock.dart';

void main(List<String> argsList) async {
  final argsParser = ArgParser()
    ..addFlag('init-locked', help: 'Adding this option will start Genesis Shell in a locked state')
    ..addFlag('help', abbr: 'h', negatable: false);

  final args = argsParser.parse(argsList);

  if (args.flag('help')) {
    print(argsParser.usage);
    exit(0);
  }

  WidgetsFlutterBinding.ensureInitialized();
  await SystemTheme.accentColor.load();

  runApp(GenesisShellApp(
    initLocked: args.flag('init-locked'),
  ));

  doWhenWindowReady(() {
    const initialSize = Size(600, 450);
    appWindow.size = initialSize;
    appWindow.alignment = Alignment.center;
    appWindow.show();
  });
}

class GenesisShellApp extends StatelessWidget {
  const GenesisShellApp({
    super.key,
    this.initLocked = false,
  });

  final bool initLocked;

  @override
  Widget build(BuildContext context) {
    return SystemThemeBuilder(
      builder: (context, accent) =>
        MaterialApp(
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
            '/': (_) => const DesktopView(),
            '/lock': (_) => const LockView(),
          },
          initialRoute: initLocked ? '/lock' : '/',
        ),
      );
  }
}
