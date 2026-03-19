import 'package:flutter_test/flutter_test.dart';
import 'package:ninja_scrolls/src/gateway/database/episode_search_history.dart';
import 'package:ninja_scrolls/src/gateway/database/note.dart';
import 'package:ninja_scrolls/src/gateway/database/read_state.dart';
import 'package:ninja_scrolls/src/gateway/database/sqlite.dart';
import 'package:ninja_scrolls/src/gateway/database/wiki.dart';

import '../../helpers/test_database_helper.dart';
import '../../helpers/test_note_factory.dart';

void main() {
  setUp(() async {
    await setupTestDatabase();
  });

  tearDown(() async {
    await tearDownTestDatabase();
  });

  group('DatabaseHelper.deleteAllTableData', () {
    test('clears notes and read_states tables', () async {
      // Insert notes
      await NoteGateway.save(createTestNote(id: 'n_del_1'));
      await NoteGateway.save(createTestNote(id: 'n_del_2'));

      // Insert read states
      await ReadStateGateway.updateStatus('n_del_1', ReadState.reading, 0.5, 0);
      await ReadStateGateway.updateStatus('n_del_2', ReadState.read, 1.0, 0);

      // deleteAllTableData
      await DatabaseHelper.instance.deleteAllTableData();

      // Verify notes cleared
      expect(await NoteGateway.isCached('n_del_1'), isFalse);
      expect(await NoteGateway.isCached('n_del_2'), isFalse);

      // Verify read states cleared
      final statuses = await ReadStateGateway.getStatus(['n_del_1', 'n_del_2']);
      expect(statuses['n_del_1']!.state, ReadState.notRead);
      expect(statuses['n_del_2']!.state, ReadState.notRead);
    });

    test('wiki_pages and search_history remain after deleteAllTableData',
        () async {
      // Insert wiki page
      final db = await DatabaseHelper.instance.database;
      await db!.insert(WikiPageTableGateway.tableName, {
        'title': 'TestWiki',
        'sanitized_title': 'testwiki',
        'endpoint': '/test',
        'created_at': DateTime.now().toIso8601String(),
      });

      // Insert search history
      await db.insert(EpisodeSearchHistoryGateway.tableName, {
        'value': 'test search',
        'created_at': DateTime.now().toIso8601String(),
      });

      // deleteAllTableData only affects notes + read_states
      await DatabaseHelper.instance.deleteAllTableData();

      // Wiki pages should still exist
      final wikiRows = await db.query(WikiPageTableGateway.tableName);
      expect(wikiRows.length, 1);
      expect(wikiRows.first['title'], 'TestWiki');

      // Search history should still exist
      final historyRows =
          await db.query(EpisodeSearchHistoryGateway.tableName);
      expect(historyRows.length, 1);
    });

    test('is idempotent on empty tables', () async {
      // Call on empty tables - should not throw
      await DatabaseHelper.instance.deleteAllTableData();
      await DatabaseHelper.instance.deleteAllTableData();

      expect(await NoteGateway.isCached('anything'), isFalse);
    });
  });
}
