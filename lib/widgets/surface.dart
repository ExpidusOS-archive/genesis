import 'package:flutter/scheduler.dart';
import 'package:libtokyo_flutter/libtokyo.dart' hide ColorScheme;
import 'package:libtokyo/libtokyo.dart' hide TokyoApp;
import 'package:provider/provider.dart';

import '../logic/display.dart';

const kSurfaceDecorHeight = kToolbarHeight / 1.5;

class SurfaceDecor extends StatelessWidget {
  const SurfaceDecor({
    super.key,
    required this.surface,
    this.height = kSurfaceDecorHeight,
    this.onMinimize,
    this.onMaximize,
    this.onClose,
    this.onDrag,
  });

  final DisplayServerSurface surface;
  final double height;
  final VoidCallback? onMinimize;
  final VoidCallback? onMaximize;
  final VoidCallback? onClose;
  final GestureDragUpdateCallback? onDrag;

  @override
  Widget build(BuildContext context) {
    final actions = [
      onMinimize != null
        ? IconButton(
            onPressed: onMinimize!,
            icon: Icon(Icons.windowMinimize),
          ) : null,
      onMaximize != null
        ? IconButton(
            onPressed: onMaximize!,
            icon: Icon(surface.maximized ? Icons.windowRestore : Icons.windowMaximize),
          ) : null,
      onClose != null
        ? IconButton(
            onPressed: onClose!,
            icon: Icon(Icons.circleXmark),
          ) : null,
    ].where((e) => e != null).toList().cast<Widget>();

    Widget value = AppBar(
      automaticallyImplyLeading: false,
      primary: false,
      title: Text(surface.title ?? 'Untitled Window'),
      toolbarHeight: height,
      shape: ContinuousRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      actions: actions.isEmpty
        ? [
            const SizedBox()
          ] : actions,
    );

    if (onDrag != null) {
      value = GestureDetector(
        onPanUpdate: onDrag!,
        child: value,
      );
    }

    return value;
  }

  static double heightFor(BuildContext context) {
    final theme = AppBarTheme.of(context);
    return (theme.toolbarHeight ?? kToolbarHeight) / 1.5;
  }
}

class SurfaceView extends StatefulWidget {
  const SurfaceView({
    super.key,
    required this.surface,
    this.isFocusable = true,
    this.isSizable = true,
    this.buildDecor = null,
  });

  final DisplayServerSurface surface;
  final bool isFocusable;
  final bool isSizable;
  final Widget? Function(BuildContext context, DisplayServerSurface surface, Widget content)? buildDecor;

  @override
  State<SurfaceView> createState() => _SurfaceViewState();
}

class _SurfaceViewState extends State<SurfaceView> {
  GlobalKey key = GlobalKey();

  void _sendSize() {
    if (key.currentContext != null && widget.surface.texture != null && widget.isSizable) {
      final box = key.currentContext!.findRenderObject() as RenderBox;
      widget.surface.setSize(box.size.width.toInt(), box.size.height.toInt());
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
  Widget _buildContent(BuildContext context, DisplayServerSurface surface) {
    Widget content = surface.texture == null
      ? SizedBox() : Texture(
          textureId: surface.texture!,
        );

    if (widget.isFocusable) {
      content = Focus(
        onFocusChange: (isFocused) {
          surface.setActive(isFocused);
          surface.setSuspended(!isFocused);
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
          child: ConstrainedBox(
            constraints: surface.buildBoxConstraints(),
            child: content,
          ),
        ),
      );
    }

    if (surface.size != null) {
      content = SizedBox(
        width: surface.size!.width == null ? null : surface.size!.width!.toDouble(),
        height: surface.size!.height == null ? null : surface.size!.height!.toDouble(),
        child: content,
      );
    }

    if (!surface.hasDecorations && widget.buildDecor != null) {
      content = widget.buildDecor!(context, surface, content) ?? content;
    }
    return content;
  }

  @override
  Widget build(BuildContext context) =>
    ChangeNotifierProvider.value(
      value: widget.surface,
      child: Consumer<DisplayServerSurface>(
        key: key,
        builder: (context, surface, _) => _buildContent(context, surface),
      ),
    );
}
