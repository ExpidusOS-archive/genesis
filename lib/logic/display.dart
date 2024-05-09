import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'outputs.dart';

class DisplayManager extends ChangeNotifier {
  static const channel = MethodChannel('com.expidusos.genesis.shell/display');

  DisplayManager() {
    channel.setMethodCallHandler((call) async {
      print(call.arguments);
      switch (call.method) {
        case 'newToplevel':
          final server = find(call.arguments['name']);
          if (server == null) break;

          server!._toplevels.add(DisplayServerToplevel._(server, call.arguments['id']));
          server!.notifyListeners();
          break;
        case 'removeToplevel':
          final server = find(call.arguments['name']);
          if (server == null) break;

          server!._toplevels.removeWhere((item) => item.id == call.arguments['id']);
          server!.notifyListeners();
          break;
        case 'requestToplevel':
          final server = find(call.arguments['name']);
          if (server == null) break;

          final toplevel = server._toplevels.firstWhere((item) => item.id == call.arguments['id']);

          switch (call.arguments['reqName']) {
            case 'map':
              toplevel.sync();
              break;
            default:
              toplevel.notifyListeners();
              server.notifyListeners();
              break;
          }
          break;
        case 'notifyToplevel':
          final server = find(call.arguments['name']);
          if (server == null) break;

          final toplevel = server._toplevels.firstWhere((item) => item.id == call.arguments['id']);

          switch (call.arguments['propName']) {
            case 'appId':
              toplevel._appId = call.arguments['propValue'];
              toplevel.notifyListeners();
              break;
            case 'title':
              toplevel._title = call.arguments['propValue'];
              toplevel.notifyListeners();
              break;
            case 'texture':
              toplevel._texture = call.arguments['propValue'];
              toplevel.notifyListeners();
              break;
            case 'parent':
              toplevel._parent = call.arguments['propValue'];
              toplevel.notifyListeners();
              break;
            default:
              throw MissingPluginException();
          }
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
    notifyListeners();
    return instance;
  }
}

class DisplayServer extends ChangeNotifier {
  DisplayServer._(this._manager, this.name);

  final DisplayManager _manager;
  final String name;

  List<DisplayServerToplevel> _toplevels = [];
  UnmodifiableListView<DisplayServerToplevel> get toplevels => UnmodifiableListView(_toplevels);

  Future<void> stop() async {
    await DisplayManager.channel.invokeMethod('stop', name);
    _manager._servers.removeWhere((entry) => entry.name == name);
    _manager.notifyListeners();
  }

  Future<void> setOutputs(List<Output> list) async {
    await DisplayManager.channel.invokeMethod('setOutputs', <String, dynamic>{
      'name': name,
      'list': list.map((item) => item.toJSON()).toList(),
    });
  }
}

class DisplayServerToplevelSize {
  const DisplayServerToplevelSize({
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

  static DisplayServerToplevelSize? fromJSON(dynamic data) {
    final width = data['width'] > 0 ? data['width'] : null;
    final height = data['height'] > 0 ? data['height'] : null;

    if (width == null && height == null) return null;

    return DisplayServerToplevelSize(
      width: width,
      height: height,
    );
  }
}

class DisplayServerToplevel extends ChangeNotifier {
  DisplayServerToplevel._(this._server, this.id) : _active = false, _suspended = false;

  final DisplayServer _server;
  final int id;

  String? _appId;
  String? get appId => _appId;

  String? _title;
  String? get title => _title;

  int? _texture;
  int? get texture => _texture;

  int? _parent;
  DisplayServerToplevel? get parent {
    if (_parent == null) return null;
    return _server._toplevels.firstWhere((item) => item.id == _parent);
  }

  DisplayServerToplevelSize? _size;
  DisplayServerToplevelSize? get size => _size;

  DisplayServerToplevelSize? _maxSize;
  DisplayServerToplevelSize? get maxSize => _maxSize;

  DisplayServerToplevelSize? _minSize;
  DisplayServerToplevelSize? get minSize => _minSize;

  bool _active;
  bool get active => _active;

  bool _suspended;
  bool get suspended => _suspended;

  Future<void> sync() async {
    final data = await DisplayManager.channel.invokeMethod('getToplevel', <String, dynamic>{
      'name': _server.name,
      'id': id,
    });
    print(data);

    _appId = data['appId'];
    _title = data['title'];
    _texture = data['texture'];
    _parent = data['parent'];
    _size = DisplayServerToplevelSize.fromJSON(data['size']);
    _minSize = DisplayServerToplevelSize.fromJSON(data['minSize']);
    _maxSize = DisplayServerToplevelSize.fromJSON(data['maxSize']);
    _active = data['active'];
    _suspended = data['suspended'];
    notifyListeners();
  }

  Future<void> setSize(int width, int height) async {
    _size = DisplayServerToplevelSize(width: width, height: height);
    await DisplayManager.channel.invokeMethod('setToplevel', <String, dynamic>{
      'name': _server.name,
      'id': id,
      'size': size!.toJSON(),
    });
    await sync();
  }

  Future<void> setActive(bool isActive) async {
    _active = isActive;
    await DisplayManager.channel.invokeMethod('setToplevel', <String, dynamic>{
      'name': _server.name,
      'id': id,
      'active': active,
    });
    await sync();
  }

  Future<void> setSuspended(bool isSuspended) async {
    _suspended = isSuspended;
    await DisplayManager.channel.invokeMethod('setToplevel', <String, dynamic>{
      'name': _server.name,
      'id': id,
      'suspended': suspended,
    });
    await sync();
  }
}
