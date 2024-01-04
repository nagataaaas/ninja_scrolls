import 'package:shared_preferences/shared_preferences.dart';

SharedPreferences? _storage;

class SharedPreferencesStorage {
  static Future<void> ensureInitialized() async {
    _storage ??= await SharedPreferences.getInstance();
  }

  static String? read(String key) {
    return _storage!.getString(key);
  }

  static void write(String key, String value) {
    _storage!.setString(key, value);
  }

  static void delete(String key) {
    _storage!.remove(key);
  }

  static void deleteAll() {
    _storage!.clear();
  }
}
