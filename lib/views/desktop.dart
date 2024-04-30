import 'package:flutter/material.dart';

import '../../widgets/system_layout.dart';

class DesktopView extends StatefulWidget {
  const DesktopView({ super.key });

  @override
  State<DesktopView> createState() => _DesktopViewState();
}

class _DesktopViewState extends State<DesktopView> {
  @override
  Widget build(BuildContext context) =>
    SystemLayout(
      body: Container(),
    );
}
