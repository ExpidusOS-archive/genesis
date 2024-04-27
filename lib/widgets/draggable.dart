import 'package:flutter/material.dart';

class VerticalDragContainer extends StatefulWidget {
  final double minHeight;
  final double startHeight;
  final double expandedHeight;
  final Widget child;
  final Widget handle;
  final Color backgroundColor;

  const VerticalDragContainer(
      {required this.startHeight,
      required this.minHeight,
      required this.child,
      required this.handle,
      required this.expandedHeight,
      this.backgroundColor = Colors.white,});

  _VerticalDragContainerState createState() => _VerticalDragContainerState();
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
      color: widget.backgroundColor,
      height: _currentHeight,
      child: Column(
        children: <Widget>[
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              if (_currentHeight <= widget.minHeight) {
                setState(() {
                  _currentHeight = widget.expandedHeight;
                });
              } else {
                setState(() {
                  _currentHeight = widget.minHeight;
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
                }
              });
            },
            child: widget.handle,
          ),

          Expanded(
              child: SingleChildScrollView(
            child: widget.child,
          ))
        ],
      ),
    );
  }
}
