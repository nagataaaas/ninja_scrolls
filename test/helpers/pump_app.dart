import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Future<void> pumpApp(
  WidgetTester tester,
  Widget child, {
  List<ChangeNotifierProvider> providers = const [],
  ThemeData? theme,
}) async {
  final app = MaterialApp(
    theme: theme ?? ThemeData.light(useMaterial3: true),
    home: providers.isEmpty
        ? Scaffold(body: child)
        : MultiProvider(
            providers: providers,
            child: Scaffold(body: child),
          ),
  );
  await tester.pumpWidget(app);
}
