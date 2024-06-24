import 'package:flutter/material.dart';

class SwipeToPopContainer extends StatefulWidget {
  final Widget child;
  final bool enabled;
  const SwipeToPopContainer(
      {super.key, required this.enabled, required this.child});

  @override
  State<SwipeToPopContainer> createState() => _SwipeToPopContainerState();
}

class _SwipeToPopContainerState extends State<SwipeToPopContainer> {
  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        if (details.primaryDelta! >= 8 && details.globalPosition.dx < 150) {
          Navigator.of(context).pop();
        }
      },
      child: widget.child,
    );
  }
}
