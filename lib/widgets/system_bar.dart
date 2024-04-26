import 'package:flutter/material.dart';

const kSystemBarHeight = kToolbarHeight / 1.5;

class SystemBar extends StatelessWidget implements PreferredSizeWidget {
  const SystemBar({ super.key });

  @override
  Size get preferredSize => const Size.fromHeight(kSystemBarHeight);

  @override
  Widget build(BuildContext context) =>
    AppBar(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
    );
}
