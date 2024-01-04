import 'dart:convert';

import 'package:ninja_scrolls/src/gateway/shared_preferences_storage.dart';
import 'package:ninja_scrolls/src/providers/theme_provider.dart';

enum ThemeType { auto, light, dark }

class UserSettings {
  final bool richAnimationEnabled;
  final ThemeType themeType;
  final DarkTheme darkTheme;
  final LightTheme lightTheme;

  const UserSettings({
    this.richAnimationEnabled = true,
    this.themeType = ThemeType.auto,
    this.darkTheme = DarkTheme.black,
    this.lightTheme = LightTheme.bright,
  });

  UserSettings copyWith({
    bool? richAnimationEnabled,
    ThemeType? themeType,
    DarkTheme? darkTheme,
    LightTheme? lightTheme,
  }) {
    return UserSettings(
      richAnimationEnabled: richAnimationEnabled ?? this.richAnimationEnabled,
      themeType: themeType ?? this.themeType,
      darkTheme: darkTheme ?? this.darkTheme,
      lightTheme: lightTheme ?? this.lightTheme,
    );
  }

  Future<void> save() async {
    SharedPreferencesStorage.write('userSettings', toJson());
  }

  static Future<UserSettings> load() async {
    await SharedPreferencesStorage.ensureInitialized();
    final json = SharedPreferencesStorage.read('userSettings');
    if (json == null) {
      return const UserSettings();
    }
    return UserSettings.fromJson(json);
  }

  String toJson() => JsonEncoder().convert({
        'richAnimationEnabled': richAnimationEnabled,
        'themeType': themeType.index,
        'darkTheme': darkTheme.name,
        'lightTheme': lightTheme.name,
      });

  factory UserSettings.fromJson(String source) {
    final map = JsonDecoder().convert(source) as Map<String, dynamic>;
    return UserSettings(
      richAnimationEnabled: map['richAnimationEnabled'] as bool,
      themeType: ThemeType.values[map['themeType'] as int],
      darkTheme: DarkTheme.values.firstWhere(
        (element) => element.name == map['darkTheme'] as String?,
        orElse: () => DarkTheme.black,
      ),
      lightTheme: LightTheme.values.firstWhere(
        (element) => element.name == map['lightTheme'] as String?,
        orElse: () => LightTheme.bright,
      ),
    );
  }
}
