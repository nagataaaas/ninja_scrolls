import 'package:flutter_test/flutter_test.dart';
import 'package:ninja_scrolls/src/static/routes.dart';

void main() {
  group('Routes constants', () {
    test('route constants are correctly composed', () {
      expect(Routes.chaptersRoute, '/chapters');
      expect(Routes.chaptersEpisodesRoute, '/chapters/:chapterId/episodes');
      expect(Routes.chaptersEpisodesReadRoute,
          '/chapters/:chapterId/episodes/:episodeId');
      expect(Routes.readHistoryRoute, '/chapters/readHistory');
      expect(Routes.searchEpisodeRoute, '/searchEpisode');
      expect(Routes.searchWikiRoute, '/searchWiki');
      expect(Routes.searchWikiReadRoute, '/searchWiki/read');
      expect(Routes.settingRoute, '/setting');
      expect(Routes.settingThemeRoute, '/setting/theme');
      expect(Routes.settingAnimationRoute, '/setting/richAnimation');
    });
  });

  group('Routes.getRouteTitle', () {
    test('returns correct title for chapters', () {
      expect(Routes.getRouteTitle(Routes.chaptersRoute), 'チャプター選択');
    });

    test('returns correct title for episodes', () {
      expect(Routes.getRouteTitle(Routes.chaptersEpisodesRoute), 'エピソード選択');
    });

    test('returns null for episode reader', () {
      expect(Routes.getRouteTitle(Routes.chaptersEpisodesReadRoute), isNull);
    });

    test('returns correct title for read history', () {
      expect(Routes.getRouteTitle(Routes.readHistoryRoute), '閲覧履歴');
    });

    test('returns correct title for episode search', () {
      expect(Routes.getRouteTitle(Routes.searchEpisodeRoute), 'エピソード検索');
    });

    test('returns correct title for wiki search', () {
      expect(Routes.getRouteTitle(Routes.searchWikiRoute), 'Wiki検索');
    });

    test('returns null for wiki reader', () {
      expect(Routes.getRouteTitle(Routes.searchWikiReadRoute), isNull);
    });

    test('returns correct title for settings', () {
      expect(Routes.getRouteTitle(Routes.settingRoute), '設定');
    });

    test('returns correct title for theme settings', () {
      expect(Routes.getRouteTitle(Routes.settingThemeRoute), 'テーマ');
    });

    test('returns correct title for animation settings', () {
      expect(Routes.getRouteTitle(Routes.settingAnimationRoute), 'リッチアニメーション');
    });

    test('returns default title for unknown route', () {
      expect(Routes.getRouteTitle('/unknown'), 'Ninja Scrolls');
    });
  });

  group('Routes.toName', () {
    test('returns correct name for chapters', () {
      expect(Routes.toName(Routes.chaptersRoute), 'chapters');
    });

    test('returns correct name for episodes', () {
      expect(Routes.toName(Routes.chaptersEpisodesRoute), 'chaptersEpisodes');
    });

    test('returns correct name for episode reader', () {
      expect(
          Routes.toName(Routes.chaptersEpisodesReadRoute), 'chaptersEpisodesRead');
    });

    test('returns correct name for read history', () {
      expect(Routes.toName(Routes.readHistoryRoute), 'readHistory');
    });

    test('returns correct name for episode search', () {
      expect(Routes.toName(Routes.searchEpisodeRoute), 'searchEpisode');
    });

    test('returns correct name for wiki search', () {
      expect(Routes.toName(Routes.searchWikiRoute), 'searchWiki');
    });

    test('returns correct name for wiki reader', () {
      expect(Routes.toName(Routes.searchWikiReadRoute), 'searchWikiRead');
    });

    test('returns correct name for settings', () {
      expect(Routes.toName(Routes.settingRoute), 'setting');
    });

    test('returns correct name for theme settings', () {
      expect(Routes.toName(Routes.settingThemeRoute), 'settingTheme');
    });

    test('returns default name for unknown route', () {
      expect(Routes.toName('/unknown'), 'Ninja Scrolls');
    });
  });
}
