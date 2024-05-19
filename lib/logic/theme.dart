import 'package:flutter/material.dart';

import 'misc.dart';

TextStyle scaleTextStyleFor(TextStyle orig, ScaleFunction scale) =>
  orig.copyWith(
    fontSize: scale(orig.fontSize!),
  );

IconThemeData scaleIconThemeFor(IconThemeData orig, ScaleFunction scale) =>
  orig.copyWith(
    size: scale(24),
  );

AppBarTheme scaleAppBarThemeFor(AppBarTheme orig, ScaleFunction scale) =>
  orig.copyWith(
    toolbarHeight: scale(kToolbarHeight),
    iconTheme: scaleIconThemeFor(orig.iconTheme!, scale),
    titleTextStyle: scaleTextStyleFor(orig.titleTextStyle!, scale),
    toolbarTextStyle: scaleTextStyleFor(orig.toolbarTextStyle!, scale),
  );

BottomAppBarTheme scaleBottomAppBarThemeFor(BottomAppBarTheme orig, ScaleFunction scale) =>
  orig.copyWith(
    height: scale(80),
  );

DrawerThemeData scaleDrawerThemeFor(DrawerThemeData orig, ScaleFunction scale) =>
  orig.copyWith(
    width: scale(304),
  );

TextTheme scaleTextThemeFor(TextTheme orig, ScaleFunction scale) =>
  orig.copyWith(
    bodyLarge: scaleTextStyleFor(orig.bodyLarge!, scale),
    bodyMedium: scaleTextStyleFor(orig.bodyMedium!, scale),
    bodySmall: scaleTextStyleFor(orig.bodySmall!, scale),
    displayLarge: scaleTextStyleFor(orig.displayLarge!, scale),
    displayMedium: scaleTextStyleFor(orig.displayMedium!, scale),
    displaySmall: scaleTextStyleFor(orig.displaySmall!, scale),
    headlineLarge: scaleTextStyleFor(orig.headlineLarge!, scale),
    headlineMedium: scaleTextStyleFor(orig.headlineMedium!, scale),
    headlineSmall: scaleTextStyleFor(orig.headlineSmall!, scale),
    labelLarge: scaleTextStyleFor(orig.labelLarge!, scale),
    labelMedium: scaleTextStyleFor(orig.labelMedium!, scale),
    labelSmall: scaleTextStyleFor(orig.labelSmall!, scale),
    titleLarge: scaleTextStyleFor(orig.titleLarge!, scale),
    titleMedium: scaleTextStyleFor(orig.titleMedium!, scale),
    titleSmall: scaleTextStyleFor(orig.titleSmall!, scale),
  );

ThemeData scaleThemeFor(ThemeData orig, ScaleFunction scale) =>
  orig.copyWith(
    appBarTheme: scaleAppBarThemeFor(orig.appBarTheme!, scale),
    bottomAppBarTheme: scaleBottomAppBarThemeFor(orig.bottomAppBarTheme!, scale),
    drawerTheme: scaleDrawerThemeFor(orig.drawerTheme!, scale),
    primaryIconTheme: scaleIconThemeFor(orig.primaryIconTheme!, scale),
    iconTheme: scaleIconThemeFor(orig.iconTheme!, scale),
    textTheme: scaleTextThemeFor(orig.textTheme, scale),
  );
