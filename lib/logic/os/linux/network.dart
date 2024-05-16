import 'dart:async';
import 'package:nm/nm.dart';
import '../../network.dart';

class LinuxNetworkManager extends NetworkManager {
  LinuxNetworkManager() : super();

  final NetworkManagerClient _client = NetworkManagerClient();

  @override
  Future<void> connect() async {
    await _client.connect();
  }

  @override
  void disconnect() {
    _client.close();
  }
}
