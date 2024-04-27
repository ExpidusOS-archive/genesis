import 'dart:async';
import 'package:upower/upower.dart';
import '../../power.dart';

class LinuxPowerManager extends PowerManager {
  LinuxPowerManager() : super() {}

  final UPowerClient _client = UPowerClient();

  StreamController<PowerDevice> _deviceAddedCtrl = StreamController();
  StreamController<PowerDevice> _deviceRemovedCtrl = StreamController();
  late StreamSubscription<UPowerDevice> _deviceAddedSub;
  late StreamSubscription<UPowerDevice> _deviceRemovedSub;

  @override
  Stream<PowerDevice> get deviceAdded {
    return _deviceAddedCtrl.stream;
  }

  @override
  Stream<PowerDevice> get deviceRemoved {
    return _deviceRemovedCtrl.stream;
  }

  @override
  Future<void> connect() async {
    _deviceAddedSub = _client.deviceAdded.listen((dev) => _deviceAddedCtrl.add(LinuxPowerDevice(dev)));
    _deviceRemovedSub = _client.deviceRemoved.listen((dev) => _deviceRemovedCtrl.add(LinuxPowerDevice(dev)));

    await _client.connect();
  }

  @override
  void disconnect() {
    _deviceAddedSub.cancel();
    _deviceRemovedSub.cancel();
    _client.close();
  }

  @override
  Future<List<LinuxPowerDevice>> devices() async {
    return List.empty();
  }
}

class LinuxPowerDevice extends PowerDevice {
  LinuxPowerDevice(this._device) : super();

  final UPowerDevice _device;

  @override
  Stream<List<String>> get changed {
    return _device.propertiesChanged;
  }

  @override
  PowerDeviceType get type {
    switch (_device.type) {
      case UPowerDeviceType.linePower:
        if (_device.powerSupply) return PowerDeviceType.line;
        break;
      case UPowerDeviceType.battery: return PowerDeviceType.battery;
      case UPowerDeviceType.mouse: return PowerDeviceType.mouse;
      case UPowerDeviceType.keyboard: return PowerDeviceType.keyboard;
      default: break;
    }
    return PowerDeviceType.unknown;
  }

  @override
  String get name {
    if (_device.model.length == 0) return _device.nativePath;
    return _device.model;
  }

  @override
  bool get isOnline {
    return _device.online;
  }

  @override
  Future<double> percentage() async {
    return _device.percentage;
  }

  @override
  Future<PowerDeviceState> state() async {
    switch (_device.state) {
      case UPowerDeviceState.fullyCharged: return PowerDeviceState.full;
      case UPowerDeviceState.charging: return PowerDeviceState.charging;
      case UPowerDeviceState.discharging: return PowerDeviceState.discharging;
      case UPowerDeviceState.empty: return PowerDeviceState.empty;
      default: break;
    }
    return PowerDeviceState.unknown;
  }
}
