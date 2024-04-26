import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import '../../widgets/output_layout.dart';
import '../../widgets/system_bar.dart';

class SystemLockView extends StatefulWidget {
  const SystemLockView({ super.key });

  @override
  State<SystemLockView> createState() => _SystemLockViewState();
}

class _SystemLockViewState extends State<SystemLockView> {
  @override
  Widget build(BuildContext context) =>
    OutputLayout(
      builder: (context) =>
        Scaffold(
          appBar: const SystemBar(),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
              ],
            ),
          ),
        ),
    );
}
