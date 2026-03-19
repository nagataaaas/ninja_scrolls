import 'package:flutter_test/flutter_test.dart';
import 'package:ninja_scrolls/src/gateway/shared_preferences_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SharedPreferencesStorage', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await SharedPreferencesStorage.ensureInitialized();
    });

    test('write and read returns stored value', () {
      SharedPreferencesStorage.write('key1', 'value1');
      expect(SharedPreferencesStorage.read('key1'), 'value1');
    });

    test('read returns null for non-existent key', () {
      expect(SharedPreferencesStorage.read('nonexistent'), isNull);
    });

    test('delete removes stored value', () {
      SharedPreferencesStorage.write('key2', 'value2');
      SharedPreferencesStorage.delete('key2');
      expect(SharedPreferencesStorage.read('key2'), isNull);
    });

    test('deleteAll removes all stored values', () {
      SharedPreferencesStorage.write('a', '1');
      SharedPreferencesStorage.write('b', '2');
      SharedPreferencesStorage.deleteAll();
      expect(SharedPreferencesStorage.read('a'), isNull);
      expect(SharedPreferencesStorage.read('b'), isNull);
    });

    test('write overwrites existing value', () {
      SharedPreferencesStorage.write('k', 'old');
      SharedPreferencesStorage.write('k', 'new');
      expect(SharedPreferencesStorage.read('k'), 'new');
    });
  });
}
