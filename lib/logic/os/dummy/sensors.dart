import 'dart:async';
import '../../sensors.dart';

class DummySensorsManager extends SensorsManager {
  DummySensorsManager() : super();

  Future<void> connect() async {}

  void disconnect() {}

  Future<SensorAccelerometer?> getAccelerometer() async {
    return null;
  }

  Future<SensorLight?> getLight() async {
    return null;
  }
}
