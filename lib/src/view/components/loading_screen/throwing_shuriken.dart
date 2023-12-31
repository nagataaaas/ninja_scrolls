import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ninja_scrolls/extentions.dart';
import 'package:ninja_scrolls/navkey.dart';

Future<bool> createThrowingShuriken(Completer<void> completer) async {
  final Completer<bool> successCompleter = Completer<bool>();
  bool popped = false;

  showDialog<void>(
    context: rootNavigatorKey.currentContext!,
    builder: (context) {
      return WillPopScope(
        onWillPop: () async {
          if (!successCompleter.isCompleted) successCompleter.complete(false);
          if (!popped) {
            popped = true;
            Navigator.of(context, rootNavigator: true).pop();
          }
          return true;
        },
        child: GestureDetector(
            onTap: () {
              if (!successCompleter.isCompleted) {
                successCompleter.complete(false);
              }
              if (!popped) {
                popped = true;
                Navigator.of(context, rootNavigator: true).pop();
              }
            },
            child: ThrowingShuriken(
                completer: completer,
                onAnimationFinished: () {
                  if (!successCompleter.isCompleted) {
                    successCompleter.complete(true);
                  }
                  if (!popped) {
                    popped = true;
                    Navigator.of(context, rootNavigator: true).pop();
                  }
                })),
      );
    },
  );

  return await successCompleter.future;
}

class ThrowingShuriken extends StatefulWidget {
  final Completer<void> completer;
  final Function? onAnimationFinished;
  const ThrowingShuriken(
      {super.key, required this.completer, this.onAnimationFinished});

  @override
  State<ThrowingShuriken> createState() => _ThrowingShurikenState();
}

