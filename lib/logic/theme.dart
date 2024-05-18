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
    titleTextStyle: scaleTextStyleFor(orig.titleTextStyle!, scale),
    toolbarTextStyle: scaleTextStyleFor(orig.toolbarTextStyle!, scale),
  );

BottomAppBarTheme scaleBottomAppBarThemeFor(BottomAppBarTheme orig, double scale) =>
  orig.copyWith(
    height: 80 * scale,
  );

DrawerThemeData scaleDrawerThemeFor(DrawerThemeData orig, double scale) =>
  orig.copyWith(
    width: 304 * scale,
  );

TextTheme scaleTextThemeFor(TextTheme orig, double scale) =>
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

ThemeData scaleThemeFor(ThemeData orig, double scale) =>
  orig.copyWith(
    appBarTheme: scaleAppBarThemeFor(orig.appBarTheme!, scale),
    bottomAppBarTheme: scaleBottomAppBarThemeFor(orig.bottomAppBarTheme!, scale),
    drawerTheme: scaleDrawerThemeFor(orig.drawerTheme!, scale),
    primaryIconTheme: scaleIconThemeFor(orig.primaryIconTheme!, scale),
    iconTheme: scaleIconThemeFor(orig.iconTheme!, scale),
    textTheme: scaleTextThemeFor(orig.textTheme, scale),
  );
