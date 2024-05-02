import 'package:flutter/material.dart';

class SystemNavbar extends StatelessWidget {
  const SystemNavbar({ super.key });

  @override
  Widget build(BuildContext context) =>
    BottomAppBar(
      height: 45,
      padding: EdgeInsets.zero,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.navigate_before),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.apps),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.menu),
          ),
        ],
      ),
    );
}
