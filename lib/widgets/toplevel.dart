import 'package:flutter/scheduler.dart';
import 'package:libtokyo_flutter/libtokyo.dart' hide ColorScheme;
import 'package:libtokyo/libtokyo.dart' hide TokyoApp;
import 'package:provider/provider.dart';

import '../logic/display.dart';

class Toplevel extends StatefulWidget {
  const Toplevel({
    super.key,
    required this.toplevel,
  });

  final DisplayServerToplevel toplevel;

  @override
  State<Toplevel> createState() => _ToplevelState();
}

class _ToplevelState extends State<Toplevel> {
  GlobalKey key = GlobalKey();

  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (key.currentContext != null && widget.toplevel.texture != null) {
        final box = key.currentContext!.findRenderObject() as RenderBox;
        widget.toplevel.setSize(box.size.width.toInt(), box.size.height.toInt());
      }
    });
  }

  @override
  Widget build(BuildContext context) =>
    ChangeNotifierProvider(
      key: key,
      create: (_) => widget.toplevel,
      child: Consumer<DisplayServerToplevel>(
        builder: (context, toplevel, _) =>
          toplevel.texture == null
            ? SizedBox() : Texture(
                textureId: toplevel.texture!,
              ),
      ),
    );
}
