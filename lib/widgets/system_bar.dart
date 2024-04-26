import 'package:flutter/material.dart';
import 'clock.dart';

const kSystemBarHeight = kToolbarHeight / 1.5;

class SystemBar extends StatelessWidget implements PreferredSizeWidget {
  const SystemBar({ super.key });

  @override
  Size get preferredSize => const Size.fromHeight(kSystemBarHeight);

  Widget _buildActions(BuildContext context) =>
    Row(
      children: [
        const DigitalClock(),
      ],
    );

  @override
  Widget build(BuildContext context) =>
    AppBar(
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
