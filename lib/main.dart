import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:system_theme/system_theme.dart';

import 'logic/theme.dart' show buildThemeData;
import 'views/system/lock.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemTheme.accentColor.load();

  runApp(const MyApp());

  doWhenWindowReady(() {
    const initialSize = Size(600, 450);
    appWindow.size = initialSize;
    appWindow.alignment = Alignment.center;
    appWindow.show();
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
          home: const SystemLockView(),
        ),
      );
  }
}
