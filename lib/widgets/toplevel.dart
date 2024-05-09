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

  void _sendSize() {
    if (key.currentContext != null && widget.toplevel.texture != null) {
      final box = key.currentContext!.findRenderObject() as RenderBox;
      widget.toplevel.setSize(box.size.width.toInt(), box.size.height.toInt());
    }
  }

  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance.addPostFrameCallback((_) {
      _sendSize();
    });
  }

  @override
  Widget buildContent(BuildContext context, DisplayServerToplevel toplevel) =>
    toplevel.texture == null
      ? SizedBox() : Texture(
          textureId: toplevel.texture!,
        );

  @override
  Widget build(BuildContext context) =>
    NotificationListener<SizeChangedLayoutNotification>(
      onNotification: (notif) {
        _sendSize();
        return true;
      },
      child: SizeChangedLayoutNotifier(
        child: ChangeNotifierProvider(
          create: (_) => widget.toplevel,
          child: Consumer<DisplayServerToplevel>(
            key: key,
            builder: (context, toplevel, _) =>
              toplevel.size != null
                ? SizedBox(
                    width: toplevel.size!.width.toDouble(),
                    height: toplevel.size!.height.toDouble(),
                    child: buildContent(context, toplevel),
                  ) : buildContent(context, toplevel),
          ),
        ),
      ),
    );
}
