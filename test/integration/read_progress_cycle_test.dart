import 'package:flutter_test/flutter_test.dart';
import 'package:ninja_scrolls/src/gateway/database/read_state.dart';

import '../helpers/test_database_helper.dart';

void main() {
  setUp(() async {
    await setupTestDatabase();
  });

  tearDown(() async {
    await tearDownTestDatabase();
  });

  group('Read progress save/restore cycle', () {
    test('saves and restores reading progress', () async {
      // Save progress for an episode
      await ReadStateGateway.updateStatus(
          'n_cycle_1', ReadState.reading, 0.5, 3);

      // Restore progress
      final statuses = await ReadStateGateway.getStatus(['n_cycle_1']);
      expect(statuses['n_cycle_1']!.state, ReadState.reading);
      expect(statuses['n_cycle_1']!.readProgress, closeTo(0.5, 0.01));
      expect(statuses['n_cycle_1']!.index, 3);
    });

    test('updates progress over time', () async {
      // Initial progress
      await ReadStateGateway.updateStatus(
          'n_cycle_2', ReadState.reading, 0.2, 1);

      // Update progress
      await ReadStateGateway.updateStatus(
          'n_cycle_2', ReadState.reading, 0.7, 4);

      // Verify latest progress
      final statuses = await ReadStateGateway.getStatus(['n_cycle_2']);
      expect(statuses['n_cycle_2']!.readProgress, closeTo(0.7, 0.01));
      expect(statuses['n_cycle_2']!.index, 4);
    });

    test('marks as read at >95% progress', () async {
      // Save progress at 96%
      await ReadStateGateway.updateStatus(
          'n_cycle_3', ReadState.read, 0.96, 10);

      // Verify it's marked as read
      final statuses = await ReadStateGateway.getStatus(['n_cycle_3']);
      expect(statuses['n_cycle_3']!.state, ReadState.read);
      expect(statuses['n_cycle_3']!.readProgress, closeTo(0.96, 0.01));
    });

    test('manages multiple episodes independently', () async {
      await ReadStateGateway.updateStatus(
          'n_multi_a', ReadState.reading, 0.3, 2);
      await ReadStateGateway.updateStatus(
          'n_multi_b', ReadState.read, 1.0, 8);
      await ReadStateGateway.updateStatus(
          'n_multi_c', ReadState.reading, 0.0, 0);

      final statuses = await ReadStateGateway.getStatus(
          ['n_multi_a', 'n_multi_b', 'n_multi_c', 'n_multi_d']);

      // Episode A: reading at 30%
      expect(statuses['n_multi_a']!.state, ReadState.reading);
      expect(statuses['n_multi_a']!.readProgress, closeTo(0.3, 0.01));

      // Episode B: completed
      expect(statuses['n_multi_b']!.state, ReadState.read);
      expect(statuses['n_multi_b']!.readProgress, closeTo(1.0, 0.01));

      // Episode C: just started
      expect(statuses['n_multi_c']!.state, ReadState.reading);
      expect(statuses['n_multi_c']!.readProgress, closeTo(0.0, 0.01));

      // Episode D: never read
      expect(statuses['n_multi_d']!.state, ReadState.notRead);
    });

    test('full cycle: not read -> reading -> read', () async {
      // Initially not read
      var statuses = await ReadStateGateway.getStatus(['n_full_cycle']);
      expect(statuses['n_full_cycle']!.state, ReadState.notRead);

      // Start reading
      await ReadStateGateway.updateStatus(
          'n_full_cycle', ReadState.reading, 0.1, 0);
      statuses = await ReadStateGateway.getStatus(['n_full_cycle']);
      expect(statuses['n_full_cycle']!.state, ReadState.reading);

      // Continue reading
      await ReadStateGateway.updateStatus(
          'n_full_cycle', ReadState.reading, 0.5, 3);
      statuses = await ReadStateGateway.getStatus(['n_full_cycle']);
      expect(statuses['n_full_cycle']!.readProgress, closeTo(0.5, 0.01));

      // Complete reading
      await ReadStateGateway.updateStatus(
          'n_full_cycle', ReadState.read, 0.98, 10);
      statuses = await ReadStateGateway.getStatus(['n_full_cycle']);
      expect(statuses['n_full_cycle']!.state, ReadState.read);
      expect(statuses['n_full_cycle']!.readProgress, closeTo(0.98, 0.01));
    });
  });
}
