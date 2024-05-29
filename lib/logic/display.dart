import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'outputs.dart';

class DisplayManager extends ChangeNotifier {
  static const channel = MethodChannel('com.expidusos.genesis.shell/display');

  DisplayManager() {
    channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'newSurface':
          final server = find(call.arguments['name']);
          if (server == null) break;

          final surface = DisplayServerSurface._(server, call.arguments['id']);

          server!._surfaceAddedCtrl.add(surface);
          server!._surfaces.add(surface);
          server!.notifyListeners();
          break;
        case 'removeSurface':
          final server = find(call.arguments['name']);
          if (server == null) break;

          final surface = server._surfaces.firstWhere((item) => item.id == call.arguments['id']);

          server!._surfaces.add(surface);
          server!._surfaces.removeWhere((item) => item.id == call.arguments['id']);
          server!.notifyListeners();
          break;
        case 'requestSurface':
          final server = find(call.arguments['name']);
          if (server == null) break;

          final surface = server._surfaces.firstWhere((item) => item.id == call.arguments['id']);

          switch (call.arguments['reqName']) {
            case 'map':
              surface.sync();
              break;
            default:
              surface.notifyListeners();
              server.notifyListeners();
              break;
          }

          surface._reqCtrl.add(call.arguments['reqName']);
          break;
        case 'notifySurface':
          final server = find(call.arguments['name']);
          if (server == null) break;

          final surface = server._surfaces.firstWhere((item) => item.id == call.arguments['id']);

          switch (call.arguments['propName']) {
            case 'appId':
              surface._appId = call.arguments['propValue'];
              surface.notifyListeners();
              break;
            case 'title':
              surface._title = call.arguments['propValue'];
              surface.notifyListeners();
              break;
            case 'texture':
              surface._texture = call.arguments['propValue'];
              surface.notifyListeners();
              break;
            case 'parent':
              surface._parent = call.arguments['propValue'];
              surface.notifyListeners();
              break;
            case 'hasDecorations':
              surface._hasDecorations = call.arguments['propValue'];
              surface.notifyListeners();
              break;
            default:
              throw MissingPluginException();
          }

          surface._notifyCtrl.add(DisplayServerSurfaceNotify(
            propName: call.arguments['propName'],
            propValue: call.arguments['propValue'],
          ));
          break;
        default:
          throw MissingPluginException();
      }
    });

    channel.invokeListMethod<String>('list').then((list) {
      _servers.clear();
      _servers.addAll(list!.map(
        (name) =>
          DisplayServer._(this, name)
      ));
    }).catchError((err) {
      print(err);
    });
  }

  List<DisplayServer> _servers = [];

  StreamController<DisplayServer> _serverStartedCtrl = StreamController();
  Stream<DisplayServer> get serverStarted => _serverStartedCtrl.stream.asBroadcastStream();

  StreamController<DisplayServer> _serverStoppedCtrl = StreamController();
  Stream<DisplayServer> get serverStopped => _serverStoppedCtrl.stream.asBroadcastStream();

  DisplayServer? find(String name) {
    for (final server in _servers) {
      if (server.name == name) return server;
    }
    return null;
  }

  Future<DisplayServer> start({
    required String sessionName,
  }) async {
    final name = await channel.invokeMethod('start', <String, dynamic>{
      'sessionName': sessionName,
    });

    final instance = DisplayServer._(this, name);
    _servers.add(instance);
    _serverStartedCtrl.add(instance);
    notifyListeners();
    return instance;
  }
}

class DisplayServer extends ChangeNotifier {
  DisplayServer._(this._manager, this.name);

  final DisplayManager _manager;
  final String name;

  List<DisplayServerSurface> _surfaces = [];
  UnmodifiableListView<DisplayServerSurface> get surfaces => UnmodifiableListView(_surfaces);

  StreamController<DisplayServerSurface> _surfaceAddedCtrl = StreamController();
  Stream<DisplayServerSurface> get surfaceAdded => _surfaceAddedCtrl.stream.asBroadcastStream();

  StreamController<DisplayServerSurface> _surfaceRemovedCtrl = StreamController();
  Stream<DisplayServerSurface> get surfaceRemoved => _surfaceRemovedCtrl.stream.asBroadcastStream();

  Future<void> stop() async {
    await DisplayManager.channel.invokeMethod('stop', name);
    _manager._servers.removeWhere((entry) => entry.name == name);
    _manager._serverStoppedCtrl.add(this);
    _manager.notifyListeners();
  }

  Future<void> setOutputs(List<Output> list) async {
    await DisplayManager.channel.invokeMethod('setOutputs', <String, dynamic>{
      'name': name,
      'list': list.map((item) => item.toJSON()).toList(),
    });
  }
}

class DisplayServerSurfaceNotify {
  const DisplayServerSurfaceNotify({
    required this.propName,
    required this.propValue,
  });

  final String propName;
  final String propValue;
}

class DisplayServerSurfaceSize {
  const DisplayServerSurfaceSize({
    this.width,
    this.height,
  });

  final int? width;
  final int? height;

