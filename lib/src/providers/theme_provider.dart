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
    textTheme: textTheme?.apply(
      bodyColor: colors.Common.black,
      displayColor: colors.Common.black,
    ),
  ),
  LightTheme.milk: ThemeData(
    useMaterial3: true,
    appBarTheme: const AppBarTheme(
      backgroundColor: colors.Common.dustMilk,
      foregroundColor: colors.Common.dark,
    ),
    colorScheme: const ColorScheme.light(
      surface: colors.Common.dustMilk,
      primary: colors.Common.dark,
      onPrimary: colors.Common.dustMilk,
      secondary: colors.Common.grey1,
      onSecondary: colors.Common.lightGrey2,
      tertiary: colors.Common.accent,
      onTertiary: colors.Common.dustMilk,
      error: colors.Common.errorRed,
    ),
    brightness: Brightness.light,
    textTheme: textTheme?.apply(
      bodyColor: colors.Common.dark,
      displayColor: colors.Common.dark,
    ),
  ),
  LightTheme.automn: ThemeData(
    appBarTheme: const AppBarTheme(
      foregroundColor: colors.Common.peach,
    ),
    useMaterial3: true,
    colorSchemeSeed: colors.Common.peach,
    brightness: Brightness.light,
    textTheme: textTheme?.apply(
      bodyColor: colors.Common.darkPeach,
      displayColor: colors.Common.darkPeach,
    ),
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
    textTheme: textTheme,
  ),
  DarkTheme.dusk: ThemeData(
    useMaterial3: true,
    appBarTheme: AppBarTheme(
      foregroundColor: colors.Common.dusk.lighten(.2),
    ),
    colorSchemeSeed: colors.Common.dusk.lighten(.2),
    brightness: Brightness.dark,
    textTheme: textTheme?.apply(
      bodyColor: colors.Common.dusk.lighten(0.4),
      displayColor: colors.Common.dusk.lighten(0.7),
    ),
  ),
  DarkTheme.cyber: ThemeData(
    useMaterial3: true,
    appBarTheme: AppBarTheme(
      foregroundColor: colors.Common.geekGreen,
    ),
    colorSchemeSeed: colors.Common.geekGreen,
    brightness: Brightness.dark,
    textTheme: textTheme?.apply(
      bodyColor: colors.Common.geekGreen,
      displayColor: colors.Common.geekGreen,
    ),
  ),
};

enum LightTheme with ThemeMixin {
  bright,
  milk,
  automn;

  @override
  String get name {
    switch (this) {
      case LightTheme.bright:
        return 'ブライト';
      case LightTheme.milk:
        return 'ミルク';
      case LightTheme.automn:
        return 'オータム';
    }
  }
}

enum DarkTheme with ThemeMixin {
  black,
  dusk,
  cyber;

  @override
  String get name {
    switch (this) {
      case DarkTheme.black:
        return 'ブラック';
      case DarkTheme.dusk:
        return 'ダスク';
      case DarkTheme.cyber:
        return 'サイバー';
    }
  }
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

    themes[LightTheme.bright] = themes[LightTheme.bright]!.copyWith(
      textTheme: textTheme?.apply(
        bodyColor: colors.Common.black,
        displayColor: colors.Common.black,
      ),
    );
    themes[LightTheme.milk] = themes[LightTheme.milk]!.copyWith(
      textTheme: textTheme!.apply(
        bodyColor: colors.Common.dark,
        displayColor: colors.Common.dark,
      ),
    );
    themes[LightTheme.automn] = themes[LightTheme.automn]!.copyWith(
      textTheme: textTheme!.apply(
        bodyColor: colors.Common.peach,
        displayColor: colors.Common.peach,
      ),
    );
    themes[DarkTheme.black] = themes[DarkTheme.black]!.copyWith(
      textTheme: textTheme,
    );
    themes[DarkTheme.dusk] = themes[DarkTheme.dusk]!.copyWith(
      textTheme: textTheme!.apply(
        bodyColor: colors.Common.dusk.lighten(0.4),
        displayColor: colors.Common.dusk.lighten(0.6),
      ),
    );
    themes[DarkTheme.cyber] = themes[DarkTheme.cyber]!.copyWith(
      textTheme: textTheme!.apply(
        bodyColor: colors.Common.geekGreen,
        displayColor: colors.Common.geekGreen,
      ),
    );

    notifyListeners();
  }

  void initializeWithUserSettings(UserSettingsProvider userSettingsProvider) {
    _darkTheme = userSettingsProvider.darkTheme;
    _lightTheme = userSettingsProvider.lightTheme;
    log("dark: $_darkTheme, light: $_lightTheme");
    notifyListeners();
  }
}
