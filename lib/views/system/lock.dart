import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../widgets/clock.dart';
import '../../widgets/draggable.dart';
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
      body: Stack(
        children: [
          Center(
            child: Column(
              children: [
                const Spacer(),
                DigitalClock(
                  style: Theme.of(context).textTheme.displayLarge,
                ),
                DigitalClock(
                  format: DateFormat.yMMMd(),
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const Spacer(),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: VerticalDragContainer(
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
              startHeight: 60.0,
              minHeight: 60.0,
              expandedHeight: MediaQuery.of(context).size.height - 60,
              handle: Container(
                color: Theme.of(context).colorScheme.surface,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Icon(Icons.lock),
                  ),
                ),
              ),
              child: AnimatedDefaultTextStyle(
                style: Theme.of(context).textTheme.titleMedium!.apply(
                  color: Theme.of(context).colorScheme.primary,
                ),
                duration: kThemeChangeDuration,
                child: Center(
                ),
              ),
            ),
          ),
        ],
      ),
    );
}
