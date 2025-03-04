import 'dart:io';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:go_router/go_router.dart';
import 'package:ninja_scrolls/navkey.dart';
import 'package:ninja_scrolls/route_observer.dart';
import 'package:ninja_scrolls/src/entities/user_settings.dart';
import 'package:ninja_scrolls/src/gateway/database/sqlite.dart';
import 'package:ninja_scrolls/src/gateway/default_cache_manager_extention.dart';
import 'package:ninja_scrolls/src/providers/episode_index_provider.dart';
import 'package:ninja_scrolls/src/providers/scaffold_provider.dart';
import 'package:ninja_scrolls/src/providers/theme_provider.dart';
import 'package:ninja_scrolls/src/providers/user_settings_provider.dart';
import 'package:ninja_scrolls/src/providers/wiki_index_provider.dart';
import 'package:ninja_scrolls/src/static/routes.dart';
import 'package:ninja_scrolls/src/transitions/liquid_transition.dart';
import 'package:ninja_scrolls/src/view/chapter_selector/episode_selector/episode_reader/view.dart';
import 'package:ninja_scrolls/src/view/chapter_selector/episode_selector/view.dart';
import 'package:ninja_scrolls/src/view/chapter_selector/read_history/view.dart';
import 'package:ninja_scrolls/src/view/chapter_selector/view.dart';
import 'package:ninja_scrolls/src/view/episode_search/view.dart';
import 'package:ninja_scrolls/src/view/scaffold/home_shell_scaffold.dart';
import 'package:ninja_scrolls/src/view/search_wiki/read/view.dart';
import 'package:ninja_scrolls/src/view/search_wiki/view.dart';
import 'package:ninja_scrolls/src/view/settings/animations/view.dart';
import 'package:ninja_scrolls/src/view/settings/theme/view.dart';
import 'package:ninja_scrolls/src/view/settings/view.dart';
import 'package:provider/provider.dart';

Future main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  DatabaseHelper.instance.ensureInitialized().then((value) {
    if (kDebugMode) {
      DatabaseHelper.instance.deleteDatabase();
    }
  });
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await DefaultCacheManagerExtention.instance.ensureInitialized();
  FlutterNativeSplash.remove();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scaffoldProvider = ScaffoldProvider();
    final episodeIndexProvider = EpisodeIndexProvider()..loadIndex();
    final themeProvider = ThemeProvider()..ensureTextThemeInitialized(context);
    final userSettingsProvider = UserSettingsProvider();
    userSettingsProvider.ensureInitialized().then(
      (_) {
        themeProvider.initializeWithUserSettings(userSettingsProvider);
      },
    );
    final wikiIndexProvider = WikiIndexProvider()
      ..ensureWikiPagesLoaded()
      ..ensureRecentAccessedLoaded();
    return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => scaffoldProvider),
          ChangeNotifierProvider(create: (_) => userSettingsProvider),
          ChangeNotifierProvider(create: (_) => episodeIndexProvider),
          ChangeNotifierProvider(create: (_) => themeProvider),
          ChangeNotifierProvider(create: (_) => themeProvider),
          ChangeNotifierProvider(create: (_) => wikiIndexProvider),
        ],
        child: AdaptiveTheme(
          light: LightTheme.bright.theme,
          dark: DarkTheme.black.theme,
          initial: {
            ThemeType.auto: AdaptiveThemeMode.system,
            ThemeType.light: AdaptiveThemeMode.light,
            ThemeType.dark: AdaptiveThemeMode.dark,
          }[userSettingsProvider.themeType]!,
          builder: (theme, darkTheme) => MaterialApp.router(
            theme: theme,
            darkTheme: darkTheme,
            routerConfig: router,
            debugShowCheckedModeBanner: false,
          ),
        ));
  }
}

