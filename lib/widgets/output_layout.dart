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

  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) =>
    Consumer<OutputManager>(
      builder: (context, mngr, _) {
        if (mngr.outputs.length == 0) {
          return builder(context);
        }

        return Stack(
          children: mngr.outputs.map(
            (output) =>
              Transform.translate(
                offset: Offset(
                  (output.geometry.x * output.scale).toDouble(),
                  (output.geometry.y * output.scale).toDouble(),
                ),
                child: SizedBox(
                  width: (output.geometry.width * output.scale).toDouble(),
                  height: (output.geometry.height * output.scale).toDouble(),
                  child: Builder(builder: builder),
                ),
              )
          ).toList(),
        );
      },
    );
}
