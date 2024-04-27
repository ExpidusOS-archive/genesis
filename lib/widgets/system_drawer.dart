import 'package:flutter/material.dart';

import '../logic/power.dart';

import 'power.dart';

class SystemDrawer extends StatelessWidget {
  const SystemDrawer({ super.key });

  @override
  Widget build(BuildContext context) =>
    Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListView(
        children: [
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
        ],
      ),
    );
}
