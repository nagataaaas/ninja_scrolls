import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ninja_scrolls/src/providers/user_settings_provider.dart';
import 'package:ninja_scrolls/src/static/colors.dart' as colors;

TextTheme? textTheme;

mixin ThemeMixin {
  ThemeData get theme => themes[this]!;
  String get name;
}

Map<ThemeMixin, ThemeData> themes = {
  LightTheme.bright: ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      surface: colors.Common.white,
      primary: colors.Common.black,
      onPrimary: colors.Common.white,
      secondary: colors.Common.grey2,
      onSecondary: colors.Common.white,
      tertiary: colors.Common.accent,
      onTertiary: colors.Common.white,
      error: colors.Common.errorRed,
    ),
    brightness: Brightness.light,
    textTheme: textTheme,
  ),
  LightTheme.leaf: ThemeData(
    useMaterial3: true,
    colorSchemeSeed: colors.Common.white,
    brightness: Brightness.light,
    textTheme: textTheme,
  ),
  LightTheme.milk: ThemeData(
    useMaterial3: true,
    colorSchemeSeed: colors.Common.milk,
    brightness: Brightness.light,
    textTheme: textTheme,
  ),
  LightTheme.automn: ThemeData(
    useMaterial3: true,
    colorSchemeSeed: colors.Common.peach,
    brightness: Brightness.light,
  ),
  DarkTheme.black: ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.dark(
      surface: colors.Common.black,
      primary: colors.Common.white,
      onPrimary: colors.Common.black,
      secondary: colors.Common.grey3,
      onSecondary: colors.Common.white,
      tertiary: colors.Common.accent,
      onTertiary: colors.Common.white,
      error: colors.Common.errorRed,
    ),
    brightness: Brightness.dark,
  ),
  DarkTheme.fuji: ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
  ),
  DarkTheme.dusk: ThemeData(
    useMaterial3: true,
    colorSchemeSeed: colors.Common.dusk.lighten(.2),
    brightness: Brightness.dark,
  ),
  DarkTheme.cyber: ThemeData(
    useMaterial3: true,
    colorSchemeSeed: colors.Common.geekGreen,
    brightness: Brightness.dark,
  ),
};

enum LightTheme with ThemeMixin {
  bright('ブライト'),
  milk('ミルク'),
  leaf('リーフ'),
  automn('オータム');

  const LightTheme(this.name);

  @override
  final String name;
}

enum DarkTheme with ThemeMixin {
  black('ブラック'),
  dusk('ダスク'),
  fuji('フジ'),
  cyber('サイバー');

  const DarkTheme(this.name);

  @override
  final String name;
}

class ThemeProvider extends ChangeNotifier {
  DarkTheme _darkTheme = DarkTheme.black;
  LightTheme _lightTheme = LightTheme.bright;

  DarkTheme get darkTheme => _darkTheme;
  LightTheme get lightTheme => _lightTheme;

  set darkTheme(DarkTheme value) {
    _darkTheme = value;
    notifyListeners();
  }

  set lightTheme(LightTheme value) {
    _lightTheme = value;
    notifyListeners();
  }

  void ensureTextThemeInitialized(BuildContext context) {
    textTheme ??=
        GoogleFonts.notoSansJpTextTheme(Theme.of(context).textTheme.copyWith(
              headlineLarge: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w600,
              ),
              headlineMedium: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
              headlineSmall: const TextStyle(
                fontSize: 18,
              ),
              bodyLarge: const TextStyle(
                fontSize: 16,
              ),
              bodyMedium: const TextStyle(
                fontSize: 14,
              ),
              bodySmall: const TextStyle(
                fontSize: 12,
              ),
            ));

    for (final themeMixin in themes.keys) {
      print(
          "themeMixin: $themeMixin, ${themes[themeMixin]!.textTheme.bodyMedium!.color}");
      themes[themeMixin] = themes[themeMixin]!.copyWith(
          textTheme: textTheme?.apply(
        bodyColor: themes[themeMixin]!.colorScheme.primary,
        displayColor: themes[themeMixin]!.colorScheme.primary,
      ));
    }

    notifyListeners();
  }

  void initializeWithUserSettings(UserSettingsProvider userSettingsProvider) {
    _darkTheme = userSettingsProvider.darkTheme;
    _lightTheme = userSettingsProvider.lightTheme;
    log("dark: $_darkTheme, light: $_lightTheme");
    notifyListeners();
  }
}
