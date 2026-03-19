import 'package:flutter_test/flutter_test.dart';
import 'package:ninja_scrolls/src/providers/episode_index_provider.dart';

import '../../helpers/test_note_factory.dart';

void main() {
  group('EpisodeIndexProvider', () {
    late EpisodeIndexProvider provider;

    setUp(() {
      provider = EpisodeIndexProvider();
      provider.testIndex = createTestIndex();
    });

    test('testIndex setter sets index', () {
      expect(provider.index, isNotNull);
    });

    group('getEpisodeLinkFromNoteId', () {
      test('returns episode link for existing note', () {
        final link = provider.getEpisodeLinkFromNoteId('n001');
        expect(link, isNotNull);
        expect(link!.title, 'Episode 1');
      });

      test('returns null for non-existent note', () {
        final link = provider.getEpisodeLinkFromNoteId('non_existent');
        expect(link, isNull);
      });

      test('returns null when index is null', () {
        provider.testIndex = null;
        final link = provider.getEpisodeLinkFromNoteId('n001');
        expect(link, isNull);
      });
    });

    group('getChapterIdbyEpisodeNoteId', () {
      test('returns chapter id for trilogy episode', () {
        expect(provider.getChapterIdbyEpisodeNoteId('n001'), 0);
        expect(provider.getChapterIdbyEpisodeNoteId('n003'), 1);
        expect(provider.getChapterIdbyEpisodeNoteId('n004'), 2);
      });

      test('returns chapter id for AoM episode', () {
        expect(provider.getChapterIdbyEpisodeNoteId('n006'), 3);
      });

      test('returns -1 for non-existent note', () {
        expect(provider.getChapterIdbyEpisodeNoteId('non_existent'), -1);
      });

      test('returns -1 when index is null', () {
        provider.testIndex = null;
        expect(provider.getChapterIdbyEpisodeNoteId('n001'), -1);
      });
    });

    group('getChapterById', () {
      test('returns chapter for existing id', () {
        final chapter = provider.getChapterById(0);
        expect(chapter, isNotNull);
        expect(chapter!.title, 'Neo Saitama');
      });

      test('returns null for non-existent id', () {
        expect(provider.getChapterById(99), isNull);
      });

      test('returns null when index is null', () {
        provider.testIndex = null;
        expect(provider.getChapterById(0), isNull);
      });
    });

    group('previous', () {
      test('returns previous episode in same chapter', () {
        final ep2 = provider.getEpisodeLinkFromNoteId('n002')!;
        final prev = provider.previous(ep2);
        expect(prev, isNotNull);
        expect(prev!.noteId, 'n001');
      });

      test('returns previous episode across chapter boundary', () {
        final ep3 = provider.getEpisodeLinkFromNoteId('n003')!;
        final prev = provider.previous(ep3);
        expect(prev, isNotNull);
        expect(prev!.noteId, 'n002');
      });

      test('returns null for first episode', () {
        final ep1 = provider.getEpisodeLinkFromNoteId('n001')!;
        final prev = provider.previous(ep1);
        expect(prev, isNull);
      });

      test('returns null when index is null', () {
        provider.testIndex = null;
        final link = createTestEpisodeLink(noteId: 'n001');
        expect(provider.previous(link), isNull);
      });
    });

    group('next', () {
      test('returns next episode in same chapter', () {
        final ep1 = provider.getEpisodeLinkFromNoteId('n001')!;
        final nxt = provider.next(ep1);
        expect(nxt, isNotNull);
        expect(nxt!.noteId, 'n002');
      });

      test('returns next episode across chapter boundary', () {
        final ep2 = provider.getEpisodeLinkFromNoteId('n002')!;
        final nxt = provider.next(ep2);
        expect(nxt, isNotNull);
        expect(nxt!.noteId, 'n003');
      });

      test('returns null for last episode', () {
        final lastEp = provider.getEpisodeLinkFromNoteId('n006')!;
        final nxt = provider.next(lastEp);
        expect(nxt, isNull);
      });

      test('returns null when index is null', () {
        provider.testIndex = null;
        final link = createTestEpisodeLink(noteId: 'n001');
        expect(provider.next(link), isNull);
      });
    });

    group('getEpisodeLinksByNoteIds', () {
      test('returns links for existing notes', () {
        final links = provider.getEpisodeLinksByNoteIds(['n001', 'n003']);
        expect(links.length, 2);
        expect(links[0]!.noteId, 'n001');
        expect(links[1]!.noteId, 'n003');
      });

      test('returns null entries for missing notes', () {
        final links =
            provider.getEpisodeLinksByNoteIds(['n001', 'non_existent']);
        expect(links.length, 2);
        expect(links[0]!.noteId, 'n001');
        expect(links[1], isNull);
      });

      test('returns empty list when index is null', () {
        provider.testIndex = null;
        final links = provider.getEpisodeLinksByNoteIds(['n001']);
        expect(links, isEmpty);
      });
    });

    group('getChapterIdbyEpisodeNoteIds', () {
      test('returns map of note ids to chapter ids', () {
        final map =
            provider.getChapterIdbyEpisodeNoteIds(['n001', 'n003', 'n006']);
        expect(map['n001'], 0);
        expect(map['n003'], 1);
        expect(map['n006'], 3);
      });

      test('returns empty map when index is null', () {
        provider.testIndex = null;
        final map = provider.getChapterIdbyEpisodeNoteIds(['n001']);
        expect(map, isEmpty);
      });
    });
  });
}
