import 'package:flutter/material.dart';
import 'clock.dart';
import 'power.dart';

const kSystemBarHeight = kToolbarHeight / 1.5;

class SystemBar extends StatelessWidget implements PreferredSizeWidget {
  const SystemBar({ super.key });

  @override
  Size get preferredSize => const Size.fromHeight(kSystemBarHeight);

  Widget _buildActions(BuildContext context) =>
    Row(
      children: [
        const PowerBar(),
        const DigitalClock(),
      ],
    );

  @override
  Widget build(BuildContext context) =>
    AppBar(
      automaticallyImplyLeading: false,
      leading: Scaffold.of(context).hasDrawer
        ? IconButton.filled(
            onPressed: () {
              final state = Scaffold.of(context);
              if (state.isDrawerOpen) {
                state.closeDrawer();
              } else {
                state.openDrawer();
              }
            },
            icon: Icon(Icons.apps),
          ) : null,
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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
    );
}
