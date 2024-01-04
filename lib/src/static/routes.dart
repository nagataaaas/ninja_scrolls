class Routes {
  static const String chapters = '/chapters';
  static const String chaptersEpisodes = ':chapterId/episodes';
  static const String chaptersEpisodesRead = ':episodeId';

  static const String searchEpisode = '/searchEpisode';

  static const String searchWiki = '/searchWiki';
  static const String searchWikiRead = 'read';

  static const String setting = '/setting';
  static const String settingTheme = 'theme';

  static const chaptersRoute = chapters;
  static const chaptersEpisodesRoute = '$chapters/$chaptersEpisodes';
  static const chaptersEpisodesReadRoute =
      '$chapters/$chaptersEpisodes/$chaptersEpisodesRead';
  static const searchEpisodeRoute = searchEpisode;
  static const searchWikiRoute = searchWiki;
  static const searchWikiReadRoute = '$searchWiki/$searchWikiRead';
  static const settingRoute = setting;
  static const settingThemeRoute = '$setting/$settingTheme';

  static String? getRouteTitle(String route) {
    switch (route) {
      case chaptersRoute:
        return 'チャプター選択';
      case chaptersEpisodesRoute:
        return 'エピソード選択';
      case chaptersEpisodesReadRoute:
        return null;
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
