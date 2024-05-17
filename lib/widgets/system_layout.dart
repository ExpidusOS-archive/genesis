import 'package:backdrop/backdrop.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:libtokyo_flutter/libtokyo.dart' hide ColorScheme;
import 'package:libtokyo/libtokyo.dart' hide TokyoApp, Scaffold;
import 'package:provider/provider.dart';

import '../logic/outputs.dart';

import 'activity_drawer.dart';
import 'account_profile.dart';
import 'output_layout.dart';
import 'system_bar.dart';
import 'system_drawer.dart';

typedef Widget? SystemLayoutBuilder(BuildContext context, Output output, int outputIndex);

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
  }) : bodyBuilder = null,
       bottomNavigationBarBuilder = null;

  const SystemLayout.builder({
    super.key,
    required this.bodyBuilder,
    this.userMode = false,
    this.isLocked = false,
    this.hasDisplayServer = false,
    this.bottomSheet,
    this.bottomNavigationBarBuilder,
    this.userName = null,
  }) : body = null,
       bottomNavigationBar = null;

  final Widget? body;
  final SystemLayoutBuilder? bodyBuilder;
  final bool userMode;
  final bool isLocked;
  final bool hasDisplayServer;
  final Widget? bottomSheet;
  final Widget? bottomNavigationBar;
  final SystemLayoutBuilder? bottomNavigationBarBuilder;
  final String? userName;

  Widget? _makeWidget(BuildContext context, Output output, int outputIndex, Widget? a, SystemLayoutBuilder? buildable) {
    if (a != null) return a!;
    if (buildable != null) return buildable!(context, output, outputIndex);
    return null;
  }

  Widget _buildMobile(BuildContext context, Output output, int outputIndex) =>
    BackdropScaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(SystemBar.heightFor(context)),
        child: Builder(
          builder: (context) =>
            GestureDetector(
              child: SystemBar(
                height: SystemBar.heightFor(context),
                spacing: 4.0 * output.units,
              ),
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
                    userMode && !Breakpoints.large.isActive(context)
                      ? Row(
                          children: [
                            Expanded(
                              child: Card(
                                shape: const LinearBorder(),
                                color: Theme.of(context).colorScheme.background,
                                margin: EdgeInsets.zero,
                                child: Padding(
                                  padding: EdgeInsets.all(8 * output.units),
                                  child: userName == null
                                    ? AccountProfile(
                                        spacing: 8 * output.units,
                                        iconSize: 40 * output.units,
                                      ) : AccountProfile.name(
                                        name: userName!,
                                        spacing: 8 * output.units,
                                        iconSize: 40 * output.units,
                                      ),
                                ),
                              ),
                            ),
                          ],
                        ) : null,
                    SystemDrawer(
                      userMode: userMode,
                      isLocked: isLocked,
                      padding: 8 * output.units,
                      accountIconSize: 40 * output.units,
                    ),
                  ].where((e) => e != null).toList().cast<Widget>(),
                ),
              ),
            ),
            onVerticalDragDown: (details) => Backdrop.of(context).fling(),
          ),
      ),
      frontLayerScrim: Theme.of(context).colorScheme.background,
      frontLayer: _makeWidget(context, output, outputIndex, body, bodyBuilder) ?? const SizedBox(),
      bottomSheet: bottomSheet,
      bottomNavigationBar: _makeWidget(context, output, outputIndex, bottomNavigationBar, bottomNavigationBarBuilder),
      extendBody: true,
    );

  Widget _buildDesktop(BuildContext context, Output output, int outputIndex) =>
    Scaffold(
      appBar: PreferredSize(
        preferredSize: Size(double.infinity, SystemBar.heightFor(context) + (8.0 * output.units)),
        child: Padding(
          padding: EdgeInsets.all(4.0 * output.units),
          child: SystemBar(
            height: SystemBar.heightFor(context),
            spacing: 4.0 * output.units,
          ),
        ),
      ),
      drawer: userMode && !isLocked
        ? Padding(
            padding: EdgeInsets.all(8.0 * output.units),
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
                      ActivityDrawer(
                        hasDisplayServer: hasDisplayServer,
                        outputIndex: outputIndex,
                        padding: 8 * output.units,
                        iconSize: 64 * output.units,
                        axisExtent: 84 * output.units,
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
                padding: 8 * output.units,
                accountIconSize: 40 * output.units,
              ),
            ),
          ),
        ),
      ),
      body: _makeWidget(context, output, outputIndex, body, bodyBuilder),
      bottomSheet: bottomSheet,
      bottomNavigationBar: _makeWidget(context, output, outputIndex, bottomNavigationBar, bottomNavigationBarBuilder),
      backgroundColor: Color(Colors.transparent.value),
      extendBody: true,
    );

  @override
  Widget build(BuildContext context) =>
    OutputLayout(
      builder: (context, output, outputIndex) =>
        Provider<Output>.value(
          value: output,
          child: AdaptiveLayout(
            body: SlotLayout(
              config: {
                Breakpoints.small: SlotLayout.from(
                  key: const Key('Body Small'),
                  builder: (context) => _buildMobile(context, output, outputIndex),
                ),
                Breakpoints.medium: SlotLayout.from(
                  key: const Key('Body Medium'),
                  builder: (context) => _buildMobile(context, output, outputIndex),
                ),
                Breakpoints.large: SlotLayout.from(
                  key: const Key('Body Large'),
                  builder: (context) => _buildDesktop(context, output, outputIndex),
                ),
              },
            ),
          ),
        ),
    );
}
