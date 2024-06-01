import 'dart:async';
import 'package:dbus/dbus.dart';
import 'package:upower/upower.dart';
import '../../power.dart';

class LinuxPowerManager extends PowerManager {
  LinuxPowerManager() : super() {}

  final DBusClient _sysbus = DBusClient.system();
  final UPowerClient _client = UPowerClient();

  StreamController<PowerDevice> _deviceAddedCtrl = StreamController();
  StreamController<PowerDevice> _deviceRemovedCtrl = StreamController();
  late StreamSubscription<UPowerDevice> _deviceAddedSub;
  late StreamSubscription<UPowerDevice> _deviceRemovedSub;
  bool? _canReboot;
  bool? _canShutdown;

  @override
  Stream<PowerDevice> get deviceAdded {
    return _deviceAddedCtrl.stream.asBroadcastStream();
  }

  @override
  Stream<PowerDevice> get deviceRemoved {
    return _deviceRemovedCtrl.stream.asBroadcastStream();
  }

  @override
  Future<void> connect() async {
    _deviceAddedSub = _client.deviceAdded.listen((dev) => _deviceAddedCtrl.add(LinuxPowerDevice(dev)));
    _deviceRemovedSub = _client.deviceRemoved.listen((dev) => _deviceRemovedCtrl.add(LinuxPowerDevice(dev)));

    await _client.connect();

    for (final value in PowerAction.values) {
      canAction(value);
    }
  }

  @override
  void disconnect() {
    _deviceAddedSub.cancel();
    _deviceRemovedSub.cancel();
    _client.close();
    _sysbus.close();
  }

  @override
  Future<List<LinuxPowerDevice>> devices() async {
    return List.empty();
  }

  @override
  Future<bool> canAction(PowerAction action) async {
    switch (action) {
      case PowerAction.reboot:
        if (_canReboot == null) {
          _canReboot = (await _sysbus.callMethod(
            destination: 'org.freedesktop.login1',
            path: DBusObjectPath('/org/freedesktop/login1'),
            interface: 'org.freedesktop.login1.Manager',
            name: 'CanReboot',
          )).returnValues[0].asString() == 'yes';
        }
        return _canReboot ?? false;
      case PowerAction.shutdown:
        if (_canShutdown == null) {
          _canShutdown = (await _sysbus.callMethod(
            destination: 'org.freedesktop.login1',
            path: DBusObjectPath('/org/freedesktop/login1'),
            interface: 'org.freedesktop.login1.Manager',
            name: 'CanPowerOff',
          )).returnValues[0].asString() == 'yes';
        }
        return _canShutdown ?? false;
      default:
        break;
    }
    return false;
  }

  @override
  Future<void> doAction(PowerAction action) async {
    switch (action) {
      case PowerAction.reboot:
        await _sysbus.callMethod(
          destination: 'org.freedesktop.login1',
          path: DBusObjectPath('/org/freedesktop/login1'),
          interface: 'org.freedesktop.login1.Manager',
          name: 'Reboot',
          values: [
            DBusBoolean(false),
          ],
        );
      case PowerAction.shutdown:
        await _sysbus.callMethod(
          destination: 'org.freedesktop.login1',
          path: DBusObjectPath('/org/freedesktop/login1'),
          interface: 'org.freedesktop.login1.Manager',
          name: 'PowerOff',
          values: [
            DBusBoolean(false),
          ],
        );
      default:
        throw Exception('Unimplemented action: ${action.name}');
    }
  }
}

class LinuxPowerDevice extends PowerDevice {
  LinuxPowerDevice(this._device) : super();

  final UPowerDevice _device;

  @override
  Stream<List<String>> get changed {
    return _device.propertiesChanged.asBroadcastStream();
  }

  @override
  PowerDeviceType get type {
    try {
      switch (_device.type) {
        case UPowerDeviceType.linePower:
          if (_device.powerSupply) return PowerDeviceType.line;
          break;
        case UPowerDeviceType.battery: return PowerDeviceType.battery;
        case UPowerDeviceType.mouse: return PowerDeviceType.mouse;
        case UPowerDeviceType.keyboard: return PowerDeviceType.keyboard;
        default: break;
      }
    } on RangeError catch (e) {
      switch (e.invalidValue as int ?? 0) {
        case 17: return PowerDeviceType.headphones;
      }
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
