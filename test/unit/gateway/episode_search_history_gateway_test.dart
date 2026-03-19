import 'package:flutter_test/flutter_test.dart';
import 'package:ninja_scrolls/src/gateway/database/episode_search_history.dart';

import '../../helpers/test_database_helper.dart';

void main() {
  setUp(() async {
    await setupTestDatabase();
  });

  tearDown(() async {
    await tearDownTestDatabase();
  });

  group('EpisodeSearchHistoryGateway', () {
    test('all returns empty list initially', () async {
      final history = await EpisodeSearchHistoryGateway.all;
      expect(history, isEmpty);
    });

    test('addOrTouch adds new entry', () async {
      await EpisodeSearchHistoryGateway.addOrTouch('ニンジャ');
      final history = await EpisodeSearchHistoryGateway.all;
      expect(history.length, 1);
      expect(history.first.value, 'ニンジャ');
    });

    test('addOrTouch updates timestamp for existing entry', () async {
      await EpisodeSearchHistoryGateway.addOrTouch('ニンジャ');
      final beforeHistory = await EpisodeSearchHistoryGateway.all;
      final beforeTime = beforeHistory.first.createdAt;

      // Small delay to ensure different timestamp
      await Future.delayed(const Duration(milliseconds: 20));

      await EpisodeSearchHistoryGateway.addOrTouch('ニンジャ');
      final afterHistory = await EpisodeSearchHistoryGateway.all;
      expect(afterHistory.length, 1); // still one entry
      expect(afterHistory.first.createdAt.isAfter(beforeTime), isTrue);
    });

    test('addOrTouch prunes oldest entries when exceeding limit', () async {
      // The pruning logic keeps the newest 30 entries + the one at offset 30,
      // and deletes everything older than the entry at offset 30.
      // With 32 entries, only 1 entry older than offset 30 gets deleted -> 31 remain.
      for (int i = 0; i < 35; i++) {
        await EpisodeSearchHistoryGateway.addOrTouch('query_$i');
        // Tiny delay to ensure unique timestamps
        await Future.delayed(const Duration(milliseconds: 5));
      }
      final history = await EpisodeSearchHistoryGateway.all;
      // Pruning removes entries older than the 30th newest, so 31 remain
      expect(history.length, lessThanOrEqualTo(31));
      // The oldest entries should have been pruned
      expect(history.any((h) => h.value == 'query_34'), isTrue); // newest kept
    });

    test('remove deletes specific entry', () async {
      await EpisodeSearchHistoryGateway.addOrTouch('queryA');
      await Future.delayed(const Duration(milliseconds: 10));
      await EpisodeSearchHistoryGateway.addOrTouch('queryB');
      await EpisodeSearchHistoryGateway.remove('queryA');
      final history = await EpisodeSearchHistoryGateway.all;
      expect(history.length, 1);
      expect(history.first.value, 'queryB');
    });

    test('deleteAll removes all entries', () async {
      await EpisodeSearchHistoryGateway.addOrTouch('q1');
      await Future.delayed(const Duration(milliseconds: 10));
      await EpisodeSearchHistoryGateway.addOrTouch('q2');
      await EpisodeSearchHistoryGateway.deleteAll();
      final history = await EpisodeSearchHistoryGateway.all;
      expect(history, isEmpty);
    });

    test('all returns entries ordered by created_at DESC', () async {
      await EpisodeSearchHistoryGateway.addOrTouch('first');
      await Future.delayed(const Duration(milliseconds: 10));
      await EpisodeSearchHistoryGateway.addOrTouch('second');
      await Future.delayed(const Duration(milliseconds: 10));
      await EpisodeSearchHistoryGateway.addOrTouch('third');

      final history = await EpisodeSearchHistoryGateway.all;
      expect(history[0].value, 'third');
      expect(history[1].value, 'second');
      expect(history[2].value, 'first');
    });
  });
}
