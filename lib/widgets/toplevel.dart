import 'package:flutter/scheduler.dart';
import 'package:libtokyo_flutter/libtokyo.dart' hide ColorScheme;
import 'package:libtokyo/libtokyo.dart' hide TokyoApp;
import 'package:provider/provider.dart';

import '../logic/display.dart';

class ToplevelView extends StatefulWidget {
  const ToplevelView({
    super.key,
    required this.toplevel,
    this.isFocusable = true,
    this.isSizable = true,
    this.buildDecor = null,
  });

  final DisplayServerToplevel toplevel;
  final bool isFocusable;
  final bool isSizable;
  final Widget? Function(BuildContext context, DisplayServerToplevel toplevel, Widget content)? buildDecor;

  @override
  State<ToplevelView> createState() => _ToplevelViewState();
}

class _ToplevelViewState extends State<ToplevelView> {
  GlobalKey key = GlobalKey();

  void _sendSize() {
    if (key.currentContext != null && widget.toplevel.texture != null && widget.isSizable) {
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
  Widget _buildContent(BuildContext context, DisplayServerToplevel toplevel) {
    Widget content = ConstrainedBox(
      constraints: toplevel.buildBoxConstraints(),
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

    if (widget.isSizable) {
      content = NotificationListener<SizeChangedLayoutNotification>(
        onNotification: (notif) {
          _sendSize();
          return true;
        },
        child: SizeChangedLayoutNotifier(
          child: content,
        ),
      );
    }

    if (toplevel.size != null) {
      content = SizedBox(
        width: toplevel.size!.width == null ? null : toplevel.size!.width!.toDouble(),
        height: toplevel.size!.height == null ? null : toplevel.size!.height!.toDouble(),
        child: content,
      );
    }

    if (!toplevel.hasDecorations && widget.buildDecor != null) {
      content = widget.buildDecor!(context, toplevel, content) ?? content;
    }
    return content;
  }

  @override
  Widget build(BuildContext context) =>
    ChangeNotifierProvider.value(
      value: widget.toplevel,
      child: Consumer<DisplayServerToplevel>(
        key: key,
        builder: (context, toplevel, _) => _buildContent(context, toplevel),
      ),
    );
}
