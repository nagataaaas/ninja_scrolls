import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ninja_scrolls/src/static/colors.dart';

void main() {
  group('ColorEx.darken', () {
    test('amount=0 returns same color', () {
      const color = Color(0xFF8080FF);
      expect(color.darken(0), color);
    });

    test('amount=1.0 returns black with same alpha', () {
      const color = Color(0xFF8080FF);
      final result = color.darken(1.0);
      expect((result.r * 255).round(), 0);
      expect((result.g * 255).round(), 0);
      expect((result.b * 255).round(), 0);
      expect(result.a, color.a);
    });

    test('default amount (.1) reduces lightness', () {
      const color = Color(0xFFCCCCCC);
      final result = color.darken();
      final originalHsl = HSLColor.fromColor(color);
      final resultHsl = HSLColor.fromColor(result);
      expect(resultHsl.lightness, lessThan(originalHsl.lightness));
    });

    test('preserves alpha channel', () {
      const color = Color(0x808080FF);
      final result = color.darken(0.2);
      expect(result.a, color.a);
    });

    test('lightness clamps to 0 for very large amount', () {
      const color = Color(0xFF333333);
      final result = color.darken(0.95);
      final resultHsl = HSLColor.fromColor(result);
      expect(resultHsl.lightness, closeTo(0.0, 0.01));
    });
  });

  group('ColorEx.lighten', () {
    test('amount=0 returns same color', () {
      const color = Color(0xFF8080FF);
      expect(color.lighten(0), color);
    });

    test('amount=1.0 returns white with same alpha', () {
      const color = Color(0xFF8080FF);
      final result = color.lighten(1.0);
      expect((result.r * 255).round(), 255);
      expect((result.g * 255).round(), 255);
      expect((result.b * 255).round(), 255);
      expect(result.a, color.a);
    });

    test('default amount (.1) increases lightness', () {
      const color = Color(0xFF333333);
      final result = color.lighten();
      final originalHsl = HSLColor.fromColor(color);
      final resultHsl = HSLColor.fromColor(result);
      expect(resultHsl.lightness, greaterThan(originalHsl.lightness));
    });

    test('preserves alpha channel', () {
      const color = Color(0x80333333);
      final result = color.lighten(0.2);
      expect(result.a, color.a);
    });

    test('lightness clamps to 1 for very large amount', () {
      const color = Color(0xFFCCCCCC);
      final result = color.lighten(0.95);
      final resultHsl = HSLColor.fromColor(result);
      expect(resultHsl.lightness, closeTo(1.0, 0.01));
    });
  });

  group('ColorEx.blend', () {
    test('amount=0 returns original color', () {
      const color = Color(0xFFFF0000);
      const other = Color(0xFF0000FF);
      final result = color.blend(other, 0);
      expect(result, color);
    });

    test('amount=1 returns other color', () {
      const color = Color(0xFFFF0000);
      const other = Color(0xFF0000FF);
      final result = color.blend(other, 1);
      expect(result, other);
    });

    test('amount=0.5 returns midpoint color', () {
      const color = Color(0xFFFF0000);
      const other = Color(0xFF0000FF);
      final result = color.blend(other, 0.5);
      // midpoint between red and blue
      expect((result.r * 255).round(), closeTo(128, 1));
      expect((result.g * 255).round(), 0);
      expect((result.b * 255).round(), closeTo(128, 1));
    });
  });

  group('Common colors', () {
    test('Common constants are defined', () {
      expect(Common.black, const Color(0xFF000000));
      expect(Common.white, const Color(0xFFFFFFFF));
      expect(Common.accent, const Color.fromARGB(255, 255, 39, 39));
    });
  });
}
