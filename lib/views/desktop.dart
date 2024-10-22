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
import '../widgets/surface.dart';
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

  late StreamSubscription<DisplayServerSurface> _surfaceAdded;
  late StreamSubscription<DisplayServerSurface> _surfaceRemoved;

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
      mode: Breakpoints.large.isActive(_key.currentContext!) ? WindowManagerMode.floating : WindowManagerMode.stacking,
    );

    final displayManager = Provider.of<DisplayManager>(_key.currentContext!, listen: false);

    _displayServer = await displayManager.start(
      sessionName: sessionName!,
    );

    final outputs = Provider.of<OutputManager>(_key.currentContext!, listen: false);
    outputs.addListener(_syncOutputs);

    _surfaceAdded = _displayServer!.surfaceAdded.listen((surface) {
      _windowManager!.fromSurface(surface);
    });

    _surfaceRemoved = _displayServer!.surfaceRemoved.listen((surface) {
      _windowManager!.removeSurface(surface);
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
      _surfaceAdded.cancel();
      _surfaceRemoved.cancel();
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
    Widget value = SystemLayout.builder(
      key: _key,
      userMode: true,
      userName: widget.userName,
      hasDisplayServer: _displayServer != null,
      bodyBuilder: (context, output, outputIndex, shouldScale) =>
        Container(
          decoration: !Breakpoints.large.isActive(context)
            ? BoxDecoration(
                image: getWallpaper(
                  path: widget.mobileWallpaper ?? widget.wallpaper,
                  fallback: AssetImage('assets/wallpaper/mobile/default.jpg'),
                ),
              ) : null,
          constraints: BoxConstraints.expand(),
          child: _displayServer != null && _windowManager != null
            ? NotificationListener<SizeChangedLayoutNotification>(
                onNotification: (notif) {
                  _windowManager!.mode = Breakpoints.large.isActive(_key.currentContext!) ? WindowManagerMode.floating : WindowManagerMode.stacking;
                  return true;
                },
                child: SizeChangedLayoutNotifier(
                  child: WindowManagerView(
                    displayServer: _displayServer!,
                    windowManager: _windowManager!,
                    output: output,
                    outputIndex: outputIndex,
                    decorHeight: SurfaceDecor.heightFor(context),
                    mode: Breakpoints.large.isActive(_key.currentContext!) ? WindowManagerMode.floating : WindowManagerMode.stacking,
                  ),
                ),
              ) : null,
        ),
      bottomNavigationBarBuilder: !Breakpoints.large.isActive(context)
        ? (context, output, outputIndex, shouldScale) =>
          SystemNavbar(
            outputIndex: outputIndex,
            hasDisplayServer: _displayServer != null && _windowManager != null,
            padding: shouldScale ? output.applyScale(8) : 8,
            iconSize: shouldScale ? output.applyScale(64) : 64,
            axisExtent: shouldScale ? output.applyScale(84) : 84,
            height: SystemNavbar.heightFor(context),
          ) : null,
    );

    if (Breakpoints.large.isActive(context)) {
      value = Container(
        decoration: BoxDecoration(
          image: getWallpaper(
            path: widget.desktopWallpaper ?? widget.wallpaper,
            fallback: AssetImage('assets/wallpaper/desktop/default.jpg'),
          ),
        ),
        child: value,
      );
    }

    if (_displayServer != null && _windowManager != null) {
      value = ChangeNotifierProvider<DisplayServer>(
        create: (context) => _displayServer!,
        child: ChangeNotifierProvider<WindowManager>(
          create: (context) => _windowManager!,
          child: value,
        ),
      );
    }
    return value;
  }
}
