import '../../../../domain/models/shift_result.dart';
import '../board/piece.dart';

/// Sealed event hierarchy emitted by [PuzzleSession]. The HUD listens
/// for visual updates; an audio/haptics adapter listens for SFX cues.
sealed class PuzzleEvent {
  const PuzzleEvent();
}

final class PiecePickedUpEvent extends PuzzleEvent {
  const PiecePickedUpEvent(this.piece);
  final Piece piece;
}

final class PiecePlacedEvent extends PuzzleEvent {
  const PiecePlacedEvent({
    required this.piece,
    required this.anchorRow,
    required this.anchorCol,
    required this.linesCleared,
    required this.scoreDelta,
    required this.coinDelta,
  });
  final Piece piece;
  final int anchorRow;
  final int anchorCol;
  final int linesCleared;
  final int scoreDelta;
  final int coinDelta;
}

final class InvalidDropEvent extends PuzzleEvent {
  const InvalidDropEvent({
    required this.piece,
    required this.anchorRow,
    required this.anchorCol,
  });
  final Piece piece;
  final int anchorRow;
  final int anchorCol;
}

final class LinesClearedEvent extends PuzzleEvent {
  const LinesClearedEvent({
    required this.rows,
    required this.cols,
  });
  final List<int> rows;
  final List<int> cols;

  int get count => rows.length + cols.length;
}

final class ComboChangedEvent extends PuzzleEvent {
  const ComboChangedEvent({required this.combo, required this.multiplier});
  final int combo;
  final double multiplier;
}

final class QueueRefilledEvent extends PuzzleEvent {
  const QueueRefilledEvent(this.queue);
  final List<Piece> queue;
}

final class BoardClearedEvent extends PuzzleEvent {
  const BoardClearedEvent();
}

/// Fired when [score] crosses the configured target threshold. The HUD
/// uses this for celebratory feedback; the result screen still uses
/// [ShiftResult.completed] as the authoritative flag.
final class ShiftTargetReachedEvent extends PuzzleEvent {
  const ShiftTargetReachedEvent(this.score);
  final int score;
}

final class PowerUpUsedEvent extends PuzzleEvent {
  const PowerUpUsedEvent(this.id);
  final PowerUpId id;
}

final class GameOverEvent extends PuzzleEvent {
  const GameOverEvent(this.result);
  final ShiftResult result;
}

/// Power-ups exposed in v1.
enum PowerUpId {
  stampBlast,
  ghostSwap,
  returnSender, // stubbed for v1.1
  lanternSweep; // stubbed for v1.1
}
