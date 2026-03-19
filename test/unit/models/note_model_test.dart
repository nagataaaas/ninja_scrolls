import 'package:flutter_test/flutter_test.dart';
import 'package:ninja_scrolls/src/gateway/database/note.dart';
import 'package:ninja_scrolls/src/gateway/database/read_state.dart';

void main() {
  group('Note', () {
    test('canReadAll returns true when not limited', () {
      final note = Note(
        id: 'n001',
        title: 'Test',
        html: '<p>test</p>',
        remainedCharNum: 0,
        isLimited: false,
        isPurchased: false,
      );
      expect(note.canReadAll, isTrue);
    });

    test('canReadAll returns true when limited but purchased', () {
      final note = Note(
        id: 'n001',
        title: 'Test',
        html: '<p>test</p>',
        remainedCharNum: 100,
        isLimited: true,
        isPurchased: true,
      );
      expect(note.canReadAll, isTrue);
    });

    test('canReadAll returns false when limited and not purchased', () {
      final note = Note(
        id: 'n001',
        title: 'Test',
        html: '<p>test</p>',
        remainedCharNum: 100,
        isLimited: true,
        isPurchased: false,
      );
      expect(note.canReadAll, isFalse);
    });

    test('availableIndexItems returns all items when canReadAll', () {
      final items = [
        IndexItem(id: 'sec1', title: 'Section 1'),
        IndexItem(id: 'sec2', title: 'N-Files'),
        IndexItem(id: 'sec3', title: 'Section 3'),
      ];
      final note = Note(
        id: 'n001',
        title: 'Test',
        html: '<p>test</p>',
        remainedCharNum: 0,
        indexItems: items,
        isLimited: false,
        isPurchased: false,
      );
      expect(note.availableIndexItems.length, 3);
    });

    test('availableIndexItems filters at N-Files when not canReadAll', () {
      final items = [
        IndexItem(id: 'sec1', title: 'Section 1'),
        IndexItem(id: 'sec2', title: 'N-Files'),
        IndexItem(id: 'sec3', title: 'Section 3'),
      ];
      final note = Note(
        id: 'n001',
        title: 'Test',
        html: '<p>test</p>',
        remainedCharNum: 100,
        indexItems: items,
        isLimited: true,
        isPurchased: false,
      );
      expect(note.availableIndexItems.length, 1);
      expect(note.availableIndexItems.first.title, 'Section 1');
    });

    test('availableIndexItems handles n-files case insensitive', () {
      final items = [
        IndexItem(id: 'sec1', title: 'Section 1'),
        IndexItem(id: 'sec2', title: 'n-file'),
        IndexItem(id: 'sec3', title: 'Section 3'),
      ];
      final note = Note(
        id: 'n001',
        title: 'Test',
        html: '<p>test</p>',
        remainedCharNum: 100,
        indexItems: items,
        isLimited: true,
        isPurchased: false,
      );
      expect(note.availableIndexItems.length, 1);
    });
  });

  group('IndexItem encode/decode', () {
    test('roundtrip preserves data', () {
      final item = IndexItem(id: 'section_1', title: 'Test Section');
      final encoded = item.encode();
      final decoded = IndexItem.decode(encoded);
      expect(decoded.id, 'section_1');
      expect(decoded.title, 'Test Section');
    });

    test('roundtrip with special characters', () {
      final item = IndexItem(id: 'sec_jp', title: '日本語セクション');
      final encoded = item.encode();
      final decoded = IndexItem.decode(encoded);
      expect(decoded.id, 'sec_jp');
      expect(decoded.title, '日本語セクション');
    });
  });

  group('BookPurchaseLink', () {
    test('fromDatabase/encode roundtrip preserves data', () {
      final link = BookPurchaseLink(
        title: 'Test Book',
        price: '¥1000',
        url: 'https://example.com/book',
        imageUrl: 'https://example.com/image.jpg',
      );
      final encoded = link.encode();
      final decoded = BookPurchaseLink.fromDatabase(encoded);
      expect(decoded.title, 'Test Book');
      expect(decoded.price, '¥1000');
      expect(decoded.url, 'https://example.com/book');
      expect(decoded.imageUrl, 'https://example.com/image.jpg');
    });

    test('fromDatabase/encode roundtrip with null imageUrl', () {
      final link = BookPurchaseLink(
        title: 'Test Book',
        price: '¥500',
        url: 'https://example.com/book',
        imageUrl: null,
      );
      final encoded = link.encode();
      final decoded = BookPurchaseLink.fromDatabase(encoded);
      expect(decoded.title, 'Test Book');
      expect(decoded.imageUrl, isNull);
    });
  });
}
