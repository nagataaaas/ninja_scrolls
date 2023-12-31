import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ninja_scrolls/extentions.dart';
import 'package:ninja_scrolls/src/providers/user_settings_provider.dart';
import 'package:ninja_scrolls/src/transitions/path_animation.dart';
import 'package:provider/provider.dart';

CustomTransitionPage<void> buildLiquidTransitionPage({
  required BuildContext context,
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
  if (!context.read<UserSettingsProvider>().richAnimationEnabled) {
    return CustomTransitionPage<void>(
        child: child,
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
        transitionsBuilder: (
          context,
          animation,
          secondaryAnimation,
          child,
        ) {
          if (Platform.isAndroid) {
            return FadeUpwardsPageTransitionsBuilder().buildTransitions(
                null, context, animation, secondaryAnimation, child);
          } else if (Platform.isIOS) {
            CupertinoPageTransition(
              primaryRouteAnimation: animation,
              secondaryRouteAnimation: secondaryAnimation,
              linearTransition: true,
              child: child,
            );
          }
          return child;
        });
  }

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
    transitionsBuilder: (context, animation, secondaryAnimation, child1) {
      dripProgressions ??= DripProgression.fromCount(
          width: context.screenWidth, dripCount: context.screenWidth ~/ 20);

      return AnimatedBuilder(
        animation: animation,
        child: child1,
        builder: (context, child2) {
          return Stack(
            children: [
              Opacity(opacity: animation.value > 0.5 ? 1 : 0, child: child2!),
              Visibility(
                  visible: animation.value != 0.0 && animation.value != 1.0,
                  child: ClipPath(
                    clipBehavior: Clip.antiAliasWithSaveLayer,
                    clipper: PathAnimation(
                        dripProgressions: dripProgressions!,
                        move: animation.value),
                    child: Container(color: Colors.red),
                  ))
            ],
          );
        },
      );
    },
  );
}
