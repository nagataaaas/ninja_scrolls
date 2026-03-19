import 'package:flutter_test/flutter_test.dart';
import 'package:ninja_scrolls/src/gateway/wiki.dart';

void main() {
  group('WikiNetworkGateway.isContentTitle', () {
    test('returns false for system pages with ◆', () {
      expect(WikiNetworkGateway.isContentTitle('◆管理ページ'), isFalse);
    });

    test('returns false for comment pages', () {
      expect(WikiNetworkGateway.isContentTitle('コメント/ページ名'), isFalse);
    });

    test('returns false for test pages', () {
      expect(WikiNetworkGateway.isContentTitle('テスト用ページ'), isFalse);
      expect(WikiNetworkGateway.isContentTitle('testpage'), isFalse);
    });

    test('returns false for editing log pages', () {
      expect(WikiNetworkGateway.isContentTitle('編集会議ログ2024'), isFalse);
    });

    test('returns false for InterWiki pages', () {
      expect(WikiNetworkGateway.isContentTitle('InterWikiName'), isFalse);
    });

    test('returns false for known system pages', () {
      expect(WikiNetworkGateway.isContentTitle('SandBox'), isFalse);
      expect(WikiNetworkGateway.isContentTitle('FrontPage'), isFalse);
      expect(WikiNetworkGateway.isContentTitle('MenuBar'), isFalse);
      expect(WikiNetworkGateway.isContentTitle('SideBar'), isFalse);
      expect(WikiNetworkGateway.isContentTitle('RecentCreated'), isFalse);
      expect(WikiNetworkGateway.isContentTitle('RecentDeleted'), isFalse);
      expect(WikiNetworkGateway.isContentTitle('人気100'), isFalse);
      expect(WikiNetworkGateway.isContentTitle('今日100'), isFalse);
      expect(WikiNetworkGateway.isContentTitle('更新履歴'), isFalse);
      expect(WikiNetworkGateway.isContentTitle('相談所'), isFalse);
    });

    test('returns true for content pages', () {
      expect(WikiNetworkGateway.isContentTitle('ニンジャスレイヤー'), isTrue);
      expect(WikiNetworkGateway.isContentTitle('フジキド'), isTrue);
      expect(WikiNetworkGateway.isContentTitle('ネオサイタマ'), isTrue);
    });
  });

  group('WikiNetworkGateway.getEndpoint', () {
    test('strips base URL from full URL', () {
      expect(
        WikiNetworkGateway.getEndpoint('https://wikiwiki.jp/njslyr/TestPage'),
        '/njslyr/TestPage',
      );
    });

    test('strips njslyr base path', () {
      expect(
        WikiNetworkGateway.getEndpoint('/njslyr/TestPage'),
        'TestPage',
      );
    });

    test('returns as-is for other URLs', () {
      expect(
        WikiNetworkGateway.getEndpoint('TestPage'),
        'TestPage',
      );
    });
  });

  group('WikiNetworkGateway.getUrl', () {
    test('constructs full URL from endpoint', () {
      expect(
        WikiNetworkGateway.getUrl('TestPage'),
        'https://wikiwiki.jp/njslyr/TestPage',
      );
    });

    test('returns as-is if already full URL', () {
      expect(
        WikiNetworkGateway.getUrl('https://wikiwiki.jp/some/page'),
        'https://wikiwiki.jp/some/page',
      );
    });
  });

  group('WikiNetworkGateway.splitTitle', () {
    test('splits on ／', () {
      expect(
        WikiNetworkGateway.splitTitle('タイトルA／タイトルB'),
        ['タイトルA', 'タイトルB'],
      );
    });

    test('returns single item list for title starting with 「', () {
      expect(
        WikiNetworkGateway.splitTitle('「タイトル／サブタイトル」'),
        ['「タイトル／サブタイトル」'],
      );
    });

    test('returns single item list for title without ／', () {
      expect(
        WikiNetworkGateway.splitTitle('タイトル'),
        ['タイトル'],
      );
    });
  });

  group('WikiNetworkGateway.sanitizeForSearch', () {
    test('removes symbols and converts to katakana + lowercase', () {
      expect(
        WikiNetworkGateway.sanitizeForSearch('ニンジャ・スレイヤー'),
        'ニンジャスレイヤー'.toLowerCase(),
      );
    });

    test('removes various punctuation', () {
      expect(
        WikiNetworkGateway.sanitizeForSearch('タイトル！Test＝Value'),
        'タイトルtestvalue',
      );
    });

    test('converts hiragana to katakana', () {
      expect(
        WikiNetworkGateway.sanitizeForSearch('にんじゃ'),
        'ニンジャ'.toLowerCase(),
      );
    });
  });

  group('WikiNetworkGateway.sanitizeForCompare', () {
    test('removes symbols and lowercases but no katakana conversion', () {
      expect(
        WikiNetworkGateway.sanitizeForCompare('ニンジャ・スレイヤー'),
        'ニンジャスレイヤー'.toLowerCase(),
      );
    });

    test('does not convert hiragana to katakana', () {
      // sanitizeForCompare does NOT katakanaize, only removes symbols and lowercases
      final result = WikiNetworkGateway.sanitizeForCompare('にんじゃ');
      expect(result, 'にんじゃ');
    });
  });
}
