import 'package:flutter_test/flutter_test.dart';
import 'package:ninja_scrolls/src/gateway/database/read_state.dart';

import '../../helpers/test_database_helper.dart';

void main() {
  setUp(() async {
    await setupTestDatabase();
  });

  tearDown(() async {
    await tearDownTestDatabase();
  });

  group('ReadStateGateway', () {
    test('getStatus returns ReadStatus.zero() for unregistered note', () async {
      final statuses = await ReadStateGateway.getStatus(['unknown_id']);
      expect(statuses['unknown_id'], isNotNull);
      expect(statuses['unknown_id']!.state, ReadState.notRead);
      expect(statuses['unknown_id']!.readProgress, 0.0);
      expect(statuses['unknown_id']!.index, 0);
    });

    test('updateStatus inserts new record', () async {
      await ReadStateGateway.updateStatus(
          'n_rs_1', ReadState.reading, 0.5, 3);
      final statuses = await ReadStateGateway.getStatus(['n_rs_1']);
      expect(statuses['n_rs_1']!.state, ReadState.reading);
      expect(statuses['n_rs_1']!.readProgress, closeTo(0.5, 0.01));
      expect(statuses['n_rs_1']!.index, 3);
    });

    test('updateStatus updates existing record', () async {
      await ReadStateGateway.updateStatus(
          'n_rs_2', ReadState.reading, 0.3, 1);
      await ReadStateGateway.updateStatus(
          'n_rs_2', ReadState.read, 0.95, 5);
      final statuses = await ReadStateGateway.getStatus(['n_rs_2']);
      expect(statuses['n_rs_2']!.state, ReadState.read);
      expect(statuses['n_rs_2']!.readProgress, closeTo(0.95, 0.01));
      expect(statuses['n_rs_2']!.index, 5);
    });

    test('updateStatus clamps NaN to 0.0', () async {
      await ReadStateGateway.updateStatus(
          'n_rs_nan', ReadState.reading, double.nan, 0);
      final statuses = await ReadStateGateway.getStatus(['n_rs_nan']);
      expect(statuses['n_rs_nan']!.readProgress, 0.0);
    });

    test('updateStatus clamps >1.0 to 1.0', () async {
      await ReadStateGateway.updateStatus(
          'n_rs_over', ReadState.reading, 1.5, 0);
      final statuses = await ReadStateGateway.getStatus(['n_rs_over']);
      expect(statuses['n_rs_over']!.readProgress, closeTo(1.0, 0.01));
    });

    test('updateStatus clamps Infinity to 1.0', () async {
      await ReadStateGateway.updateStatus(
          'n_rs_inf', ReadState.reading, double.infinity, 0);
      final statuses = await ReadStateGateway.getStatus(['n_rs_inf']);
      expect(statuses['n_rs_inf']!.readProgress, closeTo(1.0, 0.01));
    });

    test('updateStatus handles null readProgress', () async {
      await ReadStateGateway.updateStatus(
          'n_rs_null', ReadState.reading, null, 0);
      final statuses = await ReadStateGateway.getStatus(['n_rs_null']);
      expect(statuses['n_rs_null']!.readProgress, 0.0);
    });

    test('getStatus returns multiple statuses', () async {
      await ReadStateGateway.updateStatus(
          'n_multi_1', ReadState.reading, 0.3, 1);
      await ReadStateGateway.updateStatus(
          'n_multi_2', ReadState.read, 1.0, 5);
      final statuses =
          await ReadStateGateway.getStatus(['n_multi_1', 'n_multi_2', 'n_multi_3']);
      expect(statuses.length, 3);
      expect(statuses['n_multi_1']!.state, ReadState.reading);
      expect(statuses['n_multi_2']!.state, ReadState.read);
      expect(statuses['n_multi_3']!.state, ReadState.notRead);
    });

    test('deleteAll removes all read states', () async {
      await ReadStateGateway.updateStatus(
          'n_del_1', ReadState.reading, 0.5, 1);
      await ReadStateGateway.updateStatus(
          'n_del_2', ReadState.read, 1.0, 2);
      await ReadStateGateway.deleteAll();
      final statuses =
          await ReadStateGateway.getStatus(['n_del_1', 'n_del_2']);
      expect(statuses['n_del_1']!.state, ReadState.notRead);
      expect(statuses['n_del_2']!.state, ReadState.notRead);
    });
  });
}
