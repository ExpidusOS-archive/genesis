import 'package:libtokyo_flutter/libtokyo.dart' hide ColorScheme;
import 'package:libtokyo/libtokyo.dart' hide TokyoApp;
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'dart:async';
import 'package:provider/provider.dart';

import '../logic/display.dart';
import '../logic/outputs.dart';
import '../logic/wm.dart';

import 'surface.dart';

class WindowView extends StatelessWidget {
  const WindowView({
    super.key,
    required this.win,
    required this.desktopSize,
    this.decorHeight = kSurfaceDecorHeight,
    this.mode = null,
  });

  final Window win;
  final Size desktopSize;
  final double decorHeight;
  final WindowManagerMode? mode;

  Widget _buildInner(BuildContext context) {
    final _win = context.watch<Window>();
    final _mode = mode ?? _win.manager.mode;

    Widget content = SurfaceView(
      surface: _win.surface,
      buildDecor: (context, surface, content) =>
        Breakpoints.large.isActive(context)
          ? Container(
              width: surface.size != null ? (surface.size!.width ?? 0).toDouble() : null,
              child: Column(
                children: [
                  SurfaceDecor(
                    surface: surface,
                    height: decorHeight,
                    onMinimize: () {
                      win.minimized = true;
                    },
                    onMaximize: () {
                      if (win.surface.maximized) {
                        win.restore();
                      } else {
                        win.maximize(desktopSize);
                      }
                    },
                    onClose: () {
                      win.surface.close();
                    },
                    onDrag: (info) {
                      if (win.surface.maximized) win.restore();

                      // FIXME: a bug where multiple windows can drag at the same time after being raised.
                      if (!win.isOnTop) win.raiseToTop();

                      win.x += info.delta.dx;
                      win.y += info.delta.dy;
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
          width: _win.surface.size != null ? (_win.surface.size!.width ?? 0).toDouble() : null,
          height: _win.surface.size != null ? (_win.surface.size!.height ?? 0).toDouble() + decorHeight : null,
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

class WindowManagerView extends StatefulWidget {
  const WindowManagerView({
    super.key,
    required this.displayServer,
    required this.windowManager,
    required this.output,
    required this.outputIndex,
    this.mode,
    this.decorHeight = kSurfaceDecorHeight,
  });

  final DisplayServer displayServer;
  final WindowManager windowManager;
  final Output output;
  final int outputIndex;
  final WindowManagerMode? mode;
  final double decorHeight;

  @override
  State<WindowManagerView> createState() => _WindowManagerViewState();
}

class _WindowManagerViewState extends State<WindowManagerView> {
  List<Window> _getWindows(BuildContext context) {
    final displayServer = context.watch<DisplayServer>();
    final wm = context.watch<WindowManager>();

    final list = displayServer.surfaces.map((surface) => wm.fromSurface(surface))
      .where((win) => win.surface.monitor == widget.outputIndex)
      .where((win) => !win.minimized).toList();
    list.sort((a, b) => a.layer.compareTo(b.layer));
    return list;
  }

  Size _getDesktopSize(BuildContext context) {
    final renderObject = context.findRenderObject();
    if (renderObject == null) return Size(1, 1);
    return (renderObject as RenderBox).size;
  }

  Widget _buildTiling(BuildContext context) =>
    GridView(
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: MediaQuery.of(context).size.width,
      ),
      children: _getWindows(context).map(
        (win) => WindowView(
          win: win,
          desktopSize: _getDesktopSize(context),
          decorHeight: widget.decorHeight,
        )
      ).toList(),
    );

  Widget _buildFloating(BuildContext context) =>
    Stack(
      children: _getWindows(context).map(
        (win) => WindowView(
          win: win,
          desktopSize: _getDesktopSize(context),
          decorHeight: widget.decorHeight,
        ),
      ).toList(),
    );

  Widget _buildStacking(BuildContext context) =>
    Stack(
      fit: StackFit.expand,
      children: _getWindows(context).map(
        (win) => WindowView(
          win: win,
          desktopSize: _getDesktopSize(context),
          decorHeight: widget.decorHeight,
        ),
      ).toList(),
    );

  @override
  Widget build(BuildContext context) {
    if (widget.mode != null) {
      if (widget.mode! != widget.windowManager.mode) {
        widget.windowManager.mode = widget.mode!;
      }
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<DisplayServer>.value(value: widget.displayServer),
        ChangeNotifierProvider<WindowManager>.value(value: widget.windowManager),
      ],
      child: Builder(
        builder: (<WindowManagerMode, WidgetBuilder>{
          WindowManagerMode.tiling: _buildTiling,
          WindowManagerMode.floating: _buildFloating,
          WindowManagerMode.stacking: _buildStacking,
        })[widget.windowManager.mode]!,
      ),
    );
  }
}
