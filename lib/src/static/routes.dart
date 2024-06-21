class Routes {
  static const String chapters = '/chapters';
  static const String chaptersEpisodes = ':chapterId/episodes';
  static const String chaptersEpisodesRead = ':episodeId';

  static const String readHistory = 'readHistory';

  static const String searchEpisode = '/searchEpisode';

  static const String searchWiki = '/searchWiki';
  static const String searchWikiRead = 'read';

  static const String setting = '/setting';
  static const String settingTheme = 'theme';
  static const String settingAnimation = 'richAnimation';

  static const chaptersRoute = chapters;
  static const chaptersEpisodesRoute = '$chapters/$chaptersEpisodes';
  static const chaptersEpisodesReadRoute =
      '$chapters/$chaptersEpisodes/$chaptersEpisodesRead';
  static const readHistoryRoute = '$chapters/$readHistory';
  static const searchEpisodeRoute = searchEpisode;
  static const searchWikiRoute = searchWiki;
  static const searchWikiReadRoute = '$searchWiki/$searchWikiRead';
  static const settingRoute = setting;
  static const settingThemeRoute = '$setting/$settingTheme';
  static const settingAnimationRoute = '$setting/$settingAnimation';

  static String? getRouteTitle(String route) {
    switch (route) {
      case chaptersRoute:
        return 'チャプター選択';
      case chaptersEpisodesRoute:
        return 'エピソード選択';
      case chaptersEpisodesReadRoute:
        return null;
      case readHistoryRoute:
        return '閲覧履歴';
      case searchEpisodeRoute:
        return 'エピソード検索';
      case searchWikiRoute:
        return 'Wiki検索';
      case searchWikiReadRoute:
        return null;
      case settingRoute:
        return '設定';
      case settingThemeRoute:
        return 'テーマ';
      case settingAnimationRoute:
        return 'リッチアニメーション';
      default:
        return 'Ninja Scrolls';
    }
  }

  static String toName(String route) {
    switch (route) {
      case chaptersRoute:
        return 'chapters';
      case chaptersEpisodesRoute:
        return 'chaptersEpisodes';
      case chaptersEpisodesReadRoute:
        return 'chaptersEpisodesRead';
      case readHistoryRoute:
        return 'readHistory';
      case searchEpisodeRoute:
        return 'searchEpisode';
      case searchWikiRoute:
        return 'searchWiki';
      case searchWikiReadRoute:
        return 'searchWikiRead';
      case settingRoute:
        return 'setting';
      case settingThemeRoute:
        return 'settingTheme';
      default:
        return 'Ninja Scrolls';
    }
  }
}
