import 'package:backdrop/backdrop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';

import 'output_layout.dart';
import 'system_bar.dart';
import 'system_drawer.dart';

class SystemLayout extends StatelessWidget {
  const SystemLayout({
    super.key,
    required this.body,
    this.userMode = false,
    this.bottomSheet,
  });

  final Widget body;
  final bool userMode;
  final Widget? bottomSheet;

  Widget _buildMobile(BuildContext context) =>
    BackdropScaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kSystemBarHeight),
        child: Builder(
          builder: (context) =>
            GestureDetector(
              child: const SystemBar(),
              onVerticalDragDown: (details) => Backdrop.of(context).fling(),
            ),
        ),
      ),
      backLayerBackgroundColor: Theme.of(context).colorScheme.inversePrimary,
      backLayer: Builder(
        builder: (context) =>
          GestureDetector(
            child: ListTileTheme(
              tileColor: Theme.of(context).colorScheme.background,
              child: IconButtonTheme(
                data: IconButtonThemeData(
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.background,
                  ),
                ),
                child: SystemDrawer(
                  userMode: userMode,
                ),
              ),
            ),
            onVerticalDragDown: (details) => Backdrop.of(context).fling(),
          ),
      ),
      frontLayerScrim: Theme.of(context).colorScheme.background,
      frontLayer: body,
      bottomSheet: bottomSheet,
    );

  Widget _buildDesktop(BuildContext context) =>
    Scaffold(
      appBar: const PreferredSize(
        preferredSize: const Size(double.infinity, kSystemBarHeight + 4.0),
        child: const Padding(
          padding: EdgeInsets.all(4.0),
          child: const SystemBar(),
        ),
      ),
      endDrawer: Drawer(
        child: ListTileTheme(
          tileColor: Theme.of(context).colorScheme.inversePrimary,
          child: IconButtonTheme(
            data: IconButtonThemeData(
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.inversePrimary,
              ),
            ),
            child: SystemDrawer(
              userMode: userMode,
            ),
          ),
        ),
      ),
      body: body,
      bottomSheet: bottomSheet,
    );

  @override
  Widget build(BuildContext context) =>
    OutputLayout(
      builder: (context) =>
        AdaptiveLayout(
          body: SlotLayout(
            config: {
              Breakpoints.small: SlotLayout.from(
                key: const Key('Body Small'),
                builder: _buildMobile,
              ),
              Breakpoints.medium: SlotLayout.from(
                key: const Key('Body Medium'),
                builder: _buildDesktop,
              ),
              Breakpoints.large: SlotLayout.from(
                key: const Key('Body Large'),
                builder: _buildDesktop,
              ),
            },
          ),
        ),
    );
}
