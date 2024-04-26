import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OutputLayout extends StatefulWidget {
  const OutputLayout({
    super.key,
    required this.builder,
  });

  final WidgetBuilder builder;

  @override
  State<OutputLayout> createState() => _OutputLayoutState();
}

class _OutputLayoutState extends State<OutputLayout> {
  static const platform = MethodChannel('com.expidusos.genesis.shell/outputs');

  @override
  Widget build(BuildContext context) =>
    FutureBuilder(
      future: platform.invokeListMethod('list'),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Stack(
            children: snapshot.data!.map(
              (dynamic output) {
                final scale = output['scale'] as int;
                return Transform.translate(
                  offset: Offset(
                    ((output['geometry']['x'] as int) * scale).toDouble(),
                    ((output['geometry']['x'] as int) * scale).toDouble()
                  ),
                  child: SizedBox(
                    width: ((output['geometry']['width'] as int) * scale).toDouble(),
                    height: ((output['geometry']['height'] as int) * scale).toDouble(),
                    child: Builder(builder: widget.builder),
                  ),
                );
              }
            ).toList(),
          );
        }

        if (snapshot.hasError) {
          print(snapshot.error);
        }
        return widget.builder(context);
      },
    );
}
