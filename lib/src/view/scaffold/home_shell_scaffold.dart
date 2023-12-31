import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ninja_scrolls/extentions.dart';
import 'package:ninja_scrolls/navkey.dart';
import 'package:ninja_scrolls/src/providers/reader_provider.dart';
import 'package:ninja_scrolls/src/static/colors.dart';
import 'package:ninja_scrolls/src/static/routes.dart';
import 'package:ninja_scrolls/src/view/scaffold/appbar_title_bloc.dart';
import 'package:provider/provider.dart';

class HomeShellScaffold extends StatefulWidget {
  final GoRouterState routerState;
  final StatefulNavigationShell navigationShell;
  const HomeShellScaffold(
      {super.key, required this.navigationShell, required this.routerState});

  @override
  State<HomeShellScaffold> createState() => _HomeShellScaffoldState();
}

final tagRoutes = [Routes.chaptersRoute, Routes.settingRoute];

class _HomeShellScaffoldState extends State<HomeShellScaffold> {
  bool get canPop => location.lastIndexOf('/') != 0;

  GlobalKey<NavigatorState> get currentShellNavigatorKey => [
        readerShellNavigatorKey,
        settingShellNavigatorKey
      ][widget.navigationShell.currentIndex];

  String get location => widget.routerState.fullPath ?? '/';
  bool get hasDrawer {
    if (location == Routes.chaptersEpisodesReadRoute) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: shellScaffoldKey,
      endDrawer: hasDrawer ? context.watch<ReaderProvider>().endDrawer : null,
      appBar: AppBar(
        elevation: 1,
        title: StreamBuilder<String?>(
            stream: appBloc.titleStream,
            builder: (context, snapshot) {
              return Text(
                Routes.getRouteTitle(location) ?? snapshot.data ?? '',
                style: GoogleFonts.reggaeOne(
                    fontSize: context.textTheme.headlineMedium!.fontSize!),
              );
            }),
        leading: canPop
            ? IconButton(
                icon: Icon(Icons.arrow_back_ios),
                onPressed: () => GoRouter.of(context).pop(),
              )
            : null,
        centerTitle: true,
      ),
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
