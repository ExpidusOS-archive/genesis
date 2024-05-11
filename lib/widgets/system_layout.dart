import 'package:backdrop/backdrop.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:libtokyo_flutter/libtokyo.dart' hide ColorScheme;
import 'package:libtokyo/libtokyo.dart' hide TokyoApp, Scaffold;

import 'account_profile.dart';
import 'output_layout.dart';
import 'system_bar.dart';
import 'system_drawer.dart';
import 'user_drawer.dart';

class SystemLayout extends StatelessWidget {
  const SystemLayout({
    super.key,
    required this.body,
    this.userMode = false,
    this.isLocked = false,
    this.hasDisplayServer = false,
    this.bottomSheet,
    this.bottomNavigationBar,
    this.userName = null,
  });

  final Widget body;
  final bool userMode;
  final bool isLocked;
  final bool hasDisplayServer;
  final Widget? bottomSheet;
  final Widget? bottomNavigationBar;
  final String? userName;

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
      backLayerBackgroundColor: Theme.of(context).colorScheme.background,
      backLayer: Builder(
        builder: (context) =>
          GestureDetector(
            child: ListTileTheme(
              tileColor: Theme.of(context).colorScheme.surface,
              child: IconButtonTheme(
                data: IconButtonThemeData(
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.surface,
                  ),
                ),
                child: Column(
                  children: [
                    userMode && Breakpoints.small.isActive(context)
                      ? Row(
                          children: [
                            Expanded(
                              child: Card(
                                shape: const LinearBorder(),
                                color: Theme.of(context).colorScheme.background,
                                margin: EdgeInsets.zero,
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: userName == null ? AccountProfile() : AccountProfile.name(name: userName!),
                                ),
                              ),
                            ),
                          ],
                        ) : null,
                    SystemDrawer(
                      userMode: userMode,
                      isLocked: isLocked,
                    ),
                  ].where((e) => e != null).toList().cast<Widget>(),
                ),
              ),
            ),
            onVerticalDragDown: (details) => Backdrop.of(context).fling(),
          ),
      ),
      frontLayerScrim: Theme.of(context).colorScheme.background,
      frontLayer: body,
      bottomSheet: bottomSheet,
      bottomNavigationBar: bottomNavigationBar,
      extendBody: true,
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
      drawer: userMode && !isLocked
        ? Padding(
            padding: const EdgeInsets.all(8.0),
            child: Drawer(
              width: double.infinity,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: ListTileTheme(
                tileColor: Theme.of(context).colorScheme.surface,
                child: IconButtonTheme(
                  data: IconButtonThemeData(
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.surface,
                    ),
                  ),
                  child: Builder(
                    builder: (context) =>
                      UserDrawer(
                        hasDisplayServer: hasDisplayServer,
                        onClose: () {
                          material.Scaffold.of(context).closeDrawer();
                        },
                      ),
                  ),
                ),
              ),
            ),
          ) : null,
      endDrawer: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Drawer(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: ListTileTheme(
            tileColor: Theme.of(context).colorScheme.surface,
            child: IconButtonTheme(
              data: IconButtonThemeData(
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                ),
              ),
              child: SystemDrawer(
                userMode: userMode,
                isLocked: isLocked,
                userName: userName,
              ),
            ),
          ),
        ),
      ),
      body: body,
      bottomSheet: bottomSheet,
      bottomNavigationBar: bottomNavigationBar,
      extendBody: true,
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
