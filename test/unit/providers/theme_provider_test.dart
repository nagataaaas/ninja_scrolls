import 'package:flutter_test/flutter_test.dart';

import 'package:ninja_scrolls/src/providers/theme_provider.dart';
import 'package:ninja_scrolls/src/providers/user_settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ThemeProvider', () {
    late ThemeProvider provider;
    int notifyCount = 0;

    setUp(() {
      provider = ThemeProvider();
      notifyCount = 0;
      provider.addListener(() => notifyCount++);
    });

    test('default darkTheme is black', () {
      expect(provider.darkTheme, DarkTheme.black);
    });

    test('default lightTheme is bright', () {
      expect(provider.lightTheme, LightTheme.bright);
    });

    test('setting darkTheme notifies listeners', () {
      provider.darkTheme = DarkTheme.cyber;
      expect(provider.darkTheme, DarkTheme.cyber);
      expect(notifyCount, 1);
    });

    test('setting lightTheme notifies listeners', () {
      provider.lightTheme = LightTheme.leaf;
      expect(provider.lightTheme, LightTheme.leaf);
      expect(notifyCount, 1);
    });
  });

  group('DarkTheme enum', () {
    test('has correct names', () {
      expect(DarkTheme.black.name, 'ブラック');
      expect(DarkTheme.dusk.name, 'ダスク');
      expect(DarkTheme.fuji.name, 'フジ');
      expect(DarkTheme.cyber.name, 'サイバー');
    });

    test('each dark theme has a ThemeData', () {
      for (final dark in DarkTheme.values) {
        expect(dark.theme, isNotNull);
      }
    });
  });

  group('LightTheme enum', () {
    test('has correct names', () {
      expect(LightTheme.bright.name, 'ブライト');
      expect(LightTheme.milk.name, 'ミルク');
      expect(LightTheme.leaf.name, 'リーフ');
      expect(LightTheme.automn.name, 'オータム');
    });

    test('each light theme has a ThemeData', () {
      for (final light in LightTheme.values) {
        expect(light.theme, isNotNull);
      }
    });
  });

  group('ThemeProvider.initializeWithUserSettings', () {
    test('syncs dark and light theme from UserSettingsProvider', () async {
      SharedPreferences.setMockInitialValues({});
      final userSettingsProvider = UserSettingsProvider();
      await userSettingsProvider.ensureInitialized();
      userSettingsProvider.darkTheme = DarkTheme.cyber;
      userSettingsProvider.lightTheme = LightTheme.automn;

      final themeProvider = ThemeProvider();
      int notifyCount = 0;
      themeProvider.addListener(() => notifyCount++);

      themeProvider.initializeWithUserSettings(userSettingsProvider);

      expect(themeProvider.darkTheme, DarkTheme.cyber);
      expect(themeProvider.lightTheme, LightTheme.automn);
      expect(notifyCount, 1);
    });

    test('syncs default values from fresh UserSettingsProvider', () {
      // Use a fresh UserSettingsProvider without ensureInitialized
      // to get actual default values (no SharedPreferences pollution)
      final userSettingsProvider = UserSettingsProvider();

      final themeProvider = ThemeProvider();
      themeProvider.initializeWithUserSettings(userSettingsProvider);

      expect(themeProvider.darkTheme, DarkTheme.black);
      expect(themeProvider.lightTheme, LightTheme.bright);
    });

    test('syncs non-default fuji/milk from UserSettingsProvider', () async {
      SharedPreferences.setMockInitialValues({});
      final userSettingsProvider = UserSettingsProvider();
      await userSettingsProvider.ensureInitialized();
      userSettingsProvider.darkTheme = DarkTheme.fuji;
      userSettingsProvider.lightTheme = LightTheme.milk;

      final themeProvider = ThemeProvider();
      themeProvider.initializeWithUserSettings(userSettingsProvider);

      expect(themeProvider.darkTheme, DarkTheme.fuji);
      expect(themeProvider.lightTheme, LightTheme.milk);
    });
  });
}
