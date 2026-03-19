import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ninja_scrolls/src/providers/theme_provider.dart';
import 'package:ninja_scrolls/src/providers/user_settings_provider.dart';
import 'package:ninja_scrolls/src/view/settings/theme/view.dart';
import 'package:provider/provider.dart';

void main() {
  group('SettingsThemeView', () {
    Widget buildTestWidget() {
      return AdaptiveTheme(
        light: LightTheme.bright.theme,
        dark: DarkTheme.black.theme,
        initial: AdaptiveThemeMode.system,
        builder: (light, dark) => MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(create: (_) => UserSettingsProvider()),
          ],
          child: MaterialApp(
            theme: light,
            darkTheme: dark,
            home: const SettingsThemeView(),
          ),
        ),
      );
    }

    testWidgets('displays brightness selection options', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('OS設定に従う'), findsOneWidget);
      expect(find.text('ライト'), findsOneWidget);
      expect(find.text('ダーク'), findsOneWidget);
    });

    testWidgets('displays theme variant selection', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('ライトテーマ'), findsOneWidget);
      expect(find.text('ダークテーマ'), findsOneWidget);
    });

    testWidgets('displays default theme variant names', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Default light theme is ブライト, default dark theme is ブラック
      expect(find.text('ブライト'), findsOneWidget);
      expect(find.text('ブラック'), findsOneWidget);
    });

    testWidgets('displays section titles', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('明るさの選択'), findsOneWidget);
      expect(find.text('テーマ選択'), findsOneWidget);
    });
  });
}
