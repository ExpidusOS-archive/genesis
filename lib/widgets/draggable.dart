import 'package:libtokyo_flutter/libtokyo.dart' hide ColorScheme;
import 'package:libtokyo/libtokyo.dart' hide TokyoApp;

class VerticalDragContainer extends StatefulWidget {
  final double minHeight;
  final double startHeight;
  final double expandedHeight;
  final Widget child;
  final VoidCallback? onExpanded;
  final VoidCallback? onUnexpanded;
  final Widget Function(BuildContext context, bool isExpanded) handleBuilder;

  const VerticalDragContainer({
    required this.startHeight,
    required this.minHeight,
    required this.child,
    required this.handleBuilder,
    required this.expandedHeight,
    this.onExpanded = null,
    this.onUnexpanded = null,
  });

  @override
  State<VerticalDragContainer> createState() => _VerticalDragContainerState();
}

class _VerticalDragContainerState extends State<VerticalDragContainer> {
  var _currentHeight;
  var _startHeight;
  var _startDy;

  @override
  void initState() {
    super.initState();
    _currentHeight = widget.startHeight;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _currentHeight,
      child: Column(
        children: <Widget>[
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              if (_currentHeight <= widget.minHeight) {
                setState(() {
                  _currentHeight = widget.expandedHeight;
                  if (widget.onExpanded != null) widget.onExpanded!();
                });
              } else {
                setState(() {
                  _currentHeight = widget.minHeight;
                  if (widget.onUnexpanded != null) widget.onUnexpanded!();
                });
              }
            },
            onVerticalDragStart: (s) {
              _startDy = s.globalPosition.dy;
              _startHeight = _currentHeight;
            },
            onVerticalDragUpdate: (a) {
              var _currentDy = a.globalPosition.dy;
              var newHeight = _startDy - _currentDy;
              setState(() {
                if ((_startHeight + newHeight) >= widget.minHeight) {
                  _currentHeight = (_startHeight + newHeight);
                } else {
                  _currentHeight = widget.minHeight;
                  if (widget.onUnexpanded != null) widget.onUnexpanded!();
                }
              });
            },
            onVerticalDragEnd: (_) {
              setState(() {
                if (_currentHeight > widget.minHeight) {
                  _currentHeight = widget.expandedHeight;
                  if (widget.onExpanded != null) widget.onExpanded!();
                }
              });
            },
            child: widget.handleBuilder(context, _currentHeight > widget.minHeight),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: SizedBox(
                height: widget.expandedHeight - (widget.minHeight + 7),
                child: widget.child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
