import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:ninja_scrolls/src/gateway/database/wiki.dart';
import 'package:ninja_scrolls/src/gateway/wiki.dart';
import 'package:ninja_scrolls/src/providers/wiki_index_provider.dart';

void main() {
  group('Bisect.findIndexToInsert', () {
    test('returns 0 for empty list', () {
      expect(Bisect.findIndexToInsert([], 'a'), 0);
    });

    test('returns 0 when target is before all elements', () {
      expect(Bisect.findIndexToInsert(['b', 'c', 'd'], 'a'), 0);
    });

    test('returns list length when target is after all elements', () {
      expect(Bisect.findIndexToInsert(['a', 'b', 'c'], 'd'), 3);
    });

    test('returns exact index for existing element', () {
      expect(Bisect.findIndexToInsert(['a', 'b', 'c', 'd'], 'c'), 2);
    });

    test('returns insert position for non-existing element', () {
      expect(Bisect.findIndexToInsert(['a', 'c', 'e'], 'b'), 1);
      expect(Bisect.findIndexToInsert(['a', 'c', 'e'], 'd'), 2);
    });

    test('works with single element list', () {
      expect(Bisect.findIndexToInsert(['b'], 'a'), 0);
      expect(Bisect.findIndexToInsert(['b'], 'b'), 0);
      expect(Bisect.findIndexToInsert(['b'], 'c'), 1);
    });

    test('works with Japanese strings', () {
      final sorted = ['アイウ', 'カキク', 'サシス'];
      expect(Bisect.findIndexToInsert(sorted, 'カキク'), 1);
    });
  });

  group('WikiIndexProvider', () {
    late WikiIndexProvider provider;

    setUp(() {
      provider = WikiIndexProvider();
    });

    test('setWikiPagesForTest populates pages and builds map', () {
      final pages = [
        WikiPage(
          title: 'ニンジャスレイヤー',
          sanitizedTitle: WikiNetworkGateway.sanitizeForSearch('ニンジャスレイヤー'),
          endpoint: '/njslyr/NinjaSlayer',
        ),
        WikiPage(
          title: 'フジキド',
          sanitizedTitle: WikiNetworkGateway.sanitizeForSearch('フジキド'),
          endpoint: '/njslyr/Fujikido',
        ),
      ];
      provider.setWikiPagesForTest(pages);
      expect(provider.wikiPages.length, 2);
    });

    test('findPages returns empty for empty query', () {
      provider.setWikiPagesForTest([
        WikiPage(
          title: 'Test',
          sanitizedTitle: 'test',
          endpoint: '/test',
        ),
      ]);
      expect(provider.findPages(''), isEmpty);
    });

    test('findPages returns empty when no pages loaded', () {
      expect(provider.findPages('test'), isEmpty);
    });

    test('findPages finds matching pages', () {
      final pages = [
        WikiPage(
          title: 'ニンジャスレイヤー',
          sanitizedTitle: WikiNetworkGateway.sanitizeForSearch('ニンジャスレイヤー'),
          endpoint: '/njslyr/NinjaSlayer',
        ),
        WikiPage(
          title: 'ニンジャ',
          sanitizedTitle: WikiNetworkGateway.sanitizeForSearch('ニンジャ'),
          endpoint: '/njslyr/Ninja',
        ),
        WikiPage(
          title: 'サイタマ',
          sanitizedTitle: WikiNetworkGateway.sanitizeForSearch('サイタマ'),
          endpoint: '/njslyr/Saitama',
        ),
      ];
      provider.setWikiPagesForTest(pages);

      final results = provider.findPages('ニンジャ');
      expect(results, isNotEmpty);
      // Should find pages starting with ニンジャ
      for (final result in results) {
        expect(
          result.page.title.startsWith('ニンジャ'),
          isTrue,
          reason: 'Expected ${result.page.title} to start with ニンジャ',
        );
      }
    });

    test('buildMap sorts sanitized texts', () {
      final pages = [
        WikiPage(
          title: 'ンンジャ',
          sanitizedTitle: WikiNetworkGateway.sanitizeForSearch('ンンジャ'),
          endpoint: '/c',
        ),
        WikiPage(
          title: 'アイウ',
          sanitizedTitle: WikiNetworkGateway.sanitizeForSearch('アイウ'),
          endpoint: '/a',
        ),
        WikiPage(
          title: 'カキク',
          sanitizedTitle: WikiNetworkGateway.sanitizeForSearch('カキク'),
          endpoint: '/b',
        ),
      ];
      provider.setWikiPagesForTest(pages);

      // findPages with 'ア' should find アイウ
      final results = provider.findPages('ア');
      expect(results, isNotEmpty);
      expect(results.first.page.title, 'アイウ');
    });

    test('findPages partial prefix match returns correct results', () {
      final pages = [
        WikiPage(
          title: 'ニンジャスレイヤー',
          sanitizedTitle: WikiNetworkGateway.sanitizeForSearch('ニンジャスレイヤー'),
          endpoint: '/njslyr/NinjaSlayer',
        ),
        WikiPage(
          title: 'ニンジャ',
          sanitizedTitle: WikiNetworkGateway.sanitizeForSearch('ニンジャ'),
          endpoint: '/njslyr/Ninja',
        ),
        WikiPage(
          title: 'ニンジュツ',
          sanitizedTitle: WikiNetworkGateway.sanitizeForSearch('ニンジュツ'),
          endpoint: '/njslyr/Ninjutsu',
        ),
      ];
      provider.setWikiPagesForTest(pages);

      final results = provider.findPages('ニンジャ');
      // Should match ニンジャ and ニンジャスレイヤー but not ニンジュツ
      expect(results.length, 2);
      final titles = results.map((r) => r.page.title).toSet();
      expect(titles.contains('ニンジャ'), isTrue);
      expect(titles.contains('ニンジャスレイヤー'), isTrue);
    });

    test('findPages with duplicate sanitized titles returns all pages', () {
      // Two pages with same sanitized title but different actual titles
      final sanitized = WikiNetworkGateway.sanitizeForSearch('テスト');
      final pages = [
        WikiPage(
          title: 'テスト',
          sanitizedTitle: sanitized,
          endpoint: '/test1',
        ),
        WikiPage(
          title: 'テスト',
          sanitizedTitle: sanitized,
          endpoint: '/test2',
        ),
      ];
      provider.setWikiPagesForTest(pages);

      final results = provider.findPages('テスト');
      // Both pages match since they share the same sanitized title
      expect(results.length, greaterThanOrEqualTo(2));
      final endpoints = results.map((r) => r.page.endpoint).toSet();
      expect(endpoints.contains('/test1'), isTrue);
      expect(endpoints.contains('/test2'), isTrue);
    });

    test('findPages with empty wiki pages returns empty', () {
      provider.setWikiPagesForTest([]);
      final results = provider.findPages('ニンジャ');
      expect(results, isEmpty);
    });
  });

  group('WordSearchResult.score', () {
    test('score is matchRate * sqrt(matchLength)', () {
      final page = WikiPage(
        title: 'Test',
        sanitizedTitle: 'test',
        endpoint: '/test',
      );
      final result = WordSearchResult(page, 0.8, 4);
      expect(result.score, closeTo(0.8 * sqrt(4), 0.001));
    });

    test('score is 0 when matchRate is 0', () {
      final page = WikiPage(
        title: 'Test',
        sanitizedTitle: 'test',
        endpoint: '/test',
      );
      final result = WordSearchResult(page, 0.0, 5);
      expect(result.score, 0.0);
    });
  });
}
