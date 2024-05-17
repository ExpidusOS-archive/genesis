import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:libtokyo_flutter/libtokyo.dart' hide ColorScheme;
import 'package:libtokyo/libtokyo.dart' hide TokyoApp, Scaffold;
import 'package:provider/provider.dart';

import '../logic/power.dart';
import '../logic/outputs.dart';

import 'account_profile.dart';
import 'power.dart';

class SystemDrawer extends StatefulWidget {
  const SystemDrawer({
    super.key,
    this.userMode = false,
    this.isLocked = false,
    this.userName = null,
    this.padding = 8.0,
    this.accountIconSize = 40.0,
  });

  final bool userMode;
  final bool isLocked;
  final String? userName;
  final double padding;
  final double accountIconSize;

  @override
  State<SystemDrawer> createState() => _SystemDrawerState();
}

class _SystemDrawerState extends State<SystemDrawer> {
  final GlobalKey _powerButtonKey = GlobalKey();

  @override
  Widget build(BuildContext context) =>
    Padding(
      padding: EdgeInsets.all(widget.padding),
      child: ListView(
        shrinkWrap: true,
        children: [
          widget.userMode && Breakpoints.large.isActive(context)
            ? (widget.userName == null
              ? AccountProfile(
                  iconSize: widget.accountIconSize,
                  spacing: widget.padding,
                ) : AccountProfile.name(
                  iconSize: widget.accountIconSize,
                  name: widget.userName!,
                  spacing: widget.padding,
                )) : null,
          Row(
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
                          icon: Icon(Icons.gear),
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
                              spacing: widget.padding,
                            ),
                        ),
                      icon: Icon(Icons.powerOff),
                    ),
                  ].where((e) => e != null).toList().cast<Widget>(),
                ),
              ),
            ],
          ),
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
          ListTile(
            title: Text(
              '${Provider.of<Output>(context).toJSON()}'
            ),
          ),
        ].where((e) => e != null).toList().cast<Widget>(),
      ),
    );
}
