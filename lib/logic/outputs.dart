import 'dart:collection';

import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class OutputManager extends ChangeNotifier {
  static const channel = MethodChannel('com.expidusos.genesis.shell/outputs');

  OutputManager() {
    channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'added':
        case 'removed':
          _sync();
          break;
        default:
          throw MissingPluginException();
      }
    });

    _sync();
  }

  final List<Output> _outputs = [];
  UnmodifiableListView<Output> get outputs => UnmodifiableListView(_outputs);

  void _sync() {
    channel.invokeListMethod('list').then((list) {
      _outputs.clear();
      _outputs.addAll(list!.map(
        (item) =>
          Output(
            model: item['model'],
            manufacturer: item['manufacturer'],
            scale: item['scale'],
            refreshRate: item['refreshRate'],
            geometry: OutputGeometry(
              x: item['geometry']['x'],
              y: item['geometry']['y'],
              width: item['geometry']['width'],
              height: item['geometry']['height'],
            ),
          )
      ));
      notifyListeners();
    }).catchError((err) {
      print(err);
    });
  }
}

class OutputGeometry {
  const OutputGeometry({
    this.x = 0,
    this.y = 0,
    this.width = 0,
    this.height = 0,
  });

  final int x;
  final int y;
  final int width;
  final int height;
}

class Output {
  const Output({
    this.model,
    this.manufacturer,
    required this.geometry,
    this.scale = 1,
    this.refreshRate = 0,
  });

  final String? model;
  final String? manufacturer;
  final OutputGeometry geometry;
  final int scale;
  final int refreshRate;
}