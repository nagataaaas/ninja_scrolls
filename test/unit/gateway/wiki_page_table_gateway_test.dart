import 'package:flutter_test/flutter_test.dart';
import 'package:ninja_scrolls/src/gateway/database/wiki.dart';

import '../../helpers/test_database_helper.dart';
import '../../helpers/test_note_factory.dart';

void main() {
  setUp(() async {
    await setupTestDatabase();
  });

  tearDown(() async {
    await tearDownTestDatabase();
  });

  group('WikiPageTableGateway', () {
    test('isCached returns false initially', () async {
      expect(await WikiPageTableGateway.isCached, isFalse);
    });

    test('isCached returns true after save', () async {
      await WikiPageTableGateway.save([
        createTestWikiPage(title: 'Page1', endpoint: '/njslyr/Page1'),
      ]);
      expect(await WikiPageTableGateway.isCached, isTrue);
    });

    test('save inserts pages', () async {
      await WikiPageTableGateway.save([
        createTestWikiPage(title: 'Page1', endpoint: '/njslyr/Page1'),
        createTestWikiPage(title: 'Page2', endpoint: '/njslyr/Page2'),
      ]);
      final all = await WikiPageTableGateway.all;
      expect(all.length, 2);
    });

    test('save ignores duplicate titles (ConflictAlgorithm.ignore)', () async {
      await WikiPageTableGateway.save([
        createTestWikiPage(title: 'DupPage', endpoint: '/njslyr/DupPage'),
      ]);
      await WikiPageTableGateway.save([
        createTestWikiPage(title: 'DupPage', endpoint: '/njslyr/DupPage2'),
      ]);
      final all = await WikiPageTableGateway.all;
      expect(all.length, 1);
      // Original endpoint is kept due to IGNORE
      expect(all.first.endpoint, '/njslyr/DupPage');
    });

    test('all returns all saved pages', () async {
      await WikiPageTableGateway.save([
        createTestWikiPage(title: 'A', endpoint: '/njslyr/A'),
        createTestWikiPage(title: 'B', endpoint: '/njslyr/B'),
        createTestWikiPage(title: 'C', endpoint: '/njslyr/C'),
      ]);
      final all = await WikiPageTableGateway.all;
      expect(all.length, 3);
    });

    test('latestCreatedAt returns null when empty', () async {
      expect(await WikiPageTableGateway.latestCreatedAt, isNull);
    });

    test('latestCreatedAt returns DateTime after save', () async {
      await WikiPageTableGateway.save([
        createTestWikiPage(title: 'Dated', endpoint: '/njslyr/Dated'),
      ]);
      final latest = await WikiPageTableGateway.latestCreatedAt;
      expect(latest, isNotNull);
      expect(latest, isA<DateTime>());
    });

    test('updateLastAccessedAt sets timestamp', () async {
      await WikiPageTableGateway.save([
        createTestWikiPage(title: 'Accessed', endpoint: '/njslyr/Accessed'),
      ]);
      await WikiPageTableGateway.updateLastAccessedAt('Accessed');

      final recent = await WikiPageTableGateway.recentAccessed(10);
      expect(recent.length, 1);
      expect(recent.first.title, 'Accessed');
    });

    test('recentAccessed returns only pages with last_accessed_at', () async {
      await WikiPageTableGateway.save([
        createTestWikiPage(title: 'NoAccess', endpoint: '/njslyr/NoAccess'),
        createTestWikiPage(title: 'Accessed', endpoint: '/njslyr/Accessed'),
      ]);
      await WikiPageTableGateway.updateLastAccessedAt('Accessed');

      final recent = await WikiPageTableGateway.recentAccessed(10);
      expect(recent.length, 1);
      expect(recent.first.title, 'Accessed');
    });

    test('recentAccessed respects limit', () async {
      for (int i = 0; i < 5; i++) {
        await WikiPageTableGateway.save([
          createTestWikiPage(title: 'Page_$i', endpoint: '/njslyr/Page_$i'),
        ]);
        await WikiPageTableGateway.updateLastAccessedAt('Page_$i');
        await Future.delayed(const Duration(milliseconds: 10));
      }
      final recent = await WikiPageTableGateway.recentAccessed(3);
      expect(recent.length, 3);
    });

    test('removeAccessedAt clears last_accessed_at', () async {
      await WikiPageTableGateway.save([
        createTestWikiPage(title: 'ToRemove', endpoint: '/njslyr/ToRemove'),
      ]);
      await WikiPageTableGateway.updateLastAccessedAt('ToRemove');
      expect((await WikiPageTableGateway.recentAccessed(10)).length, 1);

      await WikiPageTableGateway.removeAccessedAt('ToRemove');
      expect((await WikiPageTableGateway.recentAccessed(10)).length, 0);
    });

    test('deleteAll removes all pages', () async {
      await WikiPageTableGateway.save([
        createTestWikiPage(title: 'Del1', endpoint: '/njslyr/Del1'),
        createTestWikiPage(title: 'Del2', endpoint: '/njslyr/Del2'),
      ]);
      await WikiPageTableGateway.deleteAll();
      expect(await WikiPageTableGateway.isCached, isFalse);
      expect((await WikiPageTableGateway.all).length, 0);
    });
  });
}
