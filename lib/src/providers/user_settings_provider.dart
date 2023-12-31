import 'package:flutter/material.dart';
import 'package:ninja_scrolls/src/entities/user_settings.dart';

class UserSettingsProvider extends ChangeNotifier {
  UserSettings? _userSettings;

  UserSettings get userSettings => _userSettings ?? UserSettings();

  ThemeType get themeType => userSettings.themeType;
  bool get richAnimationEnabled => userSettings.richAnimationEnabled;

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

  set richAnimationEnabled(bool value) {
    _userSettings = userSettings.copyWith(richAnimationEnabled: value);
    notifyListeners();
    _userSettings!.save();
  }
}
