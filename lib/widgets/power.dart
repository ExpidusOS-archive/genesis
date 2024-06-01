import 'dart:async';
import 'package:libtokyo_flutter/libtokyo.dart' hide ColorScheme;
import 'package:libtokyo/libtokyo.dart' hide TokyoApp;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../logic/power.dart';

class PowerDialog extends StatelessWidget {
  const PowerDialog({
    super.key,
    this.isLocked = false,
    this.spacing = 8,
  });

  final bool isLocked;
  final double spacing;

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
                    padding: EdgeInsets.all(spacing),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () {
                            final nav = Navigator.of(context);
                            nav.popUntil(ModalRoute.withName('/'));
                            nav.pushNamed('/lock');
                          },
                          icon: Icon(Icons.lock),
                        ),
                        Text('Lock'),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(spacing),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () {
                            final nav = Navigator.of(context);
                            nav.popUntil(ModalRoute.withName('/'));

                            if (nav.canPop()) nav.pop();
                            else SystemNavigator.pop();
                          },
                          icon: Icon(Icons.doorOpen),
                        ),
                        Text('Log Out'),
                      ],
                    ),
                  ),
                ],
              ) : null,
          Consumer<PowerManager>(
            builder: (context, mngr, _) =>
              FutureBuilder(
                future: Future.wait([
                  mngr.canAction(PowerAction.reboot),
                  mngr.canAction(PowerAction.shutdown),
                ]),
                builder: (context, snapshot) {
                  final data = snapshot.data ?? [ false, false ];
                  final canReboot = data[0];
                  final canShutdown = data[1];
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                  canReboot
                    ? Padding(
                        padding: EdgeInsets.all(spacing),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () => mngr.doAction(PowerAction.reboot),
                              icon: Icon(Icons.arrowsRotate),
                            ),
                            Text('Restart'),
                          ],
                        ),
                      ) : null,
                  canShutdown
                    ? Padding(
                        padding: EdgeInsets.all(spacing),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () => mngr.doAction(PowerAction.shutdown),
                              icon: Icon(Icons.powerOff),
                            ),
                            Text('Shutdown'),
                          ],
                        ),
                      ) : null,
                    ].where((e) => e != null).toList().cast<Widget>(),
                  );
                },
              ),
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
      case PowerDeviceState.full: return Icons.batteryFull;
      case PowerDeviceState.charging:
      case PowerDeviceState.discharging:
        if (percentage >= 90) return Icons.batteryFull;
        if (percentage >= 75) return Icons.batteryThreeQuarters;
        if (percentage >= 50) return Icons.batteryHalf;
        if (percentage >= 25) return Icons.batteryQuarter;
        return Icons.batteryEmpty;
      default:
        break;
    }
    return Icons.batteryEmpty;
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
      case PowerDeviceType.line: return Icon(Icons.plug);
      case PowerDeviceType.mouse: return Icon(Icons.mouse);
      case PowerDeviceType.keyboard: return Icon(Icons.keyboard);
      case PowerDeviceType.headphones: return Icon(Icons.headphones);
      default: break;
    }

    return Icon(Icons.bolt);
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
