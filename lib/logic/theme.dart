import 'package:flutter/material.dart';

TextStyle scaleTextStyleFor(TextStyle orig, double scale) =>
  orig.copyWith(
    fontSize: orig.fontSize! * scale,
  );

IconThemeData scaleIconThemeFor(IconThemeData orig, double scale) =>
  orig.copyWith(
    size: 24.0 * scale,
  );

AppBarTheme scaleAppBarThemeFor(AppBarTheme orig, double scale) =>
  orig.copyWith(
    toolbarHeight: kToolbarHeight * scale,
    iconTheme: scaleIconThemeFor(orig.iconTheme!, scale),
    toolbarTextStyle: scaleTextStyleFor(orig.toolbarTextStyle!, scale),
  );

ThemeData scaleThemeFor(ThemeData orig, double scale) =>
  orig.copyWith(
    appBarTheme: scaleAppBarThemeFor(orig.appBarTheme!, scale),
  );
