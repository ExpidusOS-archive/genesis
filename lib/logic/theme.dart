import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:system_theme/system_theme.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;

ThemeData buildThemeData({
  required SystemAccentColor accent,
  Brightness brightness = Brightness.light,
  TextTheme? textTheme = null,
  bool useMaterial3 = true,
}) {
  final primary = brightness == Brightness.light ? accent.dark : accent.light;

  return ThemeData.from(
    colorScheme: ColorScheme.fromSeed(
      brightness: brightness,
      seedColor: accent.accent,
      primary: primary,
    ),
    useMaterial3: useMaterial3,
    textTheme: (textTheme ?? GoogleFonts.albertSansTextTheme()).apply(
      displayColor: primary,
      bodyColor: primary,
    ),
  );
}
