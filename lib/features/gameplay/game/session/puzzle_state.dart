import '../../../../domain/models/hazard.dart';
import '../board/board.dart';
import '../board/piece.dart';

/// Immutable runtime snapshot for one block-puzzle shift. Mutated only
/// inside [PuzzleSession] via copyWith.
class PuzzleState {
  const PuzzleState({
    required this.board,
    required this.queue,
    required this.score,
    required this.combo,
    required this.coins,
    required this.piecesPlaced,
    required this.linesCleared,
    required this.dailyModifier,
    required this.ended,
    required this.stampBlastCharges,
    required this.ghostSwapCharges,
    required this.completed,
  });

  final Board board;
  final List<Piece> queue;
  final int score;
  final int combo;
  final int coins;
  final int piecesPlaced;
  final int linesCleared;

  /// Active daily modifier (Daily Seal only).
  final HazardKind? dailyModifier;

  /// Charges remaining for the two v1-active power-ups.
  final int stampBlastCharges;
  final int ghostSwapCharges;

  /// True after [GameOverEvent] is dispatched.
  final bool ended;

  /// True when [score] has reached the shift target. Drives the
  /// celebratory result UI.
  final bool completed;

  PuzzleState copyWith({
    Board? board,
    List<Piece>? queue,
    int? score,
    int? combo,
    int? coins,
    int? piecesPlaced,
    int? linesCleared,
    HazardKind? dailyModifier,
    int? stampBlastCharges,
    int? ghostSwapCharges,
    bool? ended,
    bool? completed,
  }) =>
      PuzzleState(
        board: board ?? this.board,
        queue: queue ?? this.queue,
        score: score ?? this.score,
        combo: combo ?? this.combo,
        coins: coins ?? this.coins,
        piecesPlaced: piecesPlaced ?? this.piecesPlaced,
        linesCleared: linesCleared ?? this.linesCleared,
        dailyModifier: dailyModifier ?? this.dailyModifier,
        stampBlastCharges: stampBlastCharges ?? this.stampBlastCharges,
        ghostSwapCharges: ghostSwapCharges ?? this.ghostSwapCharges,
        ended: ended ?? this.ended,
        completed: completed ?? this.completed,
      );
}
