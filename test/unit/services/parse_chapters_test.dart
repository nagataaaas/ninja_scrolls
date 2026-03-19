import 'package:flutter_test/flutter_test.dart';
import 'package:ninja_scrolls/src/gateway/database/note.dart';
import 'package:ninja_scrolls/src/services/parser/parse_chapters.dart';

// Minimal HTML fixture that parseChapters can parse.
// It must contain:
//  - A title with a date like "2024/01/15"
//  - An h2 containing "ネオサイタマ炎上" followed by content
//  - Two more h2 sections (Kyoto Hell, Never Dies) for trilogy
//  - An h2 "AoM本編" followed by h3 sections for AoM chapters

const _testHtml = '''
<h2>◆「ネオサイタマ炎上」編◆</h2>
<p>ネオサイタマの説明<br></p>
<p>◆ グループA</p>
<p><a href="https://note.com/nj/n001">【エピソード1】</a><a href="https://note.com/nj/n002">【エピソード2】</a></p>
<h2>◆「キョート殺伐都市」編◆</h2>
<p>キョートの説明<br></p>
<p><a href="https://note.com/nj/n003">【エピソード3】</a></p>
<h2>◆「ネヴァーダイズ」編◆</h2>
<p>ネヴァーダイズの説明<br></p>
<p><a href="https://note.com/nj/n004">【エピソード4】</a></p>
<h2>AoM本編</h2>
<p>AoMの説明</p>
<h3>シーズン1：テストシーズン</h3>
<p>シーズン1の説明<br></p>
<p><a href="https://note.com/nj/n005">【エピソード5】</a></p>
''';

