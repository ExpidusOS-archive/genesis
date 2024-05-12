import 'package:flutter/services.dart';
import 'package:libtokyo_flutter/libtokyo.dart' hide ColorScheme;
import 'package:libtokyo/libtokyo.dart' hide TokyoApp;
import 'package:provider/provider.dart';

import '../logic/outputs.dart';

class OutputLayout extends StatelessWidget {
  const OutputLayout({
    super.key,
    required this.builder,
  });

  final Widget Function(BuildContext context, Output output, int i) builder;

  @override
  Widget build(BuildContext context) =>
    Consumer<OutputManager>(
      builder: (context, mngr, _) {
        if (mngr.outputs.length == 0) {
          return builder(
            context,
            Output(
              geometry: OutputGeometry(
                width: MediaQuery.of(context).size.width.toInt(),
                height: MediaQuery.of(context).size.height.toInt(),
              ), 
            ),
            0
          );
        }

        return Stack(
          children: mngr.outputs.asMap().entries.map(
            (entry) =>
              Transform.translate(
                offset: Offset(
                  (entry.value.geometry.x * entry.value.scale).toDouble(),
                  (entry.value.geometry.y * entry.value.scale).toDouble(),
                ),
                child: SizedBox(
                  width: (entry.value.geometry.width * entry.value.scale).toDouble(),
                  height: (entry.value.geometry.height * entry.value.scale).toDouble(),
                  child: Builder(
                    builder: (context) =>
                      builder(context, entry.value, entry.key),
                  ),
                ),
              )
          ).toList(),
        );
      },
    );
}