final router = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: Routes.chapters,
  debugLogDiagnostics: true,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => HomeShellScaffold(
          navigationShell: navigationShell, routerState: state),
      branches: [
        StatefulShellBranch(
          navigatorKey: readerShellNavigatorKey,
          observers: [readShellRouteObserver],
          routes: [
            GoRoute(
              name: Routes.toName(Routes.chaptersRoute),
              path: Routes.chapters,
              builder: (context, state) => ChapterSelectorView(),
              routes: [
                GoRoute(
                    name: Routes.toName(Routes.readHistoryRoute),
                    path: Routes.readHistory,
                    pageBuilder: (context, state) => Platform.isIOS
                        ? CupertinoPage(
                            name: state.name,
                            key: state.pageKey,
                            child: ReadHistoryView(key: readHistoryKey))
                        : MaterialPage(
                            name: state.name,
                            key: state.pageKey,
                            child: ReadHistoryView(key: readHistoryKey),
                          )),
                GoRoute(
                    name: Routes.toName(Routes.chaptersEpisodesRoute),
                    path: Routes.chaptersEpisodes,
                    builder: (context, state) {
                      return EpisodeSelectorView(
                          key: episodeSelectorKey,
                          argument: EpisodeSelectorViewArgument(
                              int.parse(state.pathParameters['chapterId']!)));
                    },
                    routes: [
                      GoRoute(
                        name: Routes.toName(Routes.chaptersEpisodesReadRoute),
                        path: Routes.chaptersEpisodesRead,
                        pageBuilder: (context, state) {
                          final argument = EpisodeReaderViewArgument(
                            chapterId:
                                int.parse(state.pathParameters['chapterId']!),
                            episodeId: state.pathParameters['episodeId']!,
                          );

                          return buildLiquidTransitionPage(
                            context: context,
                            name: state.name,
                            key: UniqueKey(),
                            child: EpisodeReaderView(
                                key: UniqueKey(), argument: argument),
                            transitionDuration: Duration(milliseconds: 700),
                            reverseTransitionDuration:
                                Duration(milliseconds: 700),
                          );
                        },
                      ),
                    ]),
              ],
            ),
            GoRoute(
              name: Routes.toName(Routes.searchEpisode),
              path: Routes.searchEpisode,
              pageBuilder: (context, state) => Platform.isIOS
                  ? CupertinoPage(
                      name: state.name,
                      key: state.pageKey,
                      child: EpisodeSearchView())
                  : MaterialPage(
                      name: state.name,
                      key: state.pageKey,
                      child: EpisodeSearchView()),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: wikiShellNavigatorKey,
          routes: [
            GoRoute(
              name: Routes.toName(Routes.searchWikiRoute),
              path: Routes.searchWiki,
              builder: (context, state) => SearchWikiView(),
              routes: [
                GoRoute(
                  name: Routes.toName(Routes.searchWikiReadRoute),
                  path: Routes.searchWikiRead,
                  pageBuilder: (context, GoRouterState state) {
                    final argument = SearchWikiReadViewArgument(
                      wikiEndpoint: state.uri.queryParameters['wikiEndpoint']!,
                      wikiTitle: state.uri.queryParameters['wikiTitle']!,
                    );

                    return buildLiquidTransitionPage(
                      context: context,
                      name: state.name,
                      key: UniqueKey(),
                      child: SearchWikiReadView(argument: argument),
                      transitionDuration: Duration(milliseconds: 700),
                      reverseTransitionDuration: Duration(milliseconds: 700),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: settingShellNavigatorKey,
          routes: [
            GoRoute(
                name: Routes.toName(Routes.settingRoute),
                path: Routes.setting,
                builder: (context, state) => SettingsView(),
                routes: [
                  GoRoute(
                    name: Routes.toName(Routes.settingThemeRoute),
                    path: Routes.settingTheme,
                    builder: (context, state) => SettingsThemeView(),
                  ),
                  GoRoute(
                    name: Routes.toName(Routes.settingAnimationRoute),
                    path: Routes.settingAnimation,
                    builder: (context, state) => SettingsAnimationView(),
                  ),
                ]),
          ],
        ),
      ],
    ),
  ],
);
