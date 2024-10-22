import 'package:flutter/services.dart';
import 'package:libtokyo_flutter/libtokyo.dart' hide ColorScheme;
import 'package:libtokyo/libtokyo.dart' hide TokyoApp;
import 'package:provider/provider.dart';

import '../logic/outputs.dart';
import '../logic/theme.dart';

class OutputLayout extends StatelessWidget {
  const OutputLayout({
    super.key,
    required this.builder,
  });

  final Widget Function(BuildContext context, Output output, int i, bool shouldScale) builder;

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
              size: OutputSize(),
            ),
            0, false
          );
        }

        final toplevelSize = MediaQuery.of(context).size;
        return Stack(
          children: mngr.outputs.asMap().entries.map(
            (entry) {
              final size = Size(entry.value.geometry.width.toDouble(), entry.value.geometry.height.toDouble());

              Widget widget = Builder(
                builder: (context) =>
                  builder(context, entry.value, entry.key, size <= toplevelSize),
              );

              if (size <= toplevelSize) {
                widget = MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    devicePixelRatio: 1.0,
                    size: size,
                  ),
                  child: Theme(
                    data: scaleThemeFor(Theme.of(context), entry.value.applyScale),
                    child: widget,
                  ),
                );
              }

              return Transform.translate(
                offset: Offset(
                  entry.value.geometry.x.toDouble(),
                  entry.value.geometry.y.toDouble(),
                ),
                child: SizedBox(
                  width: entry.value.geometry.width.toDouble(),
                  height: entry.value.geometry.height.toDouble(),
                  child: widget,
                ),
              );
            }
          ).toList(),
        );
      },
    );
}
