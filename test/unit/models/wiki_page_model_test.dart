import 'package:flutter_test/flutter_test.dart';
import 'package:ninja_scrolls/src/gateway/database/wiki.dart';

void main() {
  group('WikiPage', () {
    test('fromDatabase creates WikiPage correctly', () {
      final page = WikiPage.fromDatabase({
        'title': 'ニンジャスレイヤー',
        'endpoint': '/njslyr/NinjaSlayer',
      });
      expect(page.title, 'ニンジャスレイヤー');
      expect(page.endpoint, '/njslyr/NinjaSlayer');
      // fromDatabase uses title as sanitizedTitle
      expect(page.sanitizedTitle, 'ニンジャスレイヤー');
    });

    test('toJson/fromJson roundtrip preserves data', () {
      final page = WikiPage(
        title: 'テストページ',
        sanitizedTitle: 'テストヘーシ',
        endpoint: '/njslyr/TestPage',
      );
      final json = page.toJson();
      final restored = WikiPage.fromJson(json);
      expect(restored.title, 'テストページ');
      expect(restored.sanitizedTitle, 'テストヘーシ');
      expect(restored.endpoint, '/njslyr/TestPage');
    });

    test('url getter constructs correct URL', () {
      final page = WikiPage(
        title: 'Test',
        sanitizedTitle: 'test',
        endpoint: '/njslyr/TestPage',
      );
      expect(page.url, 'https://wikiwiki.jp/njslyr/TestPage');
    });
  });
}
