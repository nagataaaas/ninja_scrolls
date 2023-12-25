import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ninja_scrolls/extentions.dart';
import 'package:ninja_scrolls/src/transitions/path_animation.dart';

CustomTransitionPage<void> buildLiquidTransitionPage({
  required Widget child,
  Duration transitionDuration = const Duration(milliseconds: 300),
  Duration reverseTransitionDuration = const Duration(milliseconds: 300),
  bool maintainState = true,
  bool fullscreenDialog = false,
  bool opaque = true,
  bool barrierDismissible = false,
  Color? barrierColor,
  String? barrierLabel,
  LocalKey? key,
  String? name,
  Object? arguments,
  String? restorationId,
}) {
  List<DripProgression>? dripProgressions;

  return CustomTransitionPage<void>(
    child: child,
    transitionDuration: transitionDuration,
    reverseTransitionDuration: reverseTransitionDuration,
    maintainState: maintainState,
    fullscreenDialog: fullscreenDialog,
    opaque: opaque,
    barrierDismissible: barrierDismissible,
    barrierColor: barrierColor,
    barrierLabel: barrierLabel,
    key: key,
    name: name,
    arguments: arguments,
    restorationId: restorationId,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      dripProgressions ??= DripProgression.fromCount(
          width: context.screenWidth, dripCount: context.screenWidth ~/ 20);

      return AnimatedBuilder(
        animation: animation,
        child: child,
        builder: (context, child) {
          return Stack(
            children: [
              if (animation.value > 0.5) child!,
              ClipPath(
                clipBehavior: Clip.antiAliasWithSaveLayer,
                clipper: PathAnimation(
                    dripProgressions: dripProgressions!, move: animation.value),
                child: Container(color: Colors.red),
              ),
            ],
          );
        },
      );
    },
  );
}
