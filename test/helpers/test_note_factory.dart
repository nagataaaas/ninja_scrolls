import 'package:ninja_scrolls/src/gateway/database/note.dart';
import 'package:ninja_scrolls/src/gateway/database/read_state.dart';
import 'package:ninja_scrolls/src/gateway/database/wiki.dart';
import 'package:ninja_scrolls/src/services/parser/parse_chapters.dart';

Note createTestNote({
  String id = 'n_test_001',
  String title = 'Test Episode Title',
  String html = '<p>Test content</p>',
  String? eyecatchUrl = 'https://example.com/image.png',
  int remainedCharNum = 0,
  List<IndexItem> indexItems = const [],
  bool isLimited = false,
  bool isPurchased = false,
  BookPurchaseLink? bookPurchaseLink,
  DateTime? cachedAt,
  DateTime? recentReadAt,
}) {
  return Note(
    id: id,
    title: title,
    html: html,
    eyecatchUrl: eyecatchUrl,
    remainedCharNum: remainedCharNum,
    indexItems: indexItems,
    isLimited: isLimited,
    isPurchased: isPurchased,
    bookPurchaseLink: bookPurchaseLink,
    cachedAt: cachedAt ?? DateTime(2024, 1, 1),
    recentReadAt: recentReadAt,
  );
}

Index createTestIndex() {
  return Index(
    updatedAt: DateTime(2024, 1, 1),
    trilogy: [
      createTestChapter(
        id: 0,
        title: 'Neo Saitama',
        episodeLinks: [
          createTestEpisodeLink(title: 'Episode 1', noteId: 'n001'),
          createTestEpisodeLink(title: 'Episode 2', noteId: 'n002'),
        ],
      ),
      createTestChapter(
        id: 1,
        title: 'Kyoto Hell',
        episodeLinks: [
          createTestEpisodeLink(title: 'Episode 3', noteId: 'n003'),
        ],
      ),
      createTestChapter(
        id: 2,
        title: 'Never Dies',
        episodeLinks: [
          createTestEpisodeLink(title: 'Episode 4', noteId: 'n004'),
          createTestEpisodeLink(title: 'Episode 5', noteId: 'n005'),
        ],
      ),
    ],
    aom: [
      createTestChapter(
        id: 3,
        title: 'AoM Season 1',
        episodeLinks: [
          createTestEpisodeLink(title: 'AoM Episode 1', noteId: 'n006'),
        ],
      ),
    ],
  );
}

Chapter createTestChapter({
  required int id,
  String title = 'Test Chapter',
  String description = 'Test description',
  List<EpisodeLink> episodeLinks = const [],
  String imagePath = 'assets/banners/neo_saitama_in_flames.webp',
}) {
  return Chapter(
    id: id,
    title: title,
    description: description,
    chapterChildren: [
      ChapterChild.episodeLinkGroup(
        EpisodeLinkGroup(groupName: null, links: episodeLinks),
      ),
    ],
    imagePath: imagePath,
  );
}

EpisodeLink createTestEpisodeLink({
  String title = 'Test Episode',
  String noteId = 'n_test_001',
  String? emoji,
}) {
  return EpisodeLink(title: title, noteId: noteId, emoji: emoji);
}

WikiPage createTestWikiPage({
  String title = 'Test Wiki Page',
  String? sanitizedTitle,
  String endpoint = '/njslyr/TestPage',
}) {
  return WikiPage(
    title: title,
    sanitizedTitle: sanitizedTitle ?? title.toLowerCase(),
    endpoint: endpoint,
  );
}