  dynamic toJSON() {
    return <String, dynamic>{
      'width': width ?? 0,
      'height': height ?? 0,
    };
  }

  static DisplayServerSurfaceSize? fromJSON(dynamic data) {
    final width = data['width'] > 0 ? data['width'] : null;
    final height = data['height'] > 0 ? data['height'] : null;

    if (width == null && height == null) return null;

    return DisplayServerSurfaceSize(
      width: width,
      height: height,
    );
  }
}

class DisplayServerSurface extends ChangeNotifier {
  DisplayServerSurface._(this._server, this.id) :
    _active = false,
    _suspended = false,
    _maximized = false,
    _hasDecorations = false,
    _monitor = 0;

  final DisplayServer _server;
  final int id;

  StreamController<DisplayServerSurfaceNotify> _notifyCtrl = StreamController();
  Stream<DisplayServerSurfaceNotify> get notify => _notifyCtrl.stream.asBroadcastStream();

  StreamController<String> _reqCtrl = StreamController();
  Stream<String> get req => _reqCtrl.stream.asBroadcastStream();

  String? _appId;
  String? get appId => _appId;

  String? _title;
  String? get title => _title;

  int? _texture;
  int? get texture => _texture;

  int? _parent;
  DisplayServerSurface? get parent {
    if (_parent == null) return null;
    return _server._surfaces.firstWhere((item) => item.id == _parent);
  }

  DisplayServerSurfaceSize? _size;
  DisplayServerSurfaceSize? get size => _size;

  DisplayServerSurfaceSize? _maxSize;
  DisplayServerSurfaceSize? get maxSize => _maxSize;

  DisplayServerSurfaceSize? _minSize;
  DisplayServerSurfaceSize? get minSize => _minSize;

  bool _active;
  bool get active => _active;

  bool _suspended;
  bool get suspended => _suspended;

  bool _maximized;
  bool get maximized => _maximized;

  bool _hasDecorations;
  bool get hasDecorations => _hasDecorations;

  int _monitor;
  int get monitor => _monitor;

  Future<void> close() => sendRequest('close');

  Future<void> sendRequest(String name) async {
    await DisplayManager.channel.invokeMethod('requestSurface', <String, dynamic>{
      'name': _server.name,
      'id': id,
      'reqName': name,
    });
  }

  Future<void> sync() async {
    final data = await DisplayManager.channel.invokeMethod('getSurface', <String, dynamic>{
      'name': _server.name,
      'id': id,
    });
    print(data);

    _appId = data['appId'];
    _title = data['title'];
    _texture = data['texture'];
    _parent = data['parent'];
    _size = DisplayServerSurfaceSize.fromJSON(data['size']);
    _minSize = DisplayServerSurfaceSize.fromJSON(data['minSize']);
    _maxSize = DisplayServerSurfaceSize.fromJSON(data['maxSize']);
    _active = data['active'];
    _suspended = data['suspended'];
    _maximized = data['maximized'];
    _hasDecorations = data['hasDecorations'];
    _monitor = data['monitor'];
    notifyListeners();
  }

  Future<void> setSize(int width, int height) async {
    _size = DisplayServerSurfaceSize(width: width, height: height);
    await DisplayManager.channel.invokeMethod('setSurface', <String, dynamic>{
      'name': _server.name,
      'id': id,
      'size': size!.toJSON(),
    });
    await sync();
  }

  Future<void> setActive(bool isActive) async {
    _active = isActive;
    await DisplayManager.channel.invokeMethod('setSurface', <String, dynamic>{
      'name': _server.name,
      'id': id,
      'active': active,
    });
    await sync();
  }

  Future<void> setSuspended(bool isSuspended) async {
    _suspended = isSuspended;
    await DisplayManager.channel.invokeMethod('setSurface', <String, dynamic>{
      'name': _server.name,
      'id': id,
      'suspended': suspended,
    });
    await sync();
  }

  Future<void> setMaximized(bool isMaximized) async {
    _maximized = isMaximized;
    await DisplayManager.channel.invokeMethod('setSurface', <String, dynamic>{
      'name': _server.name,
      'id': id,
      'maximized': maximized,
    });
    await sync();
  }

  Future<void> setMonitor(int monitor) async {
    _monitor = monitor;
    await DisplayManager.channel.invokeMethod('setSurface', <String, dynamic>{
      'name': _server.name,
      'id': id,
      'monitor': monitor,
    });
    await sync();
  }

  BoxConstraints buildBoxConstraints({
    double minWidthAppend = 0,
    double minHeightAppend = 0,
  }) =>
    BoxConstraints(
      minWidth: (minSize == null ? 0 : (minSize!.width ?? 0).toDouble()) + minWidthAppend,
      minHeight: (minSize == null ? 0 : (minSize!.height ?? 0).toDouble()) + minHeightAppend,
      maxWidth: maxSize == null ? double.infinity : (maxSize!.width ?? double.infinity).toDouble(),
      maxHeight: maxSize == null ? double.infinity : (maxSize!.height ?? double.infinity).toDouble(),
    );
}
