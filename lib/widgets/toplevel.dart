import 'package:flutter/scheduler.dart';
import 'package:libtokyo_flutter/libtokyo.dart' hide ColorScheme;
import 'package:libtokyo/libtokyo.dart' hide TokyoApp;
import 'package:provider/provider.dart';

import '../logic/display.dart';

class Toplevel extends StatefulWidget {
  const Toplevel({
    super.key,
    required this.toplevel,
    this.isFocusable = true,
  });

  final DisplayServerToplevel toplevel;
  final bool isFocusable;

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
  Widget buildContent(BuildContext context, DisplayServerToplevel toplevel) {
    Widget content = ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: toplevel.minSize == null ? 0 : (toplevel.minSize!.width ?? 0).toDouble(),
        minHeight: toplevel.minSize == null ? 0 : (toplevel.minSize!.height ?? 0).toDouble(),
        maxWidth: toplevel.maxSize == null ? double.infinity : (toplevel.maxSize!.width ?? double.infinity).toDouble(),
        maxHeight: toplevel.maxSize == null ? double.infinity : (toplevel.maxSize!.height ?? double.infinity).toDouble(),
      ),
      child: toplevel.texture == null
        ? SizedBox() : Texture(
            textureId: toplevel.texture!,
          ),
    );

    if (widget.isFocusable) {
      content = Focus(
        onFocusChange: (isFocused) {
          toplevel.setActive(isFocused);
          toplevel.setSuspended(!isFocused);
        },
        child: content,
      );
    }

    return content;
  }

  @override
  Widget build(BuildContext context) =>
    NotificationListener<SizeChangedLayoutNotification>(
      onNotification: (notif) {
        _sendSize();
        return true;
      },
      child: SizeChangedLayoutNotifier(
        child: ChangeNotifierProvider.value(
          value: widget.toplevel,
          child: Consumer<DisplayServerToplevel>(
            key: key,
            builder: (context, toplevel, _) =>
              toplevel.size != null
                ? SizedBox(
                    width: toplevel.size!.width == null ? null : toplevel.size!.width!.toDouble(),
                    height: toplevel.size!.height == null ? null : toplevel.size!.height!.toDouble(),
                    child: buildContent(context, toplevel),
                  ) : buildContent(context, toplevel),
          ),
        ),
      ),
    );
}
