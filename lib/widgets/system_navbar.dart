import 'package:flutter/material.dart' as material;
import 'package:libtokyo_flutter/libtokyo.dart' hide ColorScheme;
import 'package:libtokyo/libtokyo.dart' hide TokyoApp, Scaffold;

import 'user_drawer.dart';

class SystemNavbar extends StatefulWidget {
  const SystemNavbar({ super.key });

  @override
  State<SystemNavbar> createState() => _SystemNavbarState();
}

class _SystemNavbarState extends State<SystemNavbar> {
  PersistentBottomSheetController? _controller;

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
            icon: Icon(Icons.chevronLeft),
          ),
          IconButton(
            onPressed: () {
              if (_controller != null) {
                _controller!.close();
                _controller = null;
              } else {
                _controller = material.Scaffold.of(context).showBottomSheet((context) =>
                  UserDrawer(
                    onClose: () {
                      _controller!.close();
                    },
                  ));
              }
            },
            icon: Icon(Icons.circleDot),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.bars),
          ),
        ],
      ),
    );
}
