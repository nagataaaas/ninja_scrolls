import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ninja_scrolls/src/providers/theme_provider.dart';
import 'package:ninja_scrolls/src/providers/user_settings_provider.dart';
import 'package:ninja_scrolls/src/view/settings/animations/view.dart';
import 'package:provider/provider.dart';

void main() {
  group('SettingsAnimationView', () {
    Widget buildTestWidget() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => UserSettingsProvider()),
        ],
        child: const MaterialApp(
          home: SettingsAnimationView(),
        ),
      );
    }

    testWidgets('displays three animation options', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('OS設定に従う'), findsOneWidget);
      expect(find.text('する'), findsOneWidget);
      expect(find.text('しない'), findsOneWidget);
    });

    testWidgets('displays section title', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('アニメーション'), findsOneWidget);
    });

    testWidgets('displays radio button icons', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Default: richAnimationEnabled is true, so する should be checked
      expect(find.byIcon(Icons.radio_button_checked), findsWidgets);
      expect(find.byIcon(Icons.radio_button_off), findsWidgets);
    });
  });
}
