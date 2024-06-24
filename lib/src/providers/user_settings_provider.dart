import 'package:flutter/material.dart';
import 'package:ninja_scrolls/src/entities/user_settings.dart';
import 'package:ninja_scrolls/src/providers/theme_provider.dart';

class UserSettingsProvider extends ChangeNotifier {
  UserSettings? _userSettings;

  UserSettings get userSettings => _userSettings ?? UserSettings();

  ThemeType get themeType => userSettings.themeType;
  bool getRichAnimationEnabled(BuildContext context) =>
      userSettings.richAnimationEnabled ??
      !MediaQuery.of(context).disableAnimations;
  bool? get rawRichAnimationEnabled => userSettings.richAnimationEnabled;
  DarkTheme get darkTheme => userSettings.darkTheme;
  LightTheme get lightTheme => userSettings.lightTheme;

  Future<void> ensureInitialized() async {
    _userSettings ??= await UserSettings.load();
    notifyListeners();
  }

  set userSettings(UserSettings value) {
    _userSettings = value;
    notifyListeners();
    _userSettings!.save();
  }

  set themeType(ThemeType value) {
    _userSettings = userSettings.copyWith(themeType: value);
    notifyListeners();
    _userSettings!.save();
  }

  set richAnimationEnabled(bool? value) {
    _userSettings = userSettings.copyWith(
        forceUpdateRichAnimationEnabled: true, richAnimationEnabled: value);
    notifyListeners();
    _userSettings!.save();
  }

  set darkTheme(DarkTheme value) {
    _userSettings = userSettings.copyWith(darkTheme: value);
    notifyListeners();
    _userSettings!.save();
  }

  set lightTheme(LightTheme value) {
    _userSettings = userSettings.copyWith(lightTheme: value);
    notifyListeners();
    _userSettings!.save();
  }
}
