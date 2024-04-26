import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../widgets/clock.dart';
import '../../widgets/system_layout.dart';

class SystemLockView extends StatefulWidget {
  const SystemLockView({ super.key });

  @override
  State<SystemLockView> createState() => _SystemLockViewState();
}

class _SystemLockViewState extends State<SystemLockView> {
  @override
  Widget build(BuildContext context) =>
    SystemLayout(
      body: Center(
        child: Column(
          children: [
            const Spacer(),
            DigitalClock(
              format: DateFormat.yMMMd(),
              style: Theme.of(context).textTheme.displayLarge,
            ),
            DigitalClock(
              style: Theme.of(context).textTheme.displayLarge,
            ),
            const Spacer(),
          ],
        ),
      ),
    );
}
