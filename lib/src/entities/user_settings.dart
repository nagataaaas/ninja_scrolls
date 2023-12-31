import 'dart:convert';

import 'package:ninja_scrolls/src/gateway/secure_storage.dart';

enum ThemeType { auto, light, dark }

class UserSettings {
  final bool richAnimationEnabled;
  final ThemeType themeType;

  const UserSettings({
    this.richAnimationEnabled = true,
    this.themeType = ThemeType.auto,
  });

  UserSettings copyWith({
    bool? richAnimationEnabled,
    ThemeType? themeType,
  }) {
    return UserSettings(
      richAnimationEnabled: richAnimationEnabled ?? this.richAnimationEnabled,
      themeType: themeType ?? this.themeType,
    );
  }

  Future<void> save() async {
    await SecureStorage.write('userSettings', toJson());
  }

  static Future<UserSettings> load() async {
    final json = await SecureStorage.read('userSettings');
    if (json == null) {
      return const UserSettings();
    }
    return UserSettings.fromJson(json);
  }

  String toJson() => JsonEncoder().convert({
        'richAnimationEnabled': richAnimationEnabled,
        'themeType': themeType.index,
      });

  factory UserSettings.fromJson(String source) {
    final map = JsonDecoder().convert(source) as Map<String, dynamic>;
    return UserSettings(
      richAnimationEnabled: map['richAnimationEnabled'] as bool,
      themeType: ThemeType.values[map['themeType'] as int],
    );
  }
}
