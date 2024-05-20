import 'package:flutter/material.dart' show Scaffold;
import 'package:libtokyo_flutter/libtokyo.dart' hide ColorScheme, Scaffold;
import 'package:libtokyo/libtokyo.dart' hide TokyoApp, Scaffold;
import 'package:provider/provider.dart';

import '../logic/outputs.dart';

import 'clock.dart';
import 'power.dart';

const kSystemBarHeight = kToolbarHeight / 1.5;

class SystemBar extends StatelessWidget implements PreferredSizeWidget {
  const SystemBar({
    super.key,
    this.height,
    this.spacing = 4.0,
  });

  final double? height;
  final double spacing;

  @override
  Size get preferredSize => Size.fromHeight(height ?? kSystemBarHeight);

  Widget _buildActions(BuildContext context) =>
    Row(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: spacing),
          child: const PowerBar(),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: spacing),
          child: const DigitalClock(),
        ),
      ],
    );

  @override
  Widget build(BuildContext context) =>
    AppBar(
      automaticallyImplyLeading: false,
      leading: Scaffold.of(context).hasDrawer
        ? IconButton(
            onPressed: () {
              final state = Scaffold.of(context);
              if (state.isDrawerOpen) {
                state.closeDrawer();
              } else {
                state.openDrawer();
              }
            },
            icon: Icon(Icons.bars),
          ) : null,
      actions: [
        Scaffold.of(context).hasEndDrawer ?
          InkWell(
            child: _buildActions(context),
            onTap: () {
              final state = Scaffold.of(context);
              if (state.isEndDrawerOpen) {
                state.closeEndDrawer();
              } else {
                state.openEndDrawer();
              }
            },
          ) : _buildActions(context),
      ],
      toolbarHeight: height ?? kSystemBarHeight,
    );

  static double heightFor(BuildContext context) {
    final theme = AppBarTheme.of(context);
    return (theme.toolbarHeight ?? kToolbarHeight) / 1.5;
  }
}
