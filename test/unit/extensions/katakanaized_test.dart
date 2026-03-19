import 'package:flutter_test/flutter_test.dart';
import 'package:ninja_scrolls/extentions.dart';

void main() {
  group('ExistenceCheck.katakanaized', () {
    test('converts hiragana to katakana', () {
      const String input = 'あいうえお';
      expect(input.katakanaized, 'アイウエオ');
    });

    test('keeps katakana unchanged', () {
      const String input = 'アイウエオ';
      expect(input.katakanaized, 'アイウエオ');
    });

    test('converts mixed hiragana and katakana', () {
      const String input = 'あアいイう';
      expect(input.katakanaized, 'アアイイウ');
    });

    test('handles null', () {
      const String? nullInput = null;
      expect(nullInput.katakanaized, isNull);
    });

    test('handles empty string', () {
      const String input = '';
      expect(input.katakanaized, '');
    });

    test('converts ゔ to ヴ', () {
      const String input = 'ゔぁいおれっと';
      expect(input.katakanaized, 'ヴァイオレット');
    });

    test('keeps non-kana characters unchanged', () {
      const String input = 'ABC123あいう';
      expect(input.katakanaized, 'ABC123アイウ');
    });

    test('handles full hiragana range', () {
      const String input = 'ぁぃぅぇぉ';
      expect(input.katakanaized, 'ァィゥェォ');
    });
  });
}