class _ThrowingShurikenState extends State<ThrowingShuriken>
    with TickerProviderStateMixin {
  late final AnimationController _slideInController;
  Animation<double>? _slideInAnimation;
  late final AnimationController _loadingController;
  late final Animation<double> _loadingAnimation;
  late final AnimationController _loadedController;
  late final Animation<double> _loadedAnimation;
  late final AnimationController _loadedShurikenController;
  late final Animation<double> _loadedShurikenAlongArmRotateAnimation;
  late final AnimationController _loadedShurikenRotateController;
  Animation<Offset>? _loadedShurikenFlyAnimation;
  final lastAngle = (2.0 * math.pi) / 360 * -80;
  final throwingIntervalSleep = Duration(milliseconds: 100);
  bool toIsLoaded = false;
  bool isLoaded = false;
  static const beginningAngleRatio = 0.1;

  AnimationController get controller =>
      isLoaded ? _loadedController : _loadingController;
  AnimationController get shurikenController =>
      isLoaded ? _loadedShurikenController : _loadingController;
  Animation<double> get animation =>
      isLoaded ? _loadedAnimation : _loadingAnimation;

  Animation<double> get shurikenAlongArmRotateAnimation =>
      isLoaded ? _loadedShurikenAlongArmRotateAnimation : _loadingAnimation;

  @override
  void initState() {
    super.initState();
    widget.completer.future.then((value) {
      setState(() {
        toIsLoaded = true;
      });
    });

    _slideInController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    )..addStatusListener((AnimationStatus status) {
        if (status == AnimationStatus.completed) {
          if (!isLoaded) _loadingController.reverse();
        } else if (status == AnimationStatus.dismissed) {
          Future.delayed(throwingIntervalSleep, () {
            if (toIsLoaded) {
              setState(() {
                isLoaded = true;
              });
              _loadedController.forward();
              _loadedShurikenController.forward();
              _loadedShurikenRotateController.repeat();
              return;
            }
            _loadingController.forward();
          });
        }
      });
    _loadingAnimation = Tween<double>(begin: beginningAngleRatio, end: 0.8)
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(_loadingController);

    _loadedController = AnimationController(
        duration: const Duration(milliseconds: 300), vsync: this);
    _loadedAnimation = Tween<double>(begin: beginningAngleRatio, end: 1)
        .chain(CurveTween(curve: Curves.easeOutBack))
        .animate(_loadedController);

    _loadedShurikenController = AnimationController(
        duration: const Duration(milliseconds: 400), vsync: this)
      ..addStatusListener((AnimationStatus status) {
        if (status == AnimationStatus.completed) {
          widget.onAnimationFinished?.call();
        }
      });
    _loadedShurikenAlongArmRotateAnimation = TweenSequence([
      TweenSequenceItem<double>(
        tween: Tween<double>(
                begin: beginningAngleRatio, end: (1 + beginningAngleRatio) / 2)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 1,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(
            begin: (1 + beginningAngleRatio) / 2,
            end: (1 + beginningAngleRatio) / 2),
        weight: 16,
      ),
    ]).animate(_loadedShurikenController);
    _loadedShurikenRotateController = AnimationController(
        duration: const Duration(milliseconds: 300), vsync: this);
  }

  void afterShown() {
    isLoaded = widget.completer.isCompleted;
    if (isLoaded) {
      setState(() {});
      _loadedController.forward();
      _loadedShurikenController.forward();
      _loadedShurikenRotateController.repeat();
      return;
    }
    _loadingController.forward();
  }

  @override
  void dispose() {
    _slideInController.dispose();
    _loadingController.dispose();
    _loadedController.dispose();
    _loadedShurikenController.dispose();
    _loadedShurikenRotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = context.screenHeight / 3;
    final armWidth = height / 10 * 4;
    final shurikenWidth = armWidth / 40 * 21;

    _slideInAnimation ??= Tween<double>(begin: armWidth, end: 0)
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(_slideInController)
      ..addStatusListener((AnimationStatus status) {
        if (status == AnimationStatus.completed) afterShown();
      });
    _slideInController.forward();

    if (context.screenWidth > 0.0) {
      _loadedShurikenFlyAnimation ??= TweenSequence([
        TweenSequenceItem<Offset>(
          tween: Tween<Offset>(
            begin: Offset.zero,
            end: Offset.zero,
          ),
          weight: 1,
        ),
        TweenSequenceItem<Offset>(
          tween: Tween<Offset>(
            begin: Offset.zero,
            end: Offset(-context.screenWidth, 0),
          ),
          weight: 16,
        ),
      ]).animate(_loadedShurikenController);
    }
    return AnimatedBuilder(
      animation: _slideInController,
      builder: (BuildContext context, Widget? child) {
        return Transform.translate(
          offset: Offset(_slideInAnimation!.value, 0),
          child: child,
        );
      },
      child: SizedBox(
        height: context.screenHeight,
        width: context.screenWidth,
        child: Stack(
          alignment: Alignment.centerRight,
          children: [
            SizedBox(
              height: height,
              width: armWidth,
              child: Transform.translate(
                offset: Offset(armWidth * 0.7, 0),
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    AnimatedBuilder(
                      animation: controller,
                      child:
                          Image.asset('assets/loading_arm.png', height: height),
                      builder: (BuildContext context, Widget? child) {
                        return Transform.rotate(
                          alignment: Alignment.topLeft,
                          origin: Offset(armWidth * 0.5, height * 0.85),
                          angle: animation.value * lastAngle,
                          child: child,
                        );
                      },
                    ),
                    AnimatedBuilder(
                      animation: _loadedShurikenController,
                      builder: (context, Widget? child) {
                        return Transform.translate(
                            offset: _loadedShurikenFlyAnimation?.value ??
                                Offset.zero,
                            child: child);
                      },
                      child: AnimatedBuilder(
                        animation: shurikenController,
                        builder: (BuildContext context, Widget? child) {
                          return Transform.rotate(
                            alignment: Alignment.topLeft,
                            origin: Offset(shurikenWidth * 0.5, height * 0.85),
                            angle: shurikenAlongArmRotateAnimation.value *
                                lastAngle,
                            child: child,
                          );
                        },
                        child: Transform.translate(
                          offset: Offset(
                              shurikenWidth * 0.95, -shurikenWidth * 0.23),
                          child: AnimatedBuilder(
                              animation: _loadedShurikenRotateController,
                              child: Image.asset('assets/loading_shuriken.png',
                                  width: shurikenWidth),
                              builder: (context, Widget? child) {
                                return Transform.rotate(
                                    angle:
                                        _loadedShurikenRotateController.value *
                                            math.pi *
                                            -2,
                                    child: child);
                              }),
                        ),
                      ),
                    ),
                    AnimatedBuilder(
                      animation: controller,
                      child: Image.asset('assets/loading_thumb.png',
                          width: armWidth),
                      builder: (BuildContext context, Widget? child) {
                        return Transform.rotate(
                          alignment: Alignment.topLeft,
                          origin: Offset(armWidth * 0.5, height * 0.85),
                          angle: animation.value * lastAngle,
                          child: child,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
