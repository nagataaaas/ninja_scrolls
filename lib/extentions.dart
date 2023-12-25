// Flutter imports:
import 'package:flutter/material.dart';
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
}