void main() {
  group('parseChapters', () {
    test('parses trilogy and aom sections', () {
      final note = Note(
        id: 'toc',
        title: '目次 2024/01/15 更新',
        html: _testHtml,
        remainedCharNum: 0,
        isLimited: false,
        isPurchased: false,
      );
      final index = parseChapters(note);

      expect(index.updatedAt, DateTime(2024, 1, 15));
      expect(index.trilogy.length, 3);
      expect(index.aom.length, greaterThanOrEqualTo(1));
    });

    test('extracts updatedAt from title', () {
      final note = Note(
        id: 'toc',
        title: '目次 2024/03/20 更新',
        html: _testHtml,
        remainedCharNum: 0,
        isLimited: false,
        isPurchased: false,
      );
      final index = parseChapters(note);
      expect(index.updatedAt, DateTime(2024, 3, 20));
    });

    test('handles title without date', () {
      final note = Note(
        id: 'toc',
        title: '目次',
        html: _testHtml,
        remainedCharNum: 0,
        isLimited: false,
        isPurchased: false,
      );
      final index = parseChapters(note);
      expect(index.updatedAt, isNull);
    });
  });

  group('parseNeoSaitama', () {
    test('extracts title and episode links', () {
      final note = Note(
        id: 'toc',
        title: '目次 2024/01/15',
        html: _testHtml,
        remainedCharNum: 0,
        isLimited: false,
        isPurchased: false,
      );
      final index = parseChapters(note);
      final chapter = index.trilogy[0];

      expect(chapter.id, 0);
      expect(chapter.title, contains('ネオサイタマ炎上'));
      expect(chapter.episodeLinks.length, 2);
      expect(chapter.episodeLinks[0].noteId, 'n001');
      expect(chapter.episodeLinks[1].noteId, 'n002');
    });

    test('extracts group names', () {
      final note = Note(
        id: 'toc',
        title: '目次 2024/01/15',
        html: _testHtml,
        remainedCharNum: 0,
        isLimited: false,
        isPurchased: false,
      );
      final index = parseChapters(note);
      final chapter = index.trilogy[0];
      final group = chapter.chapterChildren
          .where((c) => c.isEpisodeLinkGroup)
          .first
          .episodeLinkGroup!;
      expect(group.groupName, contains('グループA'));
    });
  });

  group('parseKyotoHell', () {
    test('extracts single group of links', () {
      final note = Note(
        id: 'toc',
        title: '目次 2024/01/15',
        html: _testHtml,
        remainedCharNum: 0,
        isLimited: false,
        isPurchased: false,
      );
      final index = parseChapters(note);
      final chapter = index.trilogy[1];

      expect(chapter.id, 1);
      expect(chapter.episodeLinks.length, 1);
      expect(chapter.episodeLinks[0].noteId, 'n003');
    });
  });

  group('parseNeverDies', () {
    test('extracts links', () {
      final note = Note(
        id: 'toc',
        title: '目次 2024/01/15',
        html: _testHtml,
        remainedCharNum: 0,
        isLimited: false,
        isPurchased: false,
      );
      final index = parseChapters(note);
      final chapter = index.trilogy[2];

      expect(chapter.id, 2);
      expect(chapter.episodeLinks.length, 1);
      expect(chapter.episodeLinks[0].noteId, 'n004');
    });
  });

  group('parseAoM', () {
    test('extracts season title and links', () {
      final note = Note(
        id: 'toc',
        title: '目次 2024/01/15',
        html: _testHtml,
        remainedCharNum: 0,
        isLimited: false,
        isPurchased: false,
      );
      final index = parseChapters(note);
      final aomChapter = index.aom[0];

      expect(aomChapter.id, 3);
      expect(aomChapter.title, contains('テストシーズン'));
      expect(aomChapter.episodeLinks.length, 1);
      expect(aomChapter.episodeLinks[0].noteId, 'n005');
    });
  });

  // Note: encode() prepends a type name string as the first element.
  // decode() expects to receive the full encoded list including the type tag.
  // Chapter.decode reads from input[0] as id (int), so it expects the list
  // without the type tag prefix. We test the encode output structure directly.

  group('Chapter encode', () {
    test('encode produces correct structure', () {
      final chapter = Chapter(
        id: 1,
        title: 'Test Chapter',
        description: 'A test chapter',
        chapterChildren: [
          ChapterChild.guide('Guide text here'),
        ],
        imagePath: 'assets/test.webp',
      );

      final encoded = chapter.encode();
      expect(encoded[0], 'Chapter');
      expect(encoded[1], 1);
      expect(encoded[2], 'Test Chapter');
      expect(encoded[3], 'A test chapter');
      expect(encoded[4], isList);
      expect(encoded[5], 'assets/test.webp');
    });
  });

  group('EpisodeLink encode/decode', () {
    test('encode produces correct structure', () {
      final link = EpisodeLink(title: 'Test Ep', noteId: 'n123', emoji: '🔥');
      final encoded = link.encode();
      expect(encoded[0], 'EpisodeLink');
      expect(encoded[1], 'Test Ep');
      expect(encoded[2], 'n123');
      expect(encoded[3], '🔥');
    });

    test('decode reads from encode output correctly', () {
      final link = EpisodeLink(title: 'Test Ep', noteId: 'n123', emoji: '🔥');
      final encoded = link.encode();
      // decode reads input[1] as title, input[2] as noteId, input[3] as emoji
      final decoded = EpisodeLink.decode(encoded);
      expect(decoded.title, 'Test Ep');
      expect(decoded.noteId, 'n123');
      expect(decoded.emoji, '🔥');
    });

    test('encode with null emoji', () {
      final link = EpisodeLink(title: 'Test Ep', noteId: 'n123', emoji: null);
      final encoded = link.encode();
      expect(encoded[0], 'EpisodeLink');
      expect(encoded[1], 'Test Ep');
      expect(encoded[2], 'n123');
      expect(encoded[3], isNull);
    });
  });

  group('EpisodeLinkGroup encode', () {
    test('encode produces correct structure', () {
      final group = EpisodeLinkGroup(
        groupName: 'Test Group',
        links: [
          EpisodeLink(title: 'Ep 1', noteId: 'n001'),
          EpisodeLink(title: 'Ep 2', noteId: 'n002'),
        ],
      );
      final encoded = group.encode();
      expect(encoded[0], 'EpisodeLinkGroup');
      expect(encoded[1], 'Test Group');
      expect(encoded[2], isList);
      expect((encoded[2] as List).length, 2);
    });
  });

  group('ChapterChild encode/decode', () {
    test('guide roundtrip', () {
      final child = ChapterChild.guide('Some guide text');
      final encoded = child.encode();
      // encode: ['ChapterChild', null, 'Some guide text']
      // decode: input[1] -> episodeLinkGroup (null), input[2] -> guide
      final decoded = ChapterChild.decode(encoded);

      expect(decoded.isGuide, isTrue);
      expect(decoded.guide, 'Some guide text');
      expect(decoded.isEpisodeLinkGroup, isFalse);
    });

    test('encode structure for episodeLinkGroup', () {
      final child = ChapterChild.episodeLinkGroup(
        EpisodeLinkGroup(
          groupName: null,
          links: [EpisodeLink(title: 'Ep', noteId: 'n001')],
        ),
      );
      final encoded = child.encode();
      expect(encoded[0], 'ChapterChild');
      expect(encoded[1], isList); // episodeLinkGroup.encode()
      expect(encoded[2], isNull); // guide
    });
  });
}
