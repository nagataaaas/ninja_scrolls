// Flutter imports:
import 'package:flutter/material.dart';

class Common {
  static const black = Color(0xFF000000);
  static const grey1 = Color(0xFF4F4F4F);
  static const grey2 = Color(0xFF828282);
  static const grey3 = Color(0xFF606060);
  static const lightGrey1 = Color(0xFFBDBDBD);
  static const lightGrey2 = Color(0xFFE4E4E4);
  static const light = Color(0xFFFAFAFA);
  static const accent = Color.fromARGB(255, 255, 39, 39);
  static const white = Color(0xFFFFFFFF);
  static const peach = Color(0xFFFF8597);
  static const lightPink = Color(0xFFE885AF);
  static const errorRed = Color(0xFFFF5252);
  static const linkBlue = Color(0xFF00B3FF);
  static const actionBlue = Color.fromARGB(255, 0, 119, 255);
  static const lightBlueGrey = Color(0xFFF1F5F8);
  static const blueGrey = Color(0xFFD0DEEB);
  static const darkBlueGrey = Color(0xFF9BA9B9);
  static const mintGreen = Color(0xFF13C39C);
  static const limeGreen = Color(0xFF6ED25E);
}

extension ColorEx on Color {
  Color darken([double amount = .1]) {
    if (amount == 0) return this;
    if (amount == 1.0) return Colors.black.withAlpha(alpha);

    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));

    return hslDark.toColor().withAlpha(alpha);
  }

  Color lighten([double amount = .1]) {
    if (amount == 0) return this;
    if (amount == 1.0) return Colors.white.withAlpha(alpha);

    final hsl = HSLColor.fromColor(this);
    final hslLight =
        hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));

    return hslLight.toColor().withAlpha(alpha);
  }

  Color blend(Color other, double amount) {
    return Color.lerp(this, other, amount)!;
  }
}
