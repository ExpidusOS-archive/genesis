import 'package:libtokyo_flutter/libtokyo.dart' hide ColorScheme;
import 'package:libtokyo/libtokyo.dart' hide TokyoApp;
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'dart:async';
import 'package:provider/provider.dart';

import '../logic/display.dart';
import '../logic/outputs.dart';
import '../logic/wm.dart';

import 'toplevel.dart';

class WindowView extends StatelessWidget {
  const WindowView({
    super.key,
    required this.win,
    this.mode = null,
  });

  final Window win;
  final WindowManagerMode? mode;

  Widget _buildInner(BuildContext context) {
    final _win = context.watch<Window>();
    final _mode = mode ?? _win.manager.mode;

    Widget content = ToplevelView(
      toplevel: _win.toplevel,
      buildDecor: (context, toplevel, content) =>
        !Breakpoints.small.isActive(context)
          ? Container(
              width: toplevel.size != null ? (toplevel.size!.width ?? 0).toDouble() : null,
              child: Column(
                children: [
                  ToplevelDecor(
                    toplevel: toplevel,
                    onMinimize: () {
                      win.minimized = true;
                    },
                    onClose: () {
                      win.toplevel.close();
                    },
                    onDrag: (info) {
                      // FIXME: a bug where multiple windows can drag at the same time after being raised.
                      if (!_win.isOnTop) _win.raiseToTop();

                      _win.x += info.delta.dx;
                      _win.y += info.delta.dy;
                    },
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    child: content,
                  ),
                ],
              ),
            ) : null,
    );

    if (_mode == WindowManagerMode.floating) {
      content = Positioned(
        top: _win.y,
        left: _win.x,
        child: Container(
          width: _win.toplevel.size != null ? (_win.toplevel.size!.width ?? 0).toDouble() : null,
          height: _win.toplevel.size != null ? (_win.toplevel.size!.height ?? 0).toDouble() + (kToolbarHeight / 1.5) : null,
          child: content,
        ),
      );
    }
    return content;
  }

  @override
  Widget build(BuildContext context) =>
    ChangeNotifierProvider.value(
      value: win,
      child: Builder(
        builder: _buildInner,
      ),
    );
}

class WindowManagerView extends StatelessWidget {
  const WindowManagerView({
    super.key,
    required this.displayServer,
    required this.windowManager,
    required this.output,
    required this.outputIndex,
  });

  final DisplayServer displayServer;
  final WindowManager windowManager;
  final Output output;
  final int outputIndex;

  List<Window> _getWindows(BuildContext context) {
    final _displayServer = context.watch<DisplayServer>();
    final _wm = context.watch<WindowManager>();

    final list = _displayServer.toplevels.map((toplevel) => _wm.fromToplevel(toplevel))
      .where((win) => win.monitor == outputIndex)
      .where((win) => !win.minimized).toList();
    list.sort((a, b) => a.layer.compareTo(b.layer));
    return list;
  }

  Widget _buildTiling(BuildContext context) =>
    GridView(
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: MediaQuery.of(context).size.width,
      ),
      children: _getWindows(context).map(
        (win) => WindowView(win: win)
      ).toList(),
    );

  Widget _buildFloating(BuildContext context) =>
    Stack(
      children: _getWindows(context).map(
        (win) => WindowView(win: win),
      ).toList(),
    );

  Widget _buildStacking(BuildContext context) =>
    Stack(
      fit: StackFit.expand,
      children: _getWindows(context).map(
        (win) => WindowView(win: win),
      ).toList(),
    );

  @override
  Widget build(BuildContext context) =>
    MultiProvider(
      providers: [
        ChangeNotifierProvider<DisplayServer>.value(value: displayServer),
        ChangeNotifierProvider<WindowManager>.value(value: windowManager),
      ],
      child: Builder(
        builder: (<WindowManagerMode, WidgetBuilder>{
          WindowManagerMode.tiling: _buildTiling,
          WindowManagerMode.floating: _buildFloating,
          WindowManagerMode.stacking: _buildStacking,
        })[windowManager.mode]!,
      ),
    );
}
