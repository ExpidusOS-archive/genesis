import 'dart:async';
import 'package:flutter/foundation.dart';
import 'os/linux/network.dart';
import 'os/dummy/network.dart';

abstract class NetworkManager {
  NetworkManager();

  factory NetworkManager.auto() {
    if (!kIsWeb) {
      if (defaultTargetPlatform == TargetPlatform.linux) {
        return LinuxNetworkManager();
      }
    }
    return DummyNetworkManager();
  }

  Future<void> connect();
  void disconnect();
}

enum NetworkDeviceType {
  unknown,
  ethernet,
  wifi,
  modem,
}

abstract class NetworkDevice {
  NetworkDeviceType get type;
}

abstract class WiFiNetwork {
}
