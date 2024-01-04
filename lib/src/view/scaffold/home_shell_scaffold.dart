import 'dart:async';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ninja_scrolls/extentions.dart';
import 'package:ninja_scrolls/navkey.dart';
import 'package:ninja_scrolls/src/providers/scaffold_provider.dart';
import 'package:ninja_scrolls/src/providers/user_settings_provider.dart';
import 'package:ninja_scrolls/src/static/colors.dart';
import 'package:ninja_scrolls/src/static/routes.dart';
import 'package:provider/provider.dart';

class HomeShellScaffold extends StatefulWidget {
  final GoRouterState routerState;
  final StatefulNavigationShell navigationShell;
  const HomeShellScaffold(
      {super.key, required this.navigationShell, required this.routerState});

  @override
  State<HomeShellScaffold> createState() => _HomeShellScaffoldState();
}

final tagRoutes = [
  Routes.chaptersRoute,
  Routes.searchWikiRoute,
  Routes.settingRoute
];

class _HomeShellScaffoldState extends State<HomeShellScaffold> {
  bool _beforeCanPop = false;
  bool get canPop => context.canPop();

  late final Timer canPopTimer;

  GlobalKey<NavigatorState> get currentShellNavigatorKey => [
        readerShellNavigatorKey,
        wikiShellNavigatorKey,
        settingShellNavigatorKey
      ][widget.navigationShell.currentIndex];

  String get location => widget.routerState.fullPath ?? '/';
  bool get hasDrawer {
    if (location == Routes.chaptersEpisodesReadRoute) return true;
    return false;
  }

  List<Widget>? get actions {
    if (location == Routes.chaptersRoute ||
        location == Routes.chaptersEpisodesRoute) {
      return [
        IconButton(
          icon: Icon(Icons.search),
          onPressed: () => GoRouter.of(context)
              .pushNamed(Routes.toName(Routes.searchEpisodeRoute)),
        )
      ];
    }
    return null;
  }

  AppBar get appBar {
    print(location);
    if (location == Routes.searchEpisodeRoute) {
      final searchAppBar =
          context.watch<ScaffoldProvider>().episodeSearchAppBar;
      if (searchAppBar != null) {
        return searchAppBar;
      }
    }
    if (location == Routes.searchWikiRoute) {
      final wikiSearchAppBar =
          context.watch<ScaffoldProvider>().wikiSearchAppBar;
      if (wikiSearchAppBar != null) {
        return wikiSearchAppBar;
      }
    }

    return AppBar(
      elevation: 1,
      actions: actions,
      title: Text(
        title,
        style: GoogleFonts.reggaeOne(
          fontSize: context.textTheme.headlineMedium?.fontSize,
          color: context.textTheme.headlineMedium?.color,
        ),
      ),
      leading: canPop
          ? IconButton(
              icon: Icon(Icons.arrow_back_ios),
              onPressed: () => GoRouter.of(context).pop(),
            )
          : null,
      centerTitle: true,
    );
  }

  String get title {
    String? route = Routes.getRouteTitle(location);
    if (location == Routes.chaptersEpisodesReadRoute) {
      route ??= context.watch<ScaffoldProvider>().episodeTitle;
    }
    if (location == Routes.searchWikiReadRoute) {
      route ??= context.watch<ScaffoldProvider>().wikiTitle;
    }
    return route ?? 'Ninja Scrolls';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userSettingsProvider = context.read<UserSettingsProvider>();
      userSettingsProvider.ensureInitialized().then(
        (_) {
          AdaptiveTheme.of(context).setTheme(
            light: userSettingsProvider.lightTheme.theme,
            dark: userSettingsProvider.darkTheme.theme,
          );
        },
      );

      Timer.periodic(Duration(milliseconds: 100), (timer) {
        if (context.canPop() != _beforeCanPop) {
          setState(() {});
          _beforeCanPop = context.canPop();
        }
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    canPopTimer.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: shellScaffoldKey,
      endDrawer: hasDrawer ? context.watch<ScaffoldProvider>().endDrawer : null,
      appBar: appBar,
      bottomNavigationBar: BottomNavigationBar(
        onTap: (index) {
          widget.navigationShell.goBranch(
            index,
            initialLocation: index == widget.navigationShell.currentIndex,
          );
          setState(() {});
        },
        currentIndex: widget.navigationShell.currentIndex,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        selectedItemColor: Common.accent,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.my_library_books_outlined),
            activeIcon: Icon(Icons.my_library_books_rounded),
            label: '読む',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.screen_search_desktop_outlined),
            activeIcon: Icon(Icons.screen_search_desktop_rounded),
            label: 'wiki',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: '設定',
          ),
        ],
      ),
      body: widget.navigationShell,
    );
  }
}
