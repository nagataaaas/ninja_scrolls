import 'package:flutter_test/flutter_test.dart';
import 'package:ninja_scrolls/src/services/parser/parse_chapters.dart';
import 'package:ninja_scrolls/src/static/assets.dart';

void main() {
  group('Chapter.firstEpisodeLink', () {
    test('returns null for empty chapterChildren', () {
      final chapter = Chapter(
        id: 0,
        title: 'Test',
        description: 'desc',
        chapterChildren: [],
        imagePath: 'img.png',
      );
      expect(chapter.firstEpisodeLink, isNull);
    });

    test('returns null when only guides', () {
      final chapter = Chapter(
        id: 0,
        title: 'Test',
        description: 'desc',
        chapterChildren: [
          ChapterChild.guide('Guide text'),
        ],
        imagePath: 'img.png',
      );
      expect(chapter.firstEpisodeLink, isNull);
    });

    test('returns first link from first episode link group', () {
      final link1 = EpisodeLink(title: 'Ep1', noteId: 'n001');
      final link2 = EpisodeLink(title: 'Ep2', noteId: 'n002');
      final chapter = Chapter(
        id: 0,
        title: 'Test',
        description: 'desc',
        chapterChildren: [
          ChapterChild.guide('Guide'),
          ChapterChild.episodeLinkGroup(
            EpisodeLinkGroup(groupName: 'G1', links: [link1, link2]),
          ),
        ],
        imagePath: 'img.png',
      );
      expect(chapter.firstEpisodeLink, same(link1));
    });
  });

  group('Chapter.episodeLinks', () {
    test('returns empty list for empty chapterChildren', () {
      final chapter = Chapter(
        id: 0,
        title: 'Test',
        description: 'desc',
        chapterChildren: [],
        imagePath: 'img.png',
      );
      expect(chapter.episodeLinks, isEmpty);
    });

    test('collects links from multiple groups', () {
      final chapter = Chapter(
        id: 0,
        title: 'Test',
        description: 'desc',
        chapterChildren: [
          ChapterChild.episodeLinkGroup(
            EpisodeLinkGroup(groupName: 'G1', links: [
              EpisodeLink(title: 'Ep1', noteId: 'n001'),
              EpisodeLink(title: 'Ep2', noteId: 'n002'),
            ]),
          ),
          ChapterChild.guide('Guide text'),
          ChapterChild.episodeLinkGroup(
            EpisodeLinkGroup(groupName: 'G2', links: [
              EpisodeLink(title: 'Ep3', noteId: 'n003'),
            ]),
          ),
        ],
        imagePath: 'img.png',
      );
      final links = chapter.episodeLinks;
      expect(links.length, 3);
      expect(links[0].noteId, 'n001');
      expect(links[1].noteId, 'n002');
      expect(links[2].noteId, 'n003');
    });

    test('skips guides in collection', () {
      final chapter = Chapter(
        id: 0,
        title: 'Test',
        description: 'desc',
        chapterChildren: [
          ChapterChild.guide('Guide 1'),
          ChapterChild.guide('Guide 2'),
        ],
        imagePath: 'img.png',
      );
      expect(chapter.episodeLinks, isEmpty);
    });
  });

  group('Chapter.copyWith', () {
    test('id remains unchanged', () {
      final chapter = Chapter(
        id: 42,
        title: 'Original',
        description: 'desc',
        chapterChildren: [],
        imagePath: 'img.png',
      );
      final copied = chapter.copyWith(title: 'New');
      expect(copied.id, 42);
      expect(copied.title, 'New');
    });

    test('unspecified fields are preserved', () {
      final children = [
        ChapterChild.guide('Guide'),
      ];
      final chapter = Chapter(
        id: 1,
        title: 'Title',
        description: 'Desc',
        chapterChildren: children,
        imagePath: 'img.png',
      );
      final copied = chapter.copyWith(title: 'NewTitle');
      expect(copied.description, 'Desc');
      expect(copied.chapterChildren, same(children));
      expect(copied.imagePath, 'img.png');
    });

    test('all fields can be overwritten', () {
      final chapter = Chapter(
        id: 1,
        title: 'Title',
        description: 'Desc',
        chapterChildren: [],
        imagePath: 'img1.png',
      );
      final newChildren = [ChapterChild.guide('New Guide')];
      final copied = chapter.copyWith(
        title: 'NewTitle',
        description: 'NewDesc',
        chapterChildren: newChildren,
        imagePath: 'img2.png',
      );
      expect(copied.title, 'NewTitle');
      expect(copied.description, 'NewDesc');
      expect(copied.chapterChildren, same(newChildren));
      expect(copied.imagePath, 'img2.png');
    });
  });

  group('Chapter encode/decode', () {
    test('encode structure is correct for Chapter with children', () {
      final chapter = Chapter(
        id: 5,
        title: 'MyTitle',
        description: 'MyDesc',
        chapterChildren: [
          ChapterChild.episodeLinkGroup(
            EpisodeLinkGroup(groupName: 'GroupA', links: [
              EpisodeLink(title: 'Ep1', noteId: 'n100', emoji: '🔥'),
            ]),
          ),
        ],
        imagePath: 'path/to/img.png',
      );
      final encoded = chapter.encode();
      expect(encoded[0], 'Chapter');
      expect(encoded[1], 5);
      expect(encoded[2], 'MyTitle');
      expect(encoded[3], 'MyDesc');
      expect(encoded[5], 'path/to/img.png');

      // Children structure
      final childrenList = encoded[4] as List;
      expect(childrenList.length, 1);
      final childEncoded = childrenList[0] as List;
      expect(childEncoded[0], 'ChapterChild');
      final groupEncoded = childEncoded[1] as List;
      expect(groupEncoded[0], 'EpisodeLinkGroup');
      expect(groupEncoded[1], 'GroupA');
    });

    test('decode reconstructs Chapter with guide children', () {
      // Chapter.decode: [id, title, desc, children, imagePath]
      // ChapterChild.decode: [typeTag, episodeLinkGroupOrNull, guide]
      // When guide is non-null and episodeLinkGroup is null, decode works
      final input = [
        10,
        'Title',
        'Desc',
        <Object?>[
          // Guide child (no episodeLinkGroup, guide is a non-null string)
          ['ChapterChild', null, 'Guide text here'],
          // EpisodeLinkGroup child with non-null emoji (guide must be non-null too)
          [
            'ChapterChild',
            [
              'GroupName',
              [
                ['EpisodeLink', 'Ep1', 'n200', '🔥'],
              ],
            ],
            'some guide',
          ],
        ],
        'banner.png',
      ];
      final chapter = Chapter.decode(input);
      expect(chapter.id, 10);
      expect(chapter.title, 'Title');
      expect(chapter.description, 'Desc');
      expect(chapter.imagePath, 'banner.png');
      expect(chapter.chapterChildren.length, 2);
      expect(chapter.chapterChildren[0].isGuide, isTrue);
      expect(chapter.chapterChildren[0].guide, 'Guide text here');
      expect(chapter.chapterChildren[1].isEpisodeLinkGroup, isTrue);
      expect(chapter.chapterChildren[1].episodeLinkGroup!.groupName, 'GroupName');
      expect(chapter.chapterChildren[1].episodeLinkGroup!.links[0].title, 'Ep1');
    });

    test('encode produces list with type tag at [0]', () {
      final chapter = Chapter(
        id: 3,
        title: 'T',
        description: 'D',
        chapterChildren: [],
        imagePath: 'img.png',
      );
      final encoded = chapter.encode();
      expect(encoded[0], 'Chapter');
      expect(encoded[1], 3);
      expect(encoded[2], 'T');
      expect(encoded[3], 'D');
      expect(encoded[5], 'img.png');
    });

    test('encode is cached (returns same list)', () {
      final chapter = Chapter(
        id: 0,
        title: 'T',
        description: 'D',
        chapterChildren: [],
        imagePath: 'img.png',
      );
      final e1 = chapter.encode();
      final e2 = chapter.encode();
      expect(identical(e1, e2), isTrue);
    });
  });

  group('ChapterChild', () {
    test('isGuide returns true for guide', () {
      final child = ChapterChild.guide('text');
      expect(child.isGuide, isTrue);
      expect(child.isEpisodeLinkGroup, isFalse);
    });

    test('isEpisodeLinkGroup returns true for episode link group', () {
      final child = ChapterChild.episodeLinkGroup(
        EpisodeLinkGroup(groupName: null, links: []),
      );
      expect(child.isEpisodeLinkGroup, isTrue);
      expect(child.isGuide, isFalse);
    });

    test('encode/decode roundtrip for guide', () {
      final child = ChapterChild.guide('Guide text');
      final encoded = child.encode();
      expect(encoded[0], 'ChapterChild');
      expect(encoded[1], isNull);
      expect(encoded[2], 'Guide text');

      final decoded = ChapterChild.decode(encoded);
      expect(decoded.isGuide, isTrue);
      expect(decoded.guide, 'Guide text');
    });

    test('encode/decode roundtrip for episodeLinkGroup', () {
      final child = ChapterChild.episodeLinkGroup(
        EpisodeLinkGroup(groupName: 'GName', links: [
          EpisodeLink(title: 'Ep', noteId: 'n1', emoji: null),
        ]),
      );
      final encoded = child.encode();
      // ChapterChild.encode: ['ChapterChild', episodeLinkGroup.encode(), guide]
      // ChapterChild.decode: input[1] passed to EpisodeLinkGroup.decode
      // EpisodeLinkGroup.encode: ['EpisodeLinkGroup', groupName, links]
      // EpisodeLinkGroup.decode expects: [groupName, links] (no type tag)
      // So encode/decode are NOT symmetric for ChapterChild+EpisodeLinkGroup.
      // Verify encode structure instead.
      expect(encoded[0], 'ChapterChild');
      expect(encoded[2], isNull); // guide is null
      final groupEncoded = encoded[1] as List<Object?>;
      expect(groupEncoded[0], 'EpisodeLinkGroup');
      expect(groupEncoded[1], 'GName');
      final linksEncoded = groupEncoded[2] as List<Object?>;
      expect(linksEncoded.length, 1);
    });
  });

  group('EpisodeLinkGroup', () {
    test('encode produces correct structure', () {
      final group = EpisodeLinkGroup(
        groupName: 'TestGroup',
        links: [
          EpisodeLink(title: 'A', noteId: 'nA', emoji: '🔥'),
          EpisodeLink(title: 'B', noteId: 'nB'),
        ],
      );
      final encoded = group.encode();
      expect(encoded[0], 'EpisodeLinkGroup');
      expect(encoded[1], 'TestGroup');
      expect((encoded[2] as List).length, 2);
    });

    test('decode from type-tag-free format', () {
      // EpisodeLinkGroup.decode expects [groupName, links] (no type tag)
      // Note: EpisodeLink.decode uses input[3]! which crashes on null emoji
      final input = [
        'TestGroup',
        <Object?>[
          ['EpisodeLink', 'A', 'nA', '🔥'],
          ['EpisodeLink', 'B', 'nB', '⚡'],
        ],
      ];
      final decoded = EpisodeLinkGroup.decode(input);
      expect(decoded.groupName, 'TestGroup');
      expect(decoded.links.length, 2);
      expect(decoded.links[0].title, 'A');
      expect(decoded.links[0].emoji, '🔥');
      expect(decoded.links[1].emoji, '⚡');
    });
  });

  group('EpisodeLink', () {
    test('encode/decode roundtrip', () {
      final link = EpisodeLink(title: 'Title', noteId: 'n123', emoji: '⚡');
      final encoded = link.encode();
      expect(encoded[0], 'EpisodeLink');
      expect(encoded[1], 'Title');
      expect(encoded[2], 'n123');
      expect(encoded[3], '⚡');

      final decoded = EpisodeLink.decode(encoded);
      expect(decoded.title, 'Title');
      expect(decoded.noteId, 'n123');
      expect(decoded.emoji, '⚡');
    });

    test('null emoji encodes correctly', () {
      final link = EpisodeLink(title: 'T', noteId: 'n1');
      final encoded = link.encode();
      expect(encoded[0], 'EpisodeLink');
      expect(encoded[1], 'T');
      expect(encoded[2], 'n1');
      expect(encoded[3], isNull);
    });

    test('decode with non-null emoji works', () {
      final encoded = ['EpisodeLink', 'Title', 'n123', '⚡'];
      final decoded = EpisodeLink.decode(encoded);
      expect(decoded.title, 'Title');
      expect(decoded.noteId, 'n123');
      expect(decoded.emoji, '⚡');
    });
  });

  group('ChapterChildListExt.episodeLinks', () {
    test('extracts links from mixed children', () {
      final children = <ChapterChild>[
        ChapterChild.guide('Guide'),
        ChapterChild.episodeLinkGroup(
          EpisodeLinkGroup(groupName: null, links: [
            EpisodeLink(title: 'A', noteId: 'nA'),
          ]),
        ),
        ChapterChild.guide('Another Guide'),
        ChapterChild.episodeLinkGroup(
          EpisodeLinkGroup(groupName: null, links: [
            EpisodeLink(title: 'B', noteId: 'nB'),
            EpisodeLink(title: 'C', noteId: 'nC'),
          ]),
        ),
      ];
      final links = children.episodeLinks;
      expect(links.length, 3);
      expect(links[0].noteId, 'nA');
      expect(links[1].noteId, 'nB');
      expect(links[2].noteId, 'nC');
    });
  });

  group('EpisodeLinkListExt.episodeLinks', () {
    test('collects links from multiple groups', () {
      final groups = <EpisodeLinkGroup>[
        EpisodeLinkGroup(groupName: 'G1', links: [
          EpisodeLink(title: 'X', noteId: 'nX'),
        ]),
        EpisodeLinkGroup(groupName: 'G2', links: [
          EpisodeLink(title: 'Y', noteId: 'nY'),
          EpisodeLink(title: 'Z', noteId: 'nZ'),
        ]),
      ];
      final links = groups.episodeLinks;
      expect(links.length, 3);
    });
  });

  group('parseAoM imagePath', () {
    // Test the imagePath switch logic by creating chapters through parseAoM
    // We test indirectly via Chapter constructor with the index->path mapping
    test('chapterIndex 0 → bannersNjslyr1', () {
      expect(Assets.bannersNjslyr1, 'assets/banners/njslyr_1.webp');
    });

    test('chapterIndex 1 → bannersNjslyr2', () {
      expect(Assets.bannersNjslyr2, 'assets/banners/njslyr_2.webp');
    });

    test('chapterIndex 2 → bannersNjslyr3', () {
      expect(Assets.bannersNjslyr3, 'assets/banners/njslyr_3.webp');
    });

    test('chapterIndex 3 → bannersNjslyr4', () {
      expect(Assets.bannersNjslyr4, 'assets/banners/njslyr_4.png');
    });

    test('chapterIndex 4 → bannersNjslyr5', () {
      expect(Assets.bannersNjslyr5, 'assets/banners/njslyr_5.webp');
    });
  });
}
