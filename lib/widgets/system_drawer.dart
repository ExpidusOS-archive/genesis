import 'package:flutter/material.dart';

import '../logic/power.dart';

import 'power.dart';

class SystemDrawer extends StatelessWidget {
  const SystemDrawer({
    super.key,
    this.userMode = false,
  });

  final bool userMode;

  @override
  Widget build(BuildContext context) =>
    Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListView(
        children: [
          userMode ? Row(
            children: [
              Expanded(
                child: ButtonBar(),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: ButtonBar(
                  children: [
                    IconButton(
                      style: IconButton.styleFrom(
                        shape: const LinearBorder(),
                      ),
                      onPressed: () {},
                      icon: Icon(Icons.settings),
                    ),
                    IconButton(
                      style: IconButton.styleFrom(
                        shape: const LinearBorder(),
                      ),
                      onPressed: () {},
                      icon: Icon(Icons.power),
                    ),
                  ],
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
