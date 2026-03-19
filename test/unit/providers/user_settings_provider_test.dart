import 'package:flutter_test/flutter_test.dart';
import 'package:ninja_scrolls/src/entities/user_settings.dart';
import 'package:ninja_scrolls/src/providers/theme_provider.dart';
import 'package:ninja_scrolls/src/providers/user_settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('UserSettingsProvider defaults', () {
    test('themeType defaults to auto', () {
      final provider = UserSettingsProvider();
      expect(provider.themeType, ThemeType.auto);
    });

    test('darkTheme defaults to black', () {
      final provider = UserSettingsProvider();
      expect(provider.darkTheme, DarkTheme.black);
    });

    test('lightTheme defaults to bright', () {
      final provider = UserSettingsProvider();
      expect(provider.lightTheme, LightTheme.bright);
    });

    test('rawRichAnimationEnabled defaults to true', () {
      final provider = UserSettingsProvider();
      expect(provider.rawRichAnimationEnabled, true);
    });

    test('userSettings returns default UserSettings when not initialized', () {
      final provider = UserSettingsProvider();
      final settings = provider.userSettings;
      expect(settings.themeType, ThemeType.auto);
      expect(settings.darkTheme, DarkTheme.black);
      expect(settings.lightTheme, LightTheme.bright);
      expect(settings.richAnimationEnabled, true);
    });
  });

  group('UserSettingsProvider setters', () {
    late UserSettingsProvider provider;
    int notifyCount = 0;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      provider = UserSettingsProvider();
      await provider.ensureInitialized();
      notifyCount = 0;
      provider.addListener(() => notifyCount++);
    });

    test('set themeType updates value and notifies', () {
      provider.themeType = ThemeType.dark;
      expect(provider.themeType, ThemeType.dark);
      expect(notifyCount, 1);
    });

    test('set themeType to light', () {
      provider.themeType = ThemeType.light;
      expect(provider.themeType, ThemeType.light);
      expect(notifyCount, 1);
    });

    test('set darkTheme updates value and notifies', () {
      provider.darkTheme = DarkTheme.cyber;
      expect(provider.darkTheme, DarkTheme.cyber);
      expect(notifyCount, 1);
    });

    test('set lightTheme updates value and notifies', () {
      provider.lightTheme = LightTheme.leaf;
      expect(provider.lightTheme, LightTheme.leaf);
      expect(notifyCount, 1);
    });

    test('set richAnimationEnabled to false updates and notifies', () {
      provider.richAnimationEnabled = false;
      expect(provider.rawRichAnimationEnabled, false);
      expect(notifyCount, 1);
    });

    test('set richAnimationEnabled to null clears value', () {
      provider.richAnimationEnabled = false;
      provider.richAnimationEnabled = null;
      expect(provider.rawRichAnimationEnabled, isNull);
      expect(notifyCount, 2);
    });

    test('set userSettings replaces entire settings and notifies', () {
      final newSettings = UserSettings(
        themeType: ThemeType.dark,
        darkTheme: DarkTheme.fuji,
        lightTheme: LightTheme.automn,
        richAnimationEnabled: false,
      );
      provider.userSettings = newSettings;
      expect(provider.themeType, ThemeType.dark);
      expect(provider.darkTheme, DarkTheme.fuji);
      expect(provider.lightTheme, LightTheme.automn);
      expect(provider.rawRichAnimationEnabled, false);
      expect(notifyCount, 1);
    });
  });

  group('UserSettingsProvider.ensureInitialized', () {
    test('notifies listeners on initialization', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = UserSettingsProvider();
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await provider.ensureInitialized();
      expect(notifyCount, 1);
    });

    test('ensureInitialized only loads once then skips', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = UserSettingsProvider();
      int notifyCount = 0;

      await provider.ensureInitialized();
      provider.addListener(() => notifyCount++);

      // Change value
      provider.themeType = ThemeType.dark;
      expect(notifyCount, 1);

      // ensureInitialized again should not reset (??= guard)
      await provider.ensureInitialized();
      expect(provider.themeType, ThemeType.dark);
      // notifyListeners is still called but _userSettings is not replaced
      expect(notifyCount, 2);
    });
  });
}
