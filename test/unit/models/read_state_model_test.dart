import 'package:flutter_test/flutter_test.dart';
import 'package:ninja_scrolls/src/gateway/database/read_state.dart';

void main() {
  group('ReadStatus.fromDatabase', () {
    test('maps completed state correctly', () {
      final status = ReadStatus.fromDatabase({
        'is_completed': 1,
        'read_progress': 950,
        '_index': 5,
      });
      expect(status.state, ReadState.read);
      expect(status.readProgress, closeTo(0.95, 0.001));
      expect(status.index, 5);
    });

    test('maps reading state correctly', () {
      final status = ReadStatus.fromDatabase({
        'is_completed': 0,
        'read_progress': 500,
        '_index': 3,
      });
      expect(status.state, ReadState.reading);
      expect(status.readProgress, closeTo(0.5, 0.001));
      expect(status.index, 3);
    });

    test('maps zero progress', () {
      final status = ReadStatus.fromDatabase({
        'is_completed': 0,
        'read_progress': 0,
        '_index': 0,
      });
      expect(status.state, ReadState.reading);
      expect(status.readProgress, 0.0);
      expect(status.index, 0);
    });
  });

  group('ReadStatus.zero', () {
    test('returns default values', () {
      final status = ReadStatus.zero();
      expect(status.state, ReadState.notRead);
      expect(status.readProgress, 0.0);
      expect(status.index, 0);
    });
  });
}
