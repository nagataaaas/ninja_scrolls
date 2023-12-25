import 'dart:math' as math;

import 'package:flutter/material.dart';

class DripProgression {
  final double startAt;
  final double endAt;
  final double centerX;

  DripProgression({
    required this.startAt,
    required this.endAt,
    required this.centerX,
  });

  // create List<DripProgression> from width and dripCount
  static List<DripProgression> fromCount({
    required double width,
    required int dripCount,
  }) {
    final dripProgressions = <DripProgression>[];
    final dripWidth = width / dripCount;
    for (var i = 0; i <= dripCount; i++) {
      dripProgressions.add(DripProgression(
        startAt: randomIntWithRange(0, 300) / 1000.0,
        endAt: randomIntWithRange(700, 1000) / 1000.0,
        centerX: dripWidth * i,
      ));
    }
    return dripProgressions;
  }

  double calcDrip(double current) {
    if (current < startAt) {
      return 0;
    }
    if (current > endAt) {
      return 1;
    }
    return (current - startAt) / (endAt - startAt);
  }
}

class PathAnimation extends CustomClipper<Path> {
  final List<DripProgression> dripProgressions;
  double move = 0.0;

  PathAnimation({
    required this.dripProgressions,
    this.move = 0.0,
  });

  @override
  getClip(Size size) {
    Path path = Path();
    final width = size.width;
    final height = size.height * 1.2;
    if (move == 0.0) {
      return path..addRect(const Rect.fromLTWH(0, 0, 0, 0));
    }
    if (move == 1.0) {
      return path..addRect(Rect.fromLTWH(width, height, width, height));
    }

    if (move < 0.5) {
      final cMove = move * 2;
      // start from top left
      path.lineTo(0, dripProgressions[0].calcDrip(cMove) * height);

      for (var i = 1; i < dripProgressions.length; i++) {
        final before = dripProgressions[i - 1];
        final current = dripProgressions[i];

        // connect all the dots with a cubic curve
        path.cubicTo(
          current.centerX,
          before.calcDrip(cMove) * height,
          before.centerX,
          current.calcDrip(cMove) * height,
          current.centerX,
          current.calcDrip(cMove) * height,
        );
      }

      path.lineTo(width, 0);
      path.lineTo(0, 0);
      path.close();
    } else {
      final cMove = (move - 0.5) * 2;
      // start from top left
      path.lineTo(0, dripProgressions[0].calcDrip(cMove) * height);

      for (var i = 1; i < dripProgressions.length; i++) {
        final before = dripProgressions[i - 1];
        final current = dripProgressions[i];

        // connect all the dots with a cubic curve
        path.cubicTo(
          current.centerX,
          before.calcDrip(cMove) * height,
          before.centerX,
          current.calcDrip(cMove) * height,
          current.centerX,
          current.calcDrip(cMove) * height,
        );
      }

      path.lineTo(width, height);
      path.lineTo(0, height);
      path.close();
    }

    return path;
  }

  @override
  bool shouldReclip(CustomClipper oldClipper) {
    return move != 0.0 && move != 1.0;
  }
}

int randomIntWithRange(int min, int max) {
  int value = math.Random().nextInt(max - min);
  return value + min;
}
