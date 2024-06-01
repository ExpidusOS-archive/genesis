import 'dart:async';
import 'package:flutter/foundation.dart';
import 'os/linux/power.dart';
import 'os/dummy/power.dart';

abstract class PowerManager {
  PowerManager();

  factory PowerManager.auto() {
    if (!kIsWeb) {
      if (defaultTargetPlatform == TargetPlatform.linux) {
        return LinuxPowerManager();
      }
    }
    return DummyPowerManager();
  }

  Stream<PowerDevice> get deviceAdded;
  Stream<PowerDevice> get deviceRemoved;

  Future<void> connect();
  void disconnect();
  Future<List<PowerDevice>> devices();

  Future<bool> canAction(PowerAction action);
  Future<void> doAction(PowerAction action);
}

abstract class PowerDevice {
  PowerDevice();

  Stream<List<String>> get changed;
  String get name;
  PowerDeviceType get type;
  bool get isOnline;

  Future<PowerDeviceState> state();
  Future<double> percentage();
}

enum PowerDeviceState {
  charging,
  discharging,
  full,
  empty,
  unknown,
}

enum PowerDeviceType {
  battery,
  line,
  mouse,
  keyboard,
  headphones,
  unknown,
}

enum PowerAction {
  shutdown,
  reboot,
}
