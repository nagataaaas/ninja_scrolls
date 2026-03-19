import 'package:flutter_test/flutter_test.dart';
import 'package:ninja_scrolls/extentions.dart';

void main() {
  group('ExistenceCheck.emptyToNull', () {
    test('returns null for empty string', () {
      const String input = '';
      expect(input.emptyToNull, isNull);
    });

    test('returns null for null', () {
      const String? nullInput = null;
      expect(nullInput.emptyToNull, isNull);
    });

    test('returns string for non-empty', () {
      const String input = 'hello';
      expect(input.emptyToNull, 'hello');
    });
  });

  group('ExistenceCheck.nullToEmpty', () {
    test('returns empty string for null', () {
      const String? nullInput = null;
      expect(nullInput.nullToEmpty, '');
    });

    test('returns the string for non-null', () {
      const String input = 'hello';
      expect(input.nullToEmpty, 'hello');
    });
  });

  group('ExistenceCheck.parenthesize', () {
    test('returns parenthesized string for non-empty', () {
      const String input = 'hello';
      expect(input.parenthesize, '(hello)');
    });

    test('returns null for empty string', () {
      const String input = '';
      expect(input.parenthesize, isNull);
    });

    test('returns null for null', () {
      const String? nullInput = null;
      expect(nullInput.parenthesize, isNull);
    });
  });

  group('CaseEdit.capitalize', () {
    test('capitalizes first letter', () {
      expect('hello'.capitalize(), 'Hello');
    });

    test('handles already capitalized', () {
      expect('Hello'.capitalize(), 'Hello');
    });

    test('handles single character', () {
      expect('h'.capitalize(), 'H');
    });

    test('handles Turkish locale i', () {
      expect('istanbul'.capitalize('tr'), '\u0130stanbul');
    });

    test('handles Azerbaijani locale i', () {
      expect('istanbul'.capitalize('az'), '\u0130stanbul');
    });
  });
}
