import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'outputs.dart';

class DisplayManager extends ChangeNotifier {
  static const channel = MethodChannel('com.expidusos.genesis.shell/display');

  DisplayManager() {
    channel.setMethodCallHandler((call) async {
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
            case 'commit':
              toplevel.notifyListeners();
              break;
          }
          break;
        case 'notifyToplevel':
          final server = find(call.arguments['name']);
          if (server == null) break;

          final toplevel = server._toplevels.firstWhere((item) => item.id == call.arguments['id']);

          switch (call.arguments['propName']) {
            case 'appId':
              toplevel.appId = call.arguments['propValue'];
              toplevel.notifyListeners();
              break;
            case 'title':
              toplevel.title = call.arguments['propValue'];
              toplevel.notifyListeners();
              break;
            case 'texture':
              toplevel.texture = call.arguments['propValue'];
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

class DisplayServerToplevel extends ChangeNotifier {
  DisplayServerToplevel._(this._server, this.id);

  final DisplayServer _server;
  final int id;

  String? appId;
  String? title;
  int? texture;

  int? _parent;
  DisplayServerToplevel? get parent {
    if (_parent == null) return null;
    return _server._toplevels.firstWhere((item) => item.id == _parent);
  }

  Future<void> sync() async {
    final data = await DisplayManager.channel.invokeMethod('getToplevel', <String, dynamic>{
      'name': _server.name,
      'id': id,
    });

    appId = data['appId'];
    title = data['title'];
    texture = data['texture'];
    _parent = data['parent'];
    notifyListeners();
  }

  Future<void> setSize(int width, int height) async {
    await DisplayManager.channel.invokeMethod('setToplevelSize', <String, dynamic>{
      'name': _server.name,
      'id': id,
      'width': width,
      'height': height,
    });
  }
}
