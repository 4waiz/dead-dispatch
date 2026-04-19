import 'package:dead_dispatch/domain/services/daily_seed.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DailySeed', () {
    test('deterministic across calls', () {
      expect(DailySeed.seedFor('2026-04-19'), DailySeed.seedFor('2026-04-19'));
    });

    test('different dates give different seeds', () {
      expect(
        DailySeed.seedFor('2026-04-19'),
        isNot(DailySeed.seedFor('2026-04-20')),
      );
    });

    test('dateKey formats as YYYY-MM-DD UTC', () {
      final key = DailySeed.dateKey(DateTime.utc(2026, 4, 19));
      expect(key, '2026-04-19');
    });

    test('dateKey zero-pads single-digit month/day', () {
      final key = DailySeed.dateKey(DateTime.utc(2026, 1, 3));
      expect(key, '2026-01-03');
    });
  });
}
