import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ninja_scrolls/navkey.dart';
import 'package:ninja_scrolls/src/transitions/liquid_transition.dart';
import 'package:ninja_scrolls/src/view/chapter_selector/view.dart';
import 'package:ninja_scrolls/src/view/loading/view.dart';
import 'package:ninja_scrolls/static/colors.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.mPlusRounded1cTextTheme(
        Theme.of(context).textTheme.copyWith(
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
    return
        // MultiProvider(
        //   providers: [
        //     // ChangeNotifierProvider(create: (_) => phone_auth.PhoneAuthProvider()),
        //     // ChangeNotifierProvider(create: (_) => InitialSettingProvider()),
        //     // ChangeNotifierProvider(create: (_) => CardObtainProvider()),
        //     // ChangeNotifierProvider(create: (_) => OwnedContentsProvider()),
        //     // ChangeNotifierProvider(create: (_) => AudioPlayProvider()),
        //     // ChangeNotifierProvider(create: (_) => UserInfoProvider()),
        //     // ChangeNotifierProvider(create: (_) => ChromeSafariBrowserProvider()),
        //     // ChangeNotifierProvider(create: (_) => NfcManagerProvider()),
        //     // ChangeNotifierProvider(create: (_) => InAppPurchaseProvider()),
        //     // ChangeNotifierProvider(create: (_) => ArtistsProvider()),
        //   ],
        //   child:
        MaterialApp.router(
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Common.ocean,
        textTheme: textTheme,
      ),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      // ),
    );
  }
}

final routes = [
  GoRoute(
      path: '/',
      builder: (context, state) {
        final c = Completer();
        return GestureDetector(
          onTap: () {
            c.complete();
          },
          child: LoadingScreen(
            completer: c,
            onAnimationFinished: () {
              context.push('/liquid');
            },
          ),
        );
      }),
  GoRoute(path: '/toc', builder: (context, state) => ChapterSelectorView()),
  GoRoute(
    path: '/liquid',
    pageBuilder: (context, state) => buildLiquidTransitionPage(
      child: GestureDetector(
        onTap: () {
          context.pop();
        },
        child: LoadingScreen(
          completer: Completer(),
        ),
      ),
      transitionDuration: Duration(seconds: 1),
      reverseTransitionDuration: Duration(seconds: 1),
    ),
  ),
];

final router = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/toc',
  // redirect: (context, state) async {},
  debugLogDiagnostics: true,
  routes: routes,
);
