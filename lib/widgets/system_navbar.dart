import 'package:flutter/material.dart' as material;
import 'package:libtokyo_flutter/libtokyo.dart' hide ColorScheme;
import 'package:libtokyo/libtokyo.dart' hide TokyoApp, Scaffold;

import 'activity_drawer.dart';

class SystemNavbar extends StatefulWidget {
  const SystemNavbar({
    super.key,
    required this.outputIndex,
    this.hasDisplayServer = false,
    this.padding = 8,
    this.iconSize = 64,
    this.axisExtent = 84,
    this.height = 45,
  });

  final int outputIndex;
  final bool hasDisplayServer;
  final double padding;
  final double iconSize;
  final double axisExtent;

  @override
  State<SystemNavbar> createState() => _SystemNavbarState();
}

class _SystemNavbarState extends State<SystemNavbar> {
  PersistentBottomSheetController? _controller;

  @override
  Widget build(BuildContext context) =>
    BottomAppBar(
      height: widget.height,
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
                  ActivityDrawer(
                    outputIndex: widget.outputIndex,
                    hasDisplayServer: widget.hasDisplayServer,
                    padding: widget.padding,
                    iconSize: widget.iconSize,
                    axisExtent: widget.axisExtent,
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
