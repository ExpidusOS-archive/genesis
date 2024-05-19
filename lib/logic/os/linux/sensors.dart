import 'dart:async';
import 'package:dbus/dbus.dart';
import '../../sensors.dart';

class LinuxSensorsManager extends SensorsManager {
  LinuxSensorsManager() : super();

  Future<void> connect() async {}

  void disconnect() {}

  Future<SensorAccelerometer?> getAccelerometer() async {
    return null;
  }

  Future<SensorLight?> getLight() async {
    return null;
  }
}
