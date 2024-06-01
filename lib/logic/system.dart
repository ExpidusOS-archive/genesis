import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class SystemManager extends ChangeNotifier {
  static const channel = MethodChannel('com.expidusos.genesis.shell/system');

  SystemManager() {
    _sync();
  }

  SystemMetadata? _metadata = null;
  SystemMetadata? get metadata => _metadata;

  void _sync() {
    channel.invokeMethod('getMetadata').then((data) {
      _metadata = SystemMetadata(
        logo: data['logo'],
        osName: data['osName'],
        osId: data['osId'],
        versionId: data['versionId'],
        versionCodename: data['versionCodename'],
        prettyName: data['prettyName'],
      );

      notifyListeners();
    }).catchError((err) {
      print(err);
    });
  }
}

class SystemMetadata {
  const SystemMetadata({
    this.logo,
    this.osName,
    this.osId,
    this.versionId,
    this.versionCodename,
    this.prettyName,
  });

  final String? logo;
  final String? osName;
  final String? osId;
  final String? versionId;
  final String? versionCodename;
  final String? prettyName;
}
