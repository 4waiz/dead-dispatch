import 'package:dead_dispatch/domain/services/seeded_random.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SeededRandom', () {
    test('same seed produces same sequence', () {
      final a = SeededRandom(42);
      final b = SeededRandom(42);
      for (var i = 0; i < 100; i++) {
        expect(a.nextU32(), b.nextU32());
      }
    });

    test('different seeds diverge quickly', () {
      final a = SeededRandom(1);
      final b = SeededRandom(2);
      // Guaranteed inequality within a few calls by the xorshift properties.
      bool diverged = false;
      for (var i = 0; i < 5; i++) {
        if (a.nextU32() != b.nextU32()) {
          diverged = true;
          break;
        }
      }
      expect(diverged, isTrue);
    });

    test('nextIntRange stays in bounds', () {
      final rng = SeededRandom(12345);
      for (var i = 0; i < 500; i++) {
        final v = rng.nextIntRange(10, 20);
        expect(v, greaterThanOrEqualTo(10));
        expect(v, lessThan(20));
      }
    });

    test('weightedPick respects weights roughly', () {
      final rng = SeededRandom(7);
      final items = ['a', 'b'];
      final weights = [9.0, 1.0];
      var countA = 0;
      for (var i = 0; i < 10000; i++) {
        if (rng.weightedPick(items, weights) == 'a') countA++;
      }
      // Expected ratio ~0.9. Give it a generous band.
      expect(countA / 10000, closeTo(0.9, 0.02));
    });

    test('zero seed is normalised', () {
      expect(() => SeededRandom(0).nextU32(), returnsNormally);
    });
  });
}
