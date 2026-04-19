import 'dart:math' as math;

import '../../domain/services/seeded_random.dart';

/// RNG boundary. Production code accepts a [RandomSource] so tests can
/// inject a deterministic stream. Two canonical implementations:
///
///   * [SeededRandomSource] — wraps [SeededRandom] (xorshift32). Use when
///     reproducibility matters (daily challenges, replay, QA repros).
///   * [SystemRandomSource] — wraps `dart:math.Random`. Use for cosmetic
///     effects where determinism is not required (particle scatter, UI
///     confetti timing).
abstract class RandomSource {
  double nextDouble();
  int nextIntRange(int minInclusive, int maxExclusive);
  T pick<T>(List<T> items);
  T weightedPick<T>(List<T> items, List<double> weights);
}

/// Deterministic xorshift32 — reproducible given the same seed.
class SeededRandomSource implements RandomSource {
  SeededRandomSource(int seed) : _rng = SeededRandom(seed);
  final SeededRandom _rng;

  @override
  double nextDouble() => _rng.nextDouble();

  @override
  int nextIntRange(int minInclusive, int maxExclusive) =>
      _rng.nextIntRange(minInclusive, maxExclusive);

  @override
  T pick<T>(List<T> items) => _rng.pick(items);

  @override
  T weightedPick<T>(List<T> items, List<double> weights) =>
      _rng.weightedPick(items, weights);

  int get state => _rng.state;
}

/// Non-deterministic fallback. Seeded from system time so separate
/// instances don't collide in the same microsecond.
class SystemRandomSource implements RandomSource {
  SystemRandomSource([int? seed])
      : _rng = math.Random(seed ?? DateTime.now().microsecondsSinceEpoch);

  final math.Random _rng;

  @override
  double nextDouble() => _rng.nextDouble();

  @override
  int nextIntRange(int minInclusive, int maxExclusive) {
    if (maxExclusive <= minInclusive) return minInclusive;
    return minInclusive + _rng.nextInt(maxExclusive - minInclusive);
  }

  @override
  T pick<T>(List<T> items) {
    if (items.isEmpty) {
      throw StateError('pick called on empty list');
    }
    return items[_rng.nextInt(items.length)];
  }

  @override
  T weightedPick<T>(List<T> items, List<double> weights) {
    if (items.length != weights.length || items.isEmpty) {
      throw ArgumentError('items/weights size mismatch');
    }
    double total = 0;
    for (final w in weights) {
      total += w;
    }
    if (total <= 0) return items.first;
    double roll = _rng.nextDouble() * total;
    for (var i = 0; i < items.length; i++) {
      roll -= weights[i];
      if (roll <= 0) return items[i];
    }
    return items.last;
  }
}
