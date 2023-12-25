import 'package:flutter/material.dart';
import 'package:ninja_scrolls/src/transitions/path_animation.dart';

class LiquidTransition extends StatefulWidget {
  final List<Widget> pages;
  final Duration animationDuration;
  final Duration pauseDuration;
  final Function(int) onTransitionStarts;
  const LiquidTransition({
    super.key,
    required this.pages,
    required this.animationDuration,
    required this.pauseDuration,
    required this.onTransitionStarts,
  });

  @override
  State<LiquidTransition> createState() => _LiquidTransitionState();
}

class _LiquidTransitionState extends State<LiquidTransition>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late PathAnimation _pathAnimation;
  List<DripProgression>? _dripProgressions;

  int currentPage = 0;
  bool showFrom = true;
  bool showTo = false;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.pages.length - 1,
      (index) {
        final controller = AnimationController(
          value: 0.0,
          duration: widget.animationDuration + widget.pauseDuration,
          vsync: this,
        );
        controller.addStatusListener((AnimationStatus status) {
          if (status == AnimationStatus.completed) {
            setState(() {
              currentPage += 1;
              showTo = false;
            });
            controller.reset();
          }
        });
        return controller;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    _dripProgressions ??= DripProgression.fromCount(
      width: MediaQuery.of(context).size.width,
      dripCount: 12,
    );
    final pages = [];
    widget.pages.skip(1).toList().asMap().forEach((index, page) {
      index += 1;
      pages.add(
        Visibility(
          visible:
              currentPage == index || ((currentPage + 1 == index) && showTo),
          child: Positioned(
            top: 0,
            left: 0,
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: AnimatedBuilder(
                animation: _controllers[index - 1],
                builder: (context, child) {
                  return ClipPath(
                    clipBehavior: Clip.antiAliasWithSaveLayer,
                    clipper: PathAnimation(
                        dripProgressions: _dripProgressions!,
                        move: _controllers[index - 1].value),
                    child: page,
                  );
                },
              ),
            ),
          ),
        ),
      );
    });

    return GestureDetector(
      onTap: () {
        if (_controllers[currentPage].status == AnimationStatus.dismissed &&
            currentPage < widget.pages.length - 1) {
          widget.onTransitionStarts(currentPage);
          setState(() {
            showTo = true;
          });
          _controllers[currentPage].forward();
        }
      },
      child: AbsorbPointer(
        child: Stack(
          children: [
            if (currentPage == 0)
              Positioned(
                top: 0,
                left: 0,
                child: widget.pages[0],
              ),
            ...pages
          ],
        ),
      ),
    );
  }
}
