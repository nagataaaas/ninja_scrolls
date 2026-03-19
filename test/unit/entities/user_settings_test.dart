import 'package:flutter_test/flutter_test.dart';
import 'package:ninja_scrolls/src/entities/user_settings.dart';
import 'package:ninja_scrolls/src/providers/theme_provider.dart';

void main() {
  group('UserSettings', () {
    test('default constructor has expected defaults', () {
      const settings = UserSettings();
      expect(settings.richAnimationEnabled, true);
      expect(settings.themeType, ThemeType.auto);
      expect(settings.darkTheme, DarkTheme.black);
      expect(settings.lightTheme, LightTheme.bright);
    });

    test('toJson/fromJson roundtrip preserves data', () {
      const settings = UserSettings(
        richAnimationEnabled: false,
        themeType: ThemeType.dark,
        darkTheme: DarkTheme.cyber,
        lightTheme: LightTheme.leaf,
      );
      final json = settings.toJson();
      final restored = UserSettings.fromJson(json);
      expect(restored.richAnimationEnabled, false);
      expect(restored.themeType, ThemeType.dark);
      expect(restored.darkTheme, DarkTheme.cyber);
      expect(restored.lightTheme, LightTheme.leaf);
    });

    test('toJson/fromJson roundtrip with null richAnimationEnabled', () {
      const settings = UserSettings(richAnimationEnabled: null);
      final json = settings.toJson();
      final restored = UserSettings.fromJson(json);
      expect(restored.richAnimationEnabled, isNull);
    });

    test('copyWith preserves existing values when no args given', () {
      const settings = UserSettings(
        richAnimationEnabled: false,
        themeType: ThemeType.light,
        darkTheme: DarkTheme.dusk,
        lightTheme: LightTheme.milk,
      );
      final copied = settings.copyWith();
      expect(copied.richAnimationEnabled, false);
      expect(copied.themeType, ThemeType.light);
      expect(copied.darkTheme, DarkTheme.dusk);
      expect(copied.lightTheme, LightTheme.milk);
    });

    test('copyWith overrides specified values', () {
      const settings = UserSettings();
      final copied = settings.copyWith(
        themeType: ThemeType.dark,
        darkTheme: DarkTheme.fuji,
      );
      expect(copied.themeType, ThemeType.dark);
      expect(copied.darkTheme, DarkTheme.fuji);
      expect(copied.lightTheme, LightTheme.bright); // unchanged
    });

    test('copyWith with forceUpdateRichAnimationEnabled sets null', () {
      const settings = UserSettings(richAnimationEnabled: true);
      final copied = settings.copyWith(
        forceUpdateRichAnimationEnabled: true,
        richAnimationEnabled: null,
      );
      expect(copied.richAnimationEnabled, isNull);
    });

    test(
        'copyWith without forceUpdateRichAnimationEnabled keeps existing when null passed',
        () {
      const settings = UserSettings(richAnimationEnabled: true);
      final copied = settings.copyWith(richAnimationEnabled: null);
      expect(copied.richAnimationEnabled, true);
    });

    test('fromJson falls back to defaults for unknown enum names', () {
      // Manually construct JSON with unknown enum names
      const json =
          '{"richAnimationEnabled":true,"themeType":0,"darkTheme":"unknownTheme","lightTheme":"unknownTheme"}';
      final restored = UserSettings.fromJson(json);
      expect(restored.darkTheme, DarkTheme.black);
      expect(restored.lightTheme, LightTheme.bright);
    });
  });
}
