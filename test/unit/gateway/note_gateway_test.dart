import 'package:flutter_test/flutter_test.dart';
import 'package:ninja_scrolls/src/gateway/database/note.dart';
import 'package:ninja_scrolls/src/gateway/database/read_state.dart';


import '../../helpers/test_database_helper.dart';
import '../../helpers/test_note_factory.dart';

void main() {
  setUp(() async {
    await setupTestDatabase();
  });

  tearDown(() async {
    await tearDownTestDatabase();
  });

  group('NoteGateway', () {
    test('isCached returns false for non-existent note', () async {
      expect(await NoteGateway.isCached('non_existent'), isFalse);
    });

    test('isCached returns true after save', () async {
      final note = createTestNote(id: 'n_test_1');
      await NoteGateway.save(note);
      expect(await NoteGateway.isCached('n_test_1'), isTrue);
    });

    test('save inserts new note', () async {
      final note = createTestNote(id: 'n_save_1', title: 'Original Title');
      await NoteGateway.save(note);
      final loaded = await NoteGateway.load('n_save_1');
      expect(loaded.title, 'Original Title');
    });

    test('save updates existing note (upsert)', () async {
      final note1 = createTestNote(id: 'n_upsert', title: 'Title 1');
      await NoteGateway.save(note1);
      final note2 = createTestNote(id: 'n_upsert', title: 'Title 2');
      await NoteGateway.save(note2);
      final loaded = await NoteGateway.load('n_upsert');
      expect(loaded.title, 'Title 2');
    });

    test('load returns saved note with correct fields', () async {
      final indexItems = [
        IndexItem(id: 'sec1', title: 'Section 1'),
        IndexItem(id: 'sec2', title: 'Section 2'),
      ];
      final note = createTestNote(
        id: 'n_load_1',
        title: 'Test Title',
        html: '<p>Hello</p>',
        eyecatchUrl: 'https://example.com/img.png',
        remainedCharNum: 42,
        indexItems: indexItems,
        isLimited: true,
        isPurchased: false,
        bookPurchaseLink: BookPurchaseLink(
          title: 'Book',
          price: '¥1000',
          url: 'https://example.com/book',
          imageUrl: 'https://example.com/book.jpg',
        ),
      );
      await NoteGateway.save(note);
      final loaded = await NoteGateway.load('n_load_1');

      expect(loaded.id, 'n_load_1');
      expect(loaded.title, 'Test Title');
      expect(loaded.html, '<p>Hello</p>');
      expect(loaded.eyecatchUrl, 'https://example.com/img.png');
      expect(loaded.remainedCharNum, 42);
      expect(loaded.indexItems.length, 2);
      expect(loaded.indexItems[0].id, 'sec1');
      expect(loaded.indexItems[1].title, 'Section 2');
      expect(loaded.isLimited, isTrue);
      expect(loaded.bookPurchaseLink, isNotNull);
      expect(loaded.bookPurchaseLink!.title, 'Book');
    });

    test('cachedAt returns null for non-existent note', () async {
      expect(await NoteGateway.cachedAt('non_existent'), isNull);
    });

    test('cachedAt returns DateTime after save', () async {
      final note = createTestNote(id: 'n_cached_at');
      await NoteGateway.save(note);
      final cachedAt = await NoteGateway.cachedAt('n_cached_at');
      expect(cachedAt, isNotNull);
      expect(cachedAt, isA<DateTime>());
    });

    test('recentRead returns notes ordered by recentReadAt DESC', () async {
      final note1 = createTestNote(
        id: 'n_recent_1',
        recentReadAt: DateTime(2024, 1, 1),
      );
      final note2 = createTestNote(
        id: 'n_recent_2',
        recentReadAt: DateTime(2024, 1, 3),
      );
      final note3 = createTestNote(
        id: 'n_recent_3',
        recentReadAt: DateTime(2024, 1, 2),
      );
      await NoteGateway.save(note1);
      await NoteGateway.save(note2);
      await NoteGateway.save(note3);

      final recent = await NoteGateway.recentRead(10);
      expect(recent.length, 3);
      expect(recent[0].id, 'n_recent_2');
      expect(recent[1].id, 'n_recent_3');
      expect(recent[2].id, 'n_recent_1');
    });

    test('recentRead respects count limit', () async {
      for (int i = 0; i < 5; i++) {
        await NoteGateway.save(createTestNote(
          id: 'n_limit_$i',
          recentReadAt: DateTime(2024, 1, i + 1),
        ));
      }
      final recent = await NoteGateway.recentRead(3);
      expect(recent.length, 3);
    });

    test('deleteAll removes all notes', () async {
      await NoteGateway.save(createTestNote(id: 'n_del_1'));
      await NoteGateway.save(createTestNote(id: 'n_del_2'));
      await NoteGateway.deleteAll();
      expect(await NoteGateway.isCached('n_del_1'), isFalse);
      expect(await NoteGateway.isCached('n_del_2'), isFalse);
    });

    test('delete removes specific note', () async {
      await NoteGateway.save(createTestNote(id: 'n_del_a'));
      await NoteGateway.save(createTestNote(id: 'n_del_b'));
      await NoteGateway.delete('n_del_a');
      expect(await NoteGateway.isCached('n_del_a'), isFalse);
      expect(await NoteGateway.isCached('n_del_b'), isTrue);
    });

    test('resetRecentReadAt clears all recentReadAt values', () async {
      await NoteGateway.save(createTestNote(
        id: 'n_reset_1',
        recentReadAt: DateTime(2024, 1, 1),
      ));
      await NoteGateway.save(createTestNote(
        id: 'n_reset_2',
        recentReadAt: DateTime(2024, 1, 2),
      ));

      await NoteGateway.resetRecentReadAt();

      final recent = await NoteGateway.recentRead(10);
      expect(recent, isEmpty);

      // Notes themselves still exist
      expect(await NoteGateway.isCached('n_reset_1'), isTrue);
      expect(await NoteGateway.isCached('n_reset_2'), isTrue);
    });

    test('save note without recentReadAt stores null', () async {
      await NoteGateway.save(createTestNote(
        id: 'n_no_recent',
        recentReadAt: null,
      ));
      final loaded = await NoteGateway.load('n_no_recent');
      expect(loaded.recentReadAt, isNull);
    });

    test('recentRead excludes notes with null recentReadAt', () async {
      await NoteGateway.save(createTestNote(
        id: 'n_with_recent',
        recentReadAt: DateTime(2024, 1, 1),
      ));
      await NoteGateway.save(createTestNote(
        id: 'n_without_recent',
        recentReadAt: null,
      ));

      final recent = await NoteGateway.recentRead(10);
      expect(recent.length, 1);
      expect(recent[0].id, 'n_with_recent');
    });

    test('save preserves recentReadAt on update', () async {
      final originalTime = DateTime(2024, 6, 15);
      await NoteGateway.save(createTestNote(
        id: 'n_preserve',
        title: 'Original',
        recentReadAt: originalTime,
      ));
      await NoteGateway.save(createTestNote(
        id: 'n_preserve',
        title: 'Updated',
        recentReadAt: originalTime,
      ));
      final loaded = await NoteGateway.load('n_preserve');
      expect(loaded.title, 'Updated');
      expect(loaded.recentReadAt, isNotNull);
    });
  });
}
