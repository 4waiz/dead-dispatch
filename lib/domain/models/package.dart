import 'block_type.dart';

/// Per-placement record kept in [ShiftResult.records]. One entry every time
/// the player drops a polyomino piece onto the board (valid or invalid is
/// not recorded here — only successful placements). Used by the result
/// screen for the lines-cleared / biggest-combo tally and by analytics.
class PlacementRecord {
  const PlacementRecord({
    required this.pieceId,
    required this.type,
    required this.cellsPlaced,
    required this.linesCleared,
    required this.scoreDelta,
    required this.coinDelta,
  });

  final int pieceId;
  final BlockType type;

  /// Number of board cells the placed piece occupies.
  final int cellsPlaced;

  /// Rows + columns cleared by this single placement (0 if none).
  final int linesCleared;

  final int scoreDelta;
  final int coinDelta;
}
