import 'dart:async';
import 'package:libtokyo_flutter/libtokyo.dart' hide ColorScheme;
import 'package:libtokyo/libtokyo.dart' hide TokyoApp;
import 'package:intl/intl.dart';

class DigitalClock extends StatefulWidget {
  const DigitalClock({
    super.key,
    this.style,
    this.format,
  });

  final TextStyle? style;
  final DateFormat? format;

  @override
  State<DigitalClock> createState() => _DigitalClockState();
}

class _DigitalClockState extends State<DigitalClock> {
  late DateTime currentTime;
  late Timer timer;

  @override
  void initState() {
    super.initState();

    currentTime = DateTime.now();
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        currentTime = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    timer.cancel();
  }

  @override
  Widget build(BuildContext context) =>
    Text(
      (widget.format ?? DateFormat.jm(Localizations.localeOf(context).toString())).format(currentTime),
      style: widget.style,
    );
}
