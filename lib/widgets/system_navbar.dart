import 'package:flutter/material.dart' as material;
import 'package:libtokyo_flutter/libtokyo.dart' hide ColorScheme;
import 'package:libtokyo/libtokyo.dart' hide TokyoApp, Scaffold;

import 'activity_drawer.dart';

const kSystemNavbarHeight = kToolbarHeight / 2.0;

class SystemNavbar extends StatefulWidget {
  const SystemNavbar({
    super.key,
    required this.outputIndex,
    this.hasDisplayServer = false,
    this.padding = 8,
    this.iconSize = 64,
    this.axisExtent = 84,
    this.height = kSystemNavbarHeight,
  });

  final int outputIndex;
  final bool hasDisplayServer;
  final double padding;
  final double iconSize;
  final double axisExtent;
  final double height;

  @override
  State<SystemNavbar> createState() => _SystemNavbarState();

  static double heightFor(BuildContext context) {
    final theme = BottomAppBarTheme.of(context);
    return (theme.height ?? kToolbarHeight) / 2.0;
  }
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
            icon: Icon(Icons.chevronLeft, size: widget.height - widget.padding),
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
            icon: Icon(Icons.circleDot, size: widget.height - widget.padding),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.bars, size: widget.height - widget.padding),
          ),
        ],
      ),
    );
}
