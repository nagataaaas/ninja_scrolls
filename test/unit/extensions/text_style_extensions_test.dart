import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ninja_scrolls/extentions.dart';

void main() {
  group('TextStyleExt.lineHeightPixel', () {
    test('null TextStyle returns null', () {
      const TextStyle? nullStyle = null;
      expect(nullStyle.lineHeightPixel, isNull);
    });

    test('fontSize null returns null', () {
      const TextStyle style = TextStyle();
      expect(style.lineHeightPixel, isNull);
    });

    test('height null returns fontSize', () {
      const TextStyle style = TextStyle(fontSize: 16.0);
      expect(style.lineHeightPixel, 16.0);
    });

    test('both fontSize and height returns fontSize * height', () {
      const TextStyle style = TextStyle(fontSize: 16.0, height: 1.5);
      expect(style.lineHeightPixel, 24.0);
    });

    test('fontSize=20 height=2.0 returns 40', () {
      const TextStyle style = TextStyle(fontSize: 20.0, height: 2.0);
      expect(style.lineHeightPixel, 40.0);
    });
  });

  group('ThemeDataSettingsThemeDataExt.settingsThemeData', () {
    test('maps colorScheme fields correctly', () {
      final themeData = ThemeData(
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF112233),
          surface: Color(0xFFAABBCC),
        ),
      );

      final settingsTheme = themeData.settingsThemeData;

      expect(settingsTheme.trailingTextColor, themeData.colorScheme.primary);
      expect(settingsTheme.settingsListBackground, themeData.colorScheme.surface);
      expect(settingsTheme.settingsSectionBackground, themeData.colorScheme.surface);
      expect(settingsTheme.titleTextColor, themeData.colorScheme.primary);
      expect(settingsTheme.leadingIconsColor, themeData.colorScheme.primary);
      expect(settingsTheme.settingsTileTextColor, themeData.colorScheme.primary);
    });

    test('opacity values are correct for divider, tileHighlight, tileDescription', () {
      final themeData = ThemeData(
        colorScheme: const ColorScheme.light(
          primary: Color(0xFFFF0000),
        ),
      );

      final settingsTheme = themeData.settingsThemeData;

      expect(
        settingsTheme.dividerColor,
        themeData.colorScheme.primary.withValues(alpha:0.7),
      );
      expect(
        settingsTheme.tileHighlightColor,
        themeData.colorScheme.primary.withValues(alpha:0.3),
      );
      expect(
        settingsTheme.tileDescriptionTextColor,
        themeData.colorScheme.primary.withValues(alpha:0.5),
      );
    });

    test('works with dark color scheme', () {
      final themeData = ThemeData(
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFFFFFF),
          surface: Color(0xFF000000),
        ),
      );

      final settingsTheme = themeData.settingsThemeData;
      expect(settingsTheme.trailingTextColor, const Color(0xFFFFFFFF));
      expect(settingsTheme.settingsListBackground, const Color(0xFF000000));
    });
  });
}
