import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:libtokyo_flutter/libtokyo.dart' hide ColorScheme;
import 'package:libtokyo/libtokyo.dart' hide TokyoApp;
import 'package:provider/provider.dart';

import '../logic/display.dart';
import '../logic/outputs.dart';
import '../logic/wallpaper.dart';
import '../logic/wm.dart';

import '../widgets/system_layout.dart';
import '../widgets/system_navbar.dart';
import '../widgets/wm.dart';

class DesktopView extends StatefulWidget {
  const DesktopView({
    super.key,
    this.wallpaper = null,
    this.desktopWallpaper = null,
    this.mobileWallpaper = null,
    this.userName = null,
    this.isSession = false,
  });

  final String? wallpaper;
  final String? desktopWallpaper;
  final String? mobileWallpaper;
  final String? userName;
  final bool isSession;

  @override
  State<DesktopView> createState() => _DesktopViewState();
}

class _DesktopViewState extends State<DesktopView> {
  static const authChannel = MethodChannel('com.expidusos.genesis.shell/auth');
  static const sessionChannel = MethodChannel('com.expidusos.genesis.shell/session');

  String? sessionName = null;
  DisplayServer? _displayServer = null;
  WindowManager? _windowManager = null;

  late StreamSubscription<DisplayServerToplevel> _toplevelAdded;
  late StreamSubscription<DisplayServerToplevel> _toplevelRemoved;

  GlobalKey _key = GlobalKey();

  void _syncOutputs() {
    final outputs = Provider.of<OutputManager>(_key.currentContext!, listen: false);
    _displayServer!.setOutputs(outputs.outputs);
  }

  void _init() async {
    try {
      sessionName = await sessionChannel.invokeMethod('open');
    } on PlatformException catch (e) {
      if (e.details is String) {
        sessionName = e.details as String;
      }
    }

    _windowManager = WindowManager(
      mode: Breakpoints.small.isActive(_key.currentContext!) ? WindowManagerMode.stacking : WindowManagerMode.floating,
    );

    final displayManager = Provider.of<DisplayManager>(_key.currentContext!, listen: false);

    _displayServer = await displayManager.start(
      sessionName: sessionName!,
    );

    final outputs = Provider.of<OutputManager>(_key.currentContext!, listen: false);
    outputs.addListener(_syncOutputs);

    _toplevelAdded = _displayServer!.toplevelAdded.listen((toplevel) {
      _windowManager!.fromToplevel(toplevel);
    });

    _toplevelRemoved = _displayServer!.toplevelRemoved.listen((toplevel) {
      _windowManager!.removeToplevel(toplevel);
    });

    _syncOutputs();
  }

  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance.addPostFrameCallback((_) {
      _init();
    });
  }

  @override
  void dispose() {
    super.dispose();

    if (sessionName != null) {
      sessionChannel.invokeMethod('close', sessionName!).catchError((err) {
        print(err);
      });
    }

    if (_windowManager != null) {
      _toplevelAdded.cancel();
      _toplevelRemoved.cancel();
      _windowManager!.dispose();
    }

    if (_displayServer != null) {
      _displayServer!.stop();
    }

    if (widget.isSession && widget.userName != null) {
      authChannel.invokeMethod('deauth', widget.userName).catchError((err) {
        print(err);
      });
    }

    final outputs = Provider.of<OutputManager>(_key.currentContext!, listen: false);
    outputs.removeListener(_syncOutputs);
  }

  @override
  Widget build(BuildContext context) {
    Widget value = SystemLayout.bodyBuilder(
      key: _key,
      userMode: true,
      userName: widget.userName,
      hasDisplayServer: _displayServer != null,
      bodyBuilder: (context, output, outputIndex) =>
        Container(
          decoration: BoxDecoration(
            image: getWallpaper(
              path: (Breakpoints.small.isActive(context) ? widget.mobileWallpaper : widget.desktopWallpaper) ?? widget.wallpaper,
              fallback: AssetImage('assets/wallpaper/${Breakpoints.small.isActive(context) ? 'mobile' : 'desktop'}/default.jpg'),
            ),
          ),
          constraints: BoxConstraints.expand(),
          child: _displayServer != null && _windowManager != null
            ? WindowManagerView(
                displayServer: _displayServer!,
                windowManager: _windowManager!,
                output: output,
                outputIndex: outputIndex,
              ) : null,
        ),
      bottomNavigationBar: Breakpoints.small.isActive(context)
        ? SystemNavbar() : null,
    );

    if (_displayServer != null && _windowManager != null) {
      value = ChangeNotifierProvider<DisplayServer>.value(
        value: _displayServer!,
        child: ChangeNotifierProvider<WindowManager>(
          create: (context) => _windowManager!,
          child: value,
        ),
      );
    }
    return value;
  }
}
