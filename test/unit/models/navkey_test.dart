import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ninja_scrolls/navkey.dart';

void main() {
  group('Navigation keys', () {
    test('rootNavigatorKey is a GlobalKey<NavigatorState>', () {
      expect(rootNavigatorKey, isA<GlobalKey<NavigatorState>>());
    });

    test('readerShellNavigatorKey is a GlobalKey<NavigatorState>', () {
      expect(readerShellNavigatorKey, isA<GlobalKey<NavigatorState>>());
    });

    test('wikiShellNavigatorKey is a GlobalKey<NavigatorState>', () {
      expect(wikiShellNavigatorKey, isA<GlobalKey<NavigatorState>>());
    });

    test('settingShellNavigatorKey is a GlobalKey<NavigatorState>', () {
      expect(settingShellNavigatorKey, isA<GlobalKey<NavigatorState>>());
    });

    test('episodeSelectorKey is a GlobalKey', () {
      expect(episodeSelectorKey, isA<GlobalKey>());
    });

    test('readHistoryKey is a GlobalKey', () {
      expect(readHistoryKey, isA<GlobalKey>());
    });

    test('shellScaffoldKey is a GlobalKey<ScaffoldState>', () {
      expect(shellScaffoldKey, isA<GlobalKey<ScaffoldState>>());
    });

    test('all keys are distinct instances', () {
      final keys = {
        rootNavigatorKey,
        readerShellNavigatorKey,
        wikiShellNavigatorKey,
        settingShellNavigatorKey,
        episodeSelectorKey,
        readHistoryKey,
        shellScaffoldKey,
      };
      expect(keys.length, 7);
    });
  });
}
