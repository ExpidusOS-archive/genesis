import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ApplicationsManager {
  static const channel = MethodChannel('com.expidusos.genesis.shell/applications');

  ApplicationsManager() {
    channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'sync':
          _sync();
          break;
        default:
          throw MissingPluginException();
      }
    });

    _sync();
  }

  List<Application> _applications = [];
  UnmodifiableListView<Application> get applications => UnmodifiableListView(_applications);

  void _sync() {
    channel.invokeListMethod('list').then((list) {
      _applications.clear();
      _applications.addAll(list!.map(
        (app) =>
          Application(
            id: app['id'],
            name: app['name'],
            displayName: app['displayName'],
            description: app['description'],
            isHidden: app['isHidden'],
            icon: app['icon'],
          )
      ));
    }).catchError((err) {
      print(err);
    });
  }
}

class Application {
  const Application({
    this.id,
    this.name,
    this.displayName,
    this.description,
    this.isHidden = false,
    this.icon,
  });

  final String? id;
  final String? name;
  final String? displayName;
  final String? description;
  final bool isHidden;
  final String? icon;

  Future<bool> launch() async {
    return await ApplicationsManager.channel.invokeMethod('launch', id);
  }
}
