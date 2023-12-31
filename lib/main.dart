import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ninja_scrolls/navkey.dart';
import 'package:ninja_scrolls/src/gateway/sqlite.dart';
import 'package:ninja_scrolls/src/providers/index_provider.dart';
import 'package:ninja_scrolls/src/providers/reader_provider.dart';
import 'package:ninja_scrolls/src/providers/user_settings_provider.dart';
import 'package:ninja_scrolls/src/static/colors.dart' as colors;
import 'package:ninja_scrolls/src/static/routes.dart';
import 'package:ninja_scrolls/src/transitions/liquid_transition.dart';
import 'package:ninja_scrolls/src/view/chapter_selector/episode_selector/episode_reader/view.dart';
import 'package:ninja_scrolls/src/view/chapter_selector/episode_selector/view.dart';
import 'package:ninja_scrolls/src/view/chapter_selector/view.dart';
import 'package:ninja_scrolls/src/view/scaffold/home_shell_scaffold.dart';
import 'package:ninja_scrolls/src/view/settings/theme/view.dart';
import 'package:ninja_scrolls/src/view/settings/view.dart';
import 'package:provider/provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  DatabaseHelper.instance
      .ensurePathInitialized()
      .then((value) => DatabaseHelper.instance.deleteDatabase());
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme =
        GoogleFonts.notoSansTextTheme(Theme.of(context).textTheme.copyWith(
              headlineLarge: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w600,
              ),
              headlineMedium: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
              headlineSmall: const TextStyle(
                fontSize: 18,
              ),
              bodyLarge: const TextStyle(
                fontSize: 16,
              ),
              bodyMedium: const TextStyle(
                fontSize: 14,
              ),
            ));
    final readerProvider = ReaderProvider();
    final userSettingsProvider = UserSettingsProvider()..ensureInitialized();
    final indexProvider = IndexProvider()..loadIndex();
    return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => readerProvider),
          ChangeNotifierProvider(create: (_) => userSettingsProvider),
          ChangeNotifierProvider(create: (_) => indexProvider),
        ],
        child: AdaptiveTheme(
          light: ThemeData(
            useMaterial3: true,
            colorScheme: const ColorScheme.light(
              background: colors.Common.white,
              primary: colors.Common.black,
              onPrimary: colors.Common.white,
              secondary: colors.Common.grey2,
              onSecondary: colors.Common.white,
              tertiary: colors.Common.accent,
              onTertiary: colors.Common.white,
              error: colors.Common.errorRed,
            ),
            textTheme: textTheme,
          ),
          dark: ThemeData(
            useMaterial3: true,
            colorScheme: const ColorScheme.dark(
              background: colors.Common.black,
              primary: colors.Common.white,
              onPrimary: colors.Common.black,
              secondary: colors.Common.grey3,
              onSecondary: colors.Common.white,
              tertiary: colors.Common.accent,
              onTertiary: colors.Common.white,
              error: colors.Common.errorRed,
            ),
            textTheme: textTheme,
          ),
          initial: AdaptiveThemeMode.system,
          builder: (theme, darkTheme) => MaterialApp.router(
            themeMode: ThemeMode.system,
            theme: theme,
            darkTheme: darkTheme,
            routerConfig: router,
            debugShowCheckedModeBanner: false,
          ),
        ));
  }
}

final router = GoRouter(
  // extraCodec: RouterCodec(),
  navigatorKey: rootNavigatorKey,
  initialLocation: Routes.chapters,
  // redirect: (context, state) async {},
  debugLogDiagnostics: true,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => HomeShellScaffold(
          navigationShell: navigationShell, routerState: state),
      branches: [
        StatefulShellBranch(
          navigatorKey: readerShellNavigatorKey,
          routes: [
            GoRoute(
              name: Routes.toName(Routes.chaptersRoute),
              path: Routes.chapters,
              builder: (context, state) => ChapterSelectorView(),
              routes: [
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
                ]),
          ],
        ),
      ],
    ),
  ],
);
