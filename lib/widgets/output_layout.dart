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

        final toplevelSize = MediaQuery.of(context).size;
        return Stack(
          children: mngr.outputs.asMap().entries.map(
            (entry) {
              final size = Size(entry.value.geometry.width.toDouble(), entry.value.geometry.height.toDouble());

              Widget widget = Transform.translate(
                offset: Offset(
                  (entry.value.geometry.x * entry.value.scale).toDouble(),
                  (entry.value.geometry.y * entry.value.scale).toDouble(),
                ),
                child: SizedBox(
                  width: entry.value.geometry.width.toDouble(),
                  height: entry.value.geometry.height.toDouble(),
                  child: AspectRatio(
                    aspectRatio: entry.value.geometry.width.toDouble() / entry.value.geometry.height.toDouble(),
                    child: size < toplevelSize
                      ? Transform.scale(
                          scale: entry.value.scale.toDouble(),
                          child: Builder(
                            builder: (context) =>
                              builder(context, entry.value, entry.key),
                          ),
                        ) : Builder(
                          builder: (context) =>
                            builder(context, entry.value, entry.key),
                        ),
                  ),
                ),
              );

              if (toplevelSize >= size) {
                widget = MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    size: size,
                  ),
                  child: widget,
                );
              }
              return widget;
            }
          ).toList(),
        );
      },
    );
}
