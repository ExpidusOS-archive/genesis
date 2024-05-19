import 'dart:async';
import 'package:flutter/foundation.dart';
import 'os/linux/sensors.dart';
import 'os/dummy/sensors.dart';

abstract class SensorsManager {
  SensorsManager();

  factory SensorsManager.auto() {
    if (!kIsWeb) {
      if (defaultTargetPlatform == TargetPlatform.linux) {
        return LinuxSensorsManager();
      }
    }
    return DummySensorsManager();
  }

  Future<void> connect();
  void disconnect();

  Future<SensorAccelerometer?> getAccelerometer();
  Future<SensorLight?> getLight();
}

enum SensorAccelerometerOrientation {
  normal,
  bottom_up,
  left_up,
  right_up,
}

abstract class SensorAccelerometer {
  SensorAccelerometerOrientation? get orientation;

  void dispose();
}

enum SensorLightUnit {
  lux,
  vendor,
}

abstract class SensorLight {
  SensorLightUnit get unit;
  int get level;

  void dispose();
}
