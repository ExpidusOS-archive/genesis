import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../logic/power.dart';

class PowerDialog extends StatelessWidget {
  const PowerDialog({
    super.key,
    this.isLocked = false,
  });

  final bool isLocked;

  @override
  Widget build(BuildContext context) =>
    Dialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          !isLocked
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pushNamed('/lock'),
                          icon: Icon(Icons.lock),
                        ),
                        Text('Lock'),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () {
                            final nav = Navigator.of(context);
                            nav.popUntil(ModalRoute.withName(nav.widget.initialRoute ?? '/'));

                            if (nav.canPop()) nav.pop();
                            else SystemNavigator.pop();
                          },
                          icon: Icon(Icons.logout),
                        ),
                        Text('Log Out'),
                      ],
                    ),
                  ),
                ],
              ) : null,
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: Icon(Icons.restart_alt),
                    ),
                    Text('Restart'),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: Icon(Icons.power),
                    ),
                    Text('Shutdown'),
                  ],
                ),
              ),
            ],
          ),
        ].where((e) => e != null).toList().cast<Widget>(),
      ),
    );
}

class PowerBar extends StatefulWidget {
  const PowerBar({
    super.key,
    this.direction = Axis.horizontal,
    this.builder = null,
    this.filter = null,
  });

  final Axis direction;
  final Widget Function(BuildContext context, PowerDevice device)? builder;
  final bool Function(PowerDevice device)? filter;

  @override
  State<PowerBar> createState() => _PowerBarState();
}

class _PowerBarState extends State<PowerBar> {
  PowerManager mngr = PowerManager.auto();
  List<PowerDevice> devices = List.empty(growable: true);
  late StreamSubscription<PowerDevice> deviceAdded;
  late StreamSubscription<PowerDevice> deviceRemoved;

  @override
  void initState() {
    super.initState();

    deviceAdded = mngr.deviceAdded.listen((dev) => setState(() => devices.add(dev)));
    deviceRemoved = mngr.deviceRemoved.listen((dev) => setState(() => devices.removeWhere((i) => dev.name == i.name)));

    mngr.connect();
  }

  @override
  void dispose() {
    super.dispose();
    deviceAdded.cancel();
    deviceRemoved.cancel();
    mngr.disconnect();
  }

  @override
  Widget build(BuildContext context) =>
    Flex(
      direction: widget.direction,
      children: devices.where((dev) {
          if (widget.filter != null) {
            return widget.filter!(dev);
          }
          return dev.type == PowerDeviceType.battery;
        }).map((dev) {
          if (widget.builder != null) {
            return widget.builder!(context, dev);
          }
          return PowerIndicator(device: dev);
        }).toList(),
    );
}

class PowerIndicator extends StatefulWidget {
  const PowerIndicator({
    super.key,
    required this.device,
  });

  final PowerDevice device;

  @override
  State<PowerIndicator> createState() => _PowerIndicatorState();
}

class _PowerIndicatorState extends State<PowerIndicator> {
  PowerDeviceState state = PowerDeviceState.unknown;
  double percentage = 0;
  late StreamSubscription<List<String>> changed;

  Future<void> _sync() async {
    state = await widget.device.state();
    percentage = await widget.device.percentage();
  }

  @override
  void initState() {
    super.initState();
    changed = widget.device.changed.listen((_) => _sync().then((_) => setState(() {})));
    _sync().then((_) => setState(() {}));
  }

  @override
  void dispose() {
    super.dispose();
    changed.cancel();
  }

  IconData _getIconData() {
    switch (state) {
      case PowerDeviceState.full: return Icons.battery_charging_full;
      case PowerDeviceState.charging:
      case PowerDeviceState.discharging:
        if (percentage >= 90) return Icons.battery_6_bar;
        if (percentage >= 80) return Icons.battery_5_bar;
        if (percentage >= 60) return Icons.battery_4_bar;
        if (percentage >= 50) return Icons.battery_3_bar;
        if (percentage >= 30) return Icons.battery_2_bar;
        if (percentage >= 10) return Icons.battery_1_bar;
        return Icons.battery_0_bar;
      default:
        break;
    }
    return Icons.battery_unknown;
  }

  @override
  Widget build(BuildContext context) =>
    Icon(_getIconData());
}

class PowerTile extends StatefulWidget {
  const PowerTile({
    super.key,
    required this.device,
    this.onChanged = null,
  });

  final PowerDevice device;
  final VoidCallback? onChanged;

  @override
  State<PowerTile> createState() => _PowerTileState();
}

class _PowerTileState extends State<PowerTile> {
  late StreamSubscription<List<String>> changed;

  Widget _buildIcon(BuildContext context) {
    switch (widget.device.type) {
      case PowerDeviceType.battery: return PowerIndicator(device: widget.device);
      case PowerDeviceType.line: return Icon(Icons.power_input);
      case PowerDeviceType.mouse: return Icon(Icons.mouse);
      case PowerDeviceType.keyboard: return Icon(Icons.keyboard);
      default: break;
    }

    return Icon(Icons.power);
  }

  @override
  void initState() {
    super.initState();
    changed = widget.device.changed.listen((_) {
      if (widget.onChanged != null) {
        widget.onChanged!();
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    changed.cancel();
  }

  @override
  Widget build(BuildContext context) =>
    ListTile(
      leading: _buildIcon(context),
      title: Text(widget.device.name),
    );
}
