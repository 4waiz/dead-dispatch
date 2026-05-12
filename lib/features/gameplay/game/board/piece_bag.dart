import '../../../../domain/models/block_type.dart';
import '../../../../domain/services/seeded_random.dart';
import 'piece.dart';
import 'piece_library.dart';

/// Deterministic generator for the player's piece queue. Same seed +
/// same `allowedTypes` → same sequence of pieces forever.
///
/// The bag draws shapes via [SeededRandom.weightedPick] (so early shifts
/// trend toward easier shapes) and types via [SeededRandom.pick] over
/// the allowed list. Each call to [next] returns a fresh [Piece] with a
/// unique per-bag id.
class PieceBag {
  PieceBag({
    required int seed,
    required this.allowedTypes,
    List<ShapeTemplate>? shapes,
    int startingId = 0,
  })  : _rng = SeededRandom(seed),
        _shapes = shapes ?? PieceLibrary.all,
        _nextId = startingId {
    if (allowedTypes.isEmpty) {
      throw ArgumentError('allowedTypes must not be empty');
    }
    if (_shapes.isEmpty) {
      throw ArgumentError('shapes must not be empty');
    }
    _weights = _shapes.map((s) => s.weight).toList(growable: false);
  }

  final SeededRandom _rng;
  final List<BlockType> allowedTypes;
  final List<ShapeTemplate> _shapes;
  late final List<double> _weights;
  int _nextId;

  /// Draw one piece.
  Piece next() {
    final shape = _rng.weightedPick(_shapes, _weights);
    final type = _rng.pick(allowedTypes);
    final piece = shape.toPiece(id: _nextId++, type: type);
    return piece;
  }

  /// Draw [count] pieces — used to refill the player's tray.
  List<Piece> nextN(int count) {
    return List<Piece>.generate(count, (_) => next(), growable: false);
  }
}
