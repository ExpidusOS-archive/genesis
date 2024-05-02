import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';

import '../logic/power.dart';

import 'account_profile.dart';
import 'power.dart';

class SystemDrawer extends StatefulWidget {
  const SystemDrawer({
    super.key,
    this.userMode = false,
    this.isLocked = false,
  });

  final bool userMode;
  final bool isLocked;

  @override
  State<SystemDrawer> createState() => _SystemDrawerState();
}

class _SystemDrawerState extends State<SystemDrawer> {
  final GlobalKey _powerButtonKey = GlobalKey();

  @override
  Widget build(BuildContext context) =>
    Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListView(
        shrinkWrap: true,
        children: [
          widget.userMode && !Breakpoints.small.isActive(context) ? const AccountProfile() : null,
          widget.userMode ? Row(
            children: [
              Expanded(
                child: ButtonBar(),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: ButtonBar(
                  children: [
                    !widget.isLocked
                      ? IconButton(
                          style: IconButton.styleFrom(
                            shape: const LinearBorder(),
                          ),
                          onPressed: () {},
                          icon: Icon(Icons.settings),
                        ) : null,
                    IconButton(
                      key: _powerButtonKey,
                      style: IconButton.styleFrom(
                        shape: const LinearBorder(),
                      ),
                      // TODO: on desktop, align to the button.
                      onPressed: () =>
                        showDialog(
                          context: context,
                          builder: (context) =>
                            PowerDialog(
                              isLocked: widget.isLocked,
                            ),
                        ),
                      icon: Icon(Icons.power),
                    ),
                  ].where((e) => e != null).toList().cast<Widget>(),
                ),
              ),
            ],
          ) : null,
          StatefulBuilder(
            builder: (context, setState) =>
              PowerBar(
                direction: Axis.vertical,
                filter: (device) {
                  if (device.type == PowerDeviceType.line) return device.isOnline;
                  return device.type != PowerDeviceType.unknown;
                },
                builder: (context, device) => PowerTile(
                  device: device,
                  onChanged: () => setState(() {}),
                ),
              ),
          ),
        ].where((e) => e != null).toList().cast<Widget>(),
      ),
    );
}
