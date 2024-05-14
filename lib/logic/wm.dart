import 'dart:ui';
import 'package:flutter/foundation.dart';

import 'display.dart';

enum WindowManagerMode {
  tiling,
  floating,
  stacking,
}

class WindowManager extends ChangeNotifier {
  WindowManager({
    this.mode = WindowManagerMode.stacking,
  }) : _next_layer = 0;

  WindowManagerMode mode;
  List<Window> _wins = [];
  int _next_layer;

  void dispose() {}

  Window fromToplevel(DisplayServerToplevel toplevel) {
    for (final win in _wins) {
      if (win.toplevel == toplevel) return win;
    }

    final win = Window._(this, toplevel);
    win._layer = _next_layer++;
    _wins.add(win);
    notifyListeners();
    return win;
  }

  void removeToplevel(DisplayServerToplevel toplevel) {
    _wins.removeWhere((win) => win.toplevel == toplevel);
    notifyListeners();
  }
}

class Window extends ChangeNotifier {
  Window._(this.manager, this.toplevel) :
    _x = 0, _y = 0, _layer = 0, _monitor = 0, _minimized = false;

  final WindowManager manager;
  final DisplayServerToplevel toplevel;
  Size? _size;
  double? _old_x;
  double? _old_y;

  @override
  void notifyListeners() {
    super.notifyListeners();
    manager.notifyListeners();
  }

  double _x;
  double get x => _x;
  set x(double value) {
    _x = value;
    notifyListeners();
  }

  double _y;
  double get y => _y;
  set y(double value) {
    _y = value;
    notifyListeners();
  }

  int _layer;
  int get layer => _layer;
  set layer(int value) {
    _layer = value;
    notifyListeners();
  }

  int _monitor;
  int get monitor => _monitor;
  set monitor(int value) {
    _monitor = value;
    notifyListeners();
  }

  bool _minimized;
  bool get minimized => _minimized;

  set minimized(bool value) {
    _minimized = value;
    notifyListeners();
  }

  bool get isOnTop => layer == (manager._next_layer - 1);

  void raiseToTop() {
    layer = manager._next_layer++;
  }

  Future<void> restore() async {
    if (_size != null) {
      await toplevel.setSize(_size!.width.toInt(), _size!.height.toInt());
      await toplevel.setMaximized(false);

      x = _old_x ?? 0;
      y = _old_y ?? 0;

      _old_x = 0;
      _old_y = 0;
      _size = null;
    }
  }

  Future<void> maximize(Size desktopSize) async {
    _size = Size(toplevel.size!.width!.toDouble(), toplevel.size!.height!.toDouble());
    raiseToTop();

    _old_x = x;
    _old_y = y;

    x = 0;
    y = 0;

    await toplevel.setMaximized(true);
    await toplevel.setSize(desktopSize.width.toInt(), desktopSize.height.toInt());
  }
}
