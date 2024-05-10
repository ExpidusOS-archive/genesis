import 'package:libtokyo_flutter/libtokyo.dart' hide ColorScheme;
import 'package:libtokyo/libtokyo.dart' hide TokyoApp;
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'dart:async';
import 'package:provider/provider.dart';

import '../logic/display.dart';
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
    Widget content = ToplevelView(
      toplevel: win.toplevel,
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

    if (mode == WindowManagerMode.floating) {
      content = Positioned(
        top: win.y,
        left: win.x,
        child: Container(
          width: win.toplevel.size != null ? (win.toplevel.size!.width ?? 0).toDouble() : null,
          height: win.toplevel.size != null ? (win.toplevel.size!.height ?? 0).toDouble() + (kToolbarHeight / 1.5) : null,
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
    this.mode = WindowManagerMode.floating,
  });

  final DisplayServer displayServer;
  final WindowManagerMode mode;

  @override
  State<WindowManagerView> createState() => WindowManagerViewState();

  static WindowManagerViewState? maybeOf(BuildContext context) =>
    context.findAncestorStateOfType<WindowManagerViewState>();

  static WindowManagerViewState of(BuildContext context) => maybeOf(context)!;
}

class WindowManagerViewState extends State<WindowManagerView> {
  WindowManager _instance = WindowManager();
  late StreamSubscription<DisplayServerToplevel> _toplevelAdded;
  late StreamSubscription<DisplayServerToplevel> _toplevelRemoved;

  WindowManager get instance => _instance;

  @override
  void initState() {
    super.initState();

    _toplevelAdded = widget.displayServer.toplevelAdded.listen((toplevel) {
      _instance.fromToplevel(toplevel);
    });

    _toplevelRemoved = widget.displayServer.toplevelRemoved.listen((toplevel) {
      _instance.removeToplevel(toplevel);
    });
  }

  @override
  void dispose() {
    super.dispose();
    _instance.dispose();
    _toplevelAdded.cancel();
    _toplevelRemoved.cancel();
  }

  List<Window> _getWindows(BuildContext context) {
    final displayServer = context.watch<DisplayServer>();
    final wm = context.watch<WindowManager>();

    final list = displayServer.toplevels.map((toplevel) => wm.fromToplevel(toplevel))
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
        ChangeNotifierProvider<DisplayServer>.value(value: widget.displayServer),
        ChangeNotifierProvider<WindowManager>.value(value: _instance),
      ],
      child: Builder(
        builder: (<WindowManagerMode, WidgetBuilder>{
          WindowManagerMode.tiling: _buildTiling,
          WindowManagerMode.floating: _buildFloating,
          WindowManagerMode.stacking: _buildStacking,
        })[widget.mode]!,
      ),
    );
}
