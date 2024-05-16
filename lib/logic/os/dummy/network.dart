import 'dart:async';
import '../../network.dart';

class DummyNetworkManager extends NetworkManager {
  DummyNetworkManager() : super();

  @override
  Future<void> connect() async {}

  @override
  void disconnect() {}
}
