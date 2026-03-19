import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ninja_scrolls/src/providers/scaffold_provider.dart';

void main() {
  group('ScaffoldProvider', () {
    late ScaffoldProvider provider;
    int notifyCount = 0;

    setUp(() {
      provider = ScaffoldProvider();
      notifyCount = 0;
      provider.addListener(() => notifyCount++);
    });

    test('initial values are null', () {
      expect(provider.episodeTitle, isNull);
      expect(provider.wikiTitle, isNull);
      expect(provider.episodeSearchAppBar, isNull);
      expect(provider.wikiSearchAppBar, isNull);
      expect(provider.endDrawer, isNull);
    });

    test('setting episodeTitle notifies listeners', () {
      provider.episodeTitle = 'Test Episode';
      expect(provider.episodeTitle, 'Test Episode');
      expect(notifyCount, 1);
    });

    test('setting wikiTitle notifies listeners', () {
      provider.wikiTitle = 'Test Wiki';
      expect(provider.wikiTitle, 'Test Wiki');
      expect(notifyCount, 1);
    });

    test('setting endDrawer notifies listeners', () {
      final drawer = Container();
      provider.endDrawer = drawer;
      expect(provider.endDrawer, drawer);
      expect(notifyCount, 1);
    });

    test('setting episodeSearchAppBar notifies listeners', () {
      final appBar = AppBar(title: const Text('Search'));
      provider.episodeSearchAppBar = appBar;
      expect(provider.episodeSearchAppBar, appBar);
      expect(notifyCount, 1);
    });

    test('setting wikiSearchAppBar notifies listeners', () {
      final appBar = AppBar(title: const Text('Wiki Search'));
      provider.wikiSearchAppBar = appBar;
      expect(provider.wikiSearchAppBar, appBar);
      expect(notifyCount, 1);
    });
  });
}
