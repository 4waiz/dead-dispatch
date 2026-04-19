/// Deterministic xorshift32 RNG. Required for reproducible daily challenges
/// and for replayable bug reports. Avoids `dart:math.Random` because that
/// class doesn't expose its internal state, which makes save/replay harder.
class SeededRandom {
  SeededRandom(int seed) : _state = (seed == 0 ? 0x9E3779B9 : seed) & 0xFFFFFFFF;

  int _state;

  /// Returns next 32-bit unsigned int.
  int nextU32() {
    int x = _state;
    x ^= (x << 13) & 0xFFFFFFFF;
    x ^= (x >> 17);
    x ^= (x << 5) & 0xFFFFFFFF;
    _state = x & 0xFFFFFFFF;
    return _state;
  }

  /// Uniform in [0, 1).
  double nextDouble() => nextU32() / 0x100000000;

  /// Uniform in [min, max).
  int nextIntRange(int min, int max) {
    if (max <= min) return min;
    return min + (nextDouble() * (max - min)).floor();
  }

  T pick<T>(List<T> items) {
    if (items.isEmpty) {
      throw StateError('SeededRandom.pick called on empty list');
    }
    return items[nextIntRange(0, items.length)];
  }

  /// Weighted pick. Weights must be non-negative and sum to > 0.
  T weightedPick<T>(List<T> items, List<double> weights) {
    if (items.length != weights.length || items.isEmpty) {
      throw ArgumentError('items/weights size mismatch');
    }
    double total = 0;
    for (final w in weights) {
      total += w;
    }
    if (total <= 0) return items.first;
    double roll = nextDouble() * total;
    for (var i = 0; i < items.length; i++) {
      roll -= weights[i];
      if (roll <= 0) return items[i];
    }
    return items.last;
  }

  int get state => _state;
  set state(int v) => _state = v & 0xFFFFFFFF;
}
