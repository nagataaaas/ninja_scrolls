import 'package:flutter_test/flutter_test.dart';
import 'package:ninja_scrolls/src/gateway/database/episode_search_history.dart';
import 'package:ninja_scrolls/src/gateway/database/note.dart';
import 'package:ninja_scrolls/src/gateway/database/read_state.dart';

void main() {
  group('Note.fromJson', () {
    test('parses complete API response', () {
      final json = {
        'data': {
          'key': 'n_test_abc',
          'name': 'Test Episode',
          'body': '<p>Hello world</p>',
          'eyecatch': 'https://example.com/img.png',
          'remained_char_num': 100,
          'index': [
            {'name': 'sec1', 'body': 'Section 1'},
            {'name': 'sec2', 'body': 'Section 2'},
          ],
          'is_limited': false,
          'is_purchased': false,
          'embedded_contents': [],
        },
      };

      final note = Note.fromJson(json);
      expect(note.id, 'n_test_abc');
      expect(note.title, 'Test Episode');
      expect(note.html, '<p>Hello world</p>');
      expect(note.eyecatchUrl, 'https://example.com/img.png');
      expect(note.remainedCharNum, 100);
      expect(note.indexItems.length, 2);
      expect(note.indexItems[0].id, 'sec1');
      expect(note.indexItems[0].title, 'Section 1');
      expect(note.indexItems[1].id, 'sec2');
      expect(note.isLimited, isFalse);
      expect(note.isPurchased, isFalse);
      expect(note.bookPurchaseLink, isNull);
      expect(note.cachedAt, isNotNull);
    });

    test('body null falls back to empty string', () {
      final json = {
        'data': {
          'key': 'n_null_body',
          'name': 'No Body',
          'body': null,
          'eyecatch': null,
          'remained_char_num': 0,
          'index': <Map<String, dynamic>>[],
          'is_limited': false,
          'is_purchased': false,
          'embedded_contents': [],
        },
      };

      final note = Note.fromJson(json);
      expect(note.html, '');
    });

    test('empty index produces empty indexItems', () {
      final json = {
        'data': {
          'key': 'n_empty_idx',
          'name': 'Empty Index',
          'body': '<p>body</p>',
          'eyecatch': null,
          'remained_char_num': 0,
          'index': <Map<String, dynamic>>[],
          'is_limited': false,
          'is_purchased': false,
          'embedded_contents': [],
        },
      };

      final note = Note.fromJson(json);
      expect(note.indexItems, isEmpty);
    });

    test('embedded_contents with data creates BookPurchaseLink', () {
      final json = {
        'data': {
          'key': 'n_book',
          'name': 'With Book',
          'body': '<p>body</p>',
          'eyecatch': null,
          'remained_char_num': 0,
          'index': <Map<String, dynamic>>[],
          'is_limited': true,
          'is_purchased': true,
          'embedded_contents': [
            {
              'url': 'https://example.com/book',
              'html_for_embed':
                  '<div><strong class="external-article-widget-title">Book Title</strong>'
                      '<em class="external-article-widget-regularprice">¥1500</em>'
                      '<a class="external-article-widget-image" style="background-image: url(\'https://example.com/book.jpg\');"></a></div>',
            }
          ],
        },
      };

      final note = Note.fromJson(json);
      expect(note.bookPurchaseLink, isNotNull);
      expect(note.bookPurchaseLink!.title, 'Book Title');
      expect(note.bookPurchaseLink!.price, '¥1500');
      expect(note.bookPurchaseLink!.url, 'https://example.com/book');
      expect(note.bookPurchaseLink!.imageUrl, 'https://example.com/book.jpg');
      expect(note.isLimited, isTrue);
      expect(note.isPurchased, isTrue);
    });
  });

  group('BookPurchaseLink.fromJson', () {
    test('extracts title, price, imageUrl from HTML embed', () {
      final json = {
        'url': 'https://example.com/purchase',
        'html_for_embed':
            '<div><strong class="external-article-widget-title">Ninja Book</strong>'
                '<em class="external-article-widget-regularprice">¥2000</em>'
                '<a class="external-article-widget-image" style="background-image: url(\'https://img.example.com/cover.jpg\');"></a></div>',
      };

      final link = BookPurchaseLink.fromJson(json);
      expect(link.title, 'Ninja Book');
      expect(link.price, '¥2000');
      expect(link.url, 'https://example.com/purchase');
      expect(link.imageUrl, 'https://img.example.com/cover.jpg');
    });

    test('missing elements fallback to empty strings', () {
      final json = {
        'url': 'https://example.com/book',
        'html_for_embed': '<div>No structured content</div>',
      };

      final link = BookPurchaseLink.fromJson(json);
      expect(link.title, '');
      expect(link.price, '');
      expect(link.url, 'https://example.com/book');
    });
  });

  group('BookPurchaseLink encode/fromDatabase', () {
    test('encode produces valid JSON', () {
      final link = BookPurchaseLink(
        title: 'Title',
        price: '¥100',
        url: 'https://example.com',
        imageUrl: 'https://example.com/img.png',
      );
      final encoded = link.encode();
      final decoded = BookPurchaseLink.fromDatabase(encoded);
      expect(decoded.title, 'Title');
      expect(decoded.price, '¥100');
      expect(decoded.url, 'https://example.com');
      expect(decoded.imageUrl, 'https://example.com/img.png');
    });

    test('encode with null imageUrl', () {
      final link = BookPurchaseLink(
        title: 'T',
        price: 'P',
        url: 'U',
        imageUrl: null,
      );
      final decoded = BookPurchaseLink.fromDatabase(link.encode());
      expect(decoded.imageUrl, isNull);
    });
  });

  group('Note model properties', () {
    test('canReadAll returns true when not limited', () {
      final note = Note(
        id: 'n1',
        title: 'T',
        html: '',
        remainedCharNum: 0,
        isLimited: false,
        isPurchased: false,
      );
      expect(note.canReadAll, isTrue);
    });

    test('canReadAll returns true when limited but purchased', () {
      final note = Note(
        id: 'n1',
        title: 'T',
        html: '',
        remainedCharNum: 100,
        isLimited: true,
        isPurchased: true,
      );
      expect(note.canReadAll, isTrue);
    });

    test('canReadAll returns false when limited and not purchased', () {
      final note = Note(
        id: 'n1',
        title: 'T',
        html: '',
        remainedCharNum: 100,
        isLimited: true,
        isPurchased: false,
      );
      expect(note.canReadAll, isFalse);
    });
  });

  group('Note.availableIndexItems', () {
    test('returns all indexItems when canReadAll is true', () {
      final indexItems = [
        IndexItem(id: 'sec1', title: 'Section 1'),
        IndexItem(id: 'sec2', title: 'N-Files'),
        IndexItem(id: 'sec3', title: 'Section 3'),
      ];
      final note = Note(
        id: 'n1',
        title: 'T',
        html: '',
        remainedCharNum: 0,
        indexItems: indexItems,
        isLimited: false,
        isPurchased: false,
      );
      expect(note.availableIndexItems.length, 3);
    });

    test('truncates at N-Files when limited and not purchased', () {
      final indexItems = [
        IndexItem(id: 'sec1', title: 'Section 1'),
        IndexItem(id: 'sec2', title: 'Section 2'),
        IndexItem(id: 'sec3', title: 'N-Files'),
        IndexItem(id: 'sec4', title: 'Section After'),
      ];
      final note = Note(
        id: 'n1',
        title: 'T',
        html: '',
        remainedCharNum: 100,
        indexItems: indexItems,
        isLimited: true,
        isPurchased: false,
      );
      final available = note.availableIndexItems;
      expect(available.length, 2);
      expect(available[0].title, 'Section 1');
      expect(available[1].title, 'Section 2');
    });

    test('handles n-file case-insensitive variants', () {
      final indexItems = [
        IndexItem(id: 'sec1', title: 'Section 1'),
        IndexItem(id: 'sec2', title: 'n-files'),
      ];
      final note = Note(
        id: 'n1',
        title: 'T',
        html: '',
        remainedCharNum: 100,
        indexItems: indexItems,
        isLimited: true,
        isPurchased: false,
      );
      expect(note.availableIndexItems.length, 1);
    });

    test('returns all when limited but no N-Files marker', () {
      final indexItems = [
        IndexItem(id: 'sec1', title: 'Section 1'),
        IndexItem(id: 'sec2', title: 'Section 2'),
      ];
      final note = Note(
        id: 'n1',
        title: 'T',
        html: '',
        remainedCharNum: 100,
        indexItems: indexItems,
        isLimited: true,
        isPurchased: false,
      );
      expect(note.availableIndexItems.length, 2);
    });
  });

  group('IndexItem encode/decode', () {
    test('roundtrip preserves data', () {
      final item = IndexItem(id: 'test-id', title: 'Test Title');
      final encoded = item.encode();
      final decoded = IndexItem.decode(encoded);
      expect(decoded.id, 'test-id');
      expect(decoded.title, 'Test Title');
    });
  });

  group('InputHistoryData', () {
    test('fromDatabase parses correctly', () {
      final data = InputHistoryData.fromDatabase({
        'value': 'search query',
        'created_at': '2024-06-15T10:30:00.000',
      });
      expect(data.value, 'search query');
      expect(data.createdAt, DateTime(2024, 6, 15, 10, 30, 0));
    });

    test('toJson produces valid JSON', () {
      final data = InputHistoryData(
        value: 'test',
        createdAt: DateTime(2024, 1, 1),
      );
      final json = data.toJson();
      expect(json, contains('test'));
      expect(json, contains('2024'));
    });
  });
}
