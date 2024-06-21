// Flutter imports:
import 'package:flutter/material.dart';
import 'package:settings_ui/settings_ui.dart';
// Package imports:
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';

extension ContextEx on BuildContext {
  TextTheme get textTheme => Theme.of(this).textTheme;

  ColorScheme get colorTheme => Theme.of(this).colorScheme;

  Size get screenSize => MediaQuery.of(this).size;

  double get screenHeight => MediaQuery.of(this).size.height;

  double get bodyHeight =>
      MediaQuery.of(this).size.height -
      (Scaffold.of(this).appBarMaxHeight ?? 0);

  double get screenWidth => MediaQuery.of(this).size.width;

  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showSnack(
      SnackBar snackBar) {
    return ScaffoldMessenger.of(this).showSnackBar(snackBar);
  }

  // L10n get l10n => L10n.of(this)!;

  Locale get locale => Localizations.localeOf(this);
}

extension CaseEdit on String {
  String capitalize([String? locale]) {
    return '${_upperCaseLetter(this[0], locale)}${substring(1)}';
  }

  String _upperCaseLetter(String letter, [String? locale]) {
    if (locale != null) {
      if (letter == 'i' &&
          (locale.startsWith('tr') || locale.startsWith('az'))) {
        return '\u0130';
      }
    }
    return letter.toUpperCase();
  }
}

extension ExistenceCheck on String? {
  String? get emptyToNull => this?.isEmpty ?? true ? null : this;
  String get nullToEmpty => this ?? '';
  String? get parenthesize => this?.isNotEmpty ?? false ? '($this)' : null;
  String? get katakanaized {
    return this?.replaceAllMapped(RegExp("[ぁ-ゔ]"),
        (Match m) => String.fromCharCode(m.group(0)!.codeUnitAt(0) + 0x60));
  }
}

extension TextStyleExt on TextStyle? {
  double? get lineHeightPixel {
    if (this == null) return null;
    if (this!.fontSize == null) return null;
    if (this!.height == null) return this!.fontSize!;
    return this!.fontSize! * this!.height!;
  }
}

extension ThemeDataSettingsThemeDataExt on ThemeData {
  SettingsThemeData get settingsThemeData {
    return SettingsThemeData(
      trailingTextColor: colorScheme.primary,
      settingsListBackground: colorScheme.surface,
      settingsSectionBackground: colorScheme.surface,
      dividerColor: colorScheme.primary.withOpacity(0.7),
      tileHighlightColor: colorScheme.primary.withOpacity(0.3),
      titleTextColor: colorScheme.primary,
      leadingIconsColor: colorScheme.primary,
      tileDescriptionTextColor: colorScheme.primary.withOpacity(0.5),
      settingsTileTextColor: colorScheme.primary,
    );
  }
}
