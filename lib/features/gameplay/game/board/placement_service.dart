import 'board.dart';
import 'piece.dart';

/// Pure-function facade around `Board` for "place a piece and resolve
/// any clears that result". Returns a [PlacementOutcome] capturing the
/// new board state and the lines cleared. Game logic should always go
/// through this instead of calling `Board.place` + `Board.clearLines`
/// in two separate steps.
class PlacementService {
  const PlacementService();

  /// Returns null if the placement is invalid; otherwise returns the
  /// resolved outcome.
  PlacementOutcome? tryPlace({
    required Board board,
    required Piece piece,
    required int anchorRow,
    required int anchorCol,
  }) {
    if (!board.canPlace(piece, anchorRow, anchorCol)) return null;
    final placed = board.place(piece, anchorRow, anchorCol);
    final rows = placed.fullRows();
    final cols = placed.fullCols();
    final clear = placed.clearLines(rows, cols);
    return PlacementOutcome(
      newBoard: clear.board,
      anchorRow: anchorRow,
      anchorCol: anchorCol,
      clearedRows: clear.clearedRows,
      clearedCols: clear.clearedCols,
      boardCleared: clear.board.isBoardEmpty,
    );
  }

  /// Pure board-level game-over check. True when none of the queued
  /// pieces can be placed anywhere.
  bool isGameOver(Board board, Iterable<Piece> queue) =>
      board.isGameOver(queue);
}

class PlacementOutcome {
  const PlacementOutcome({
    required this.newBoard,
    required this.anchorRow,
    required this.anchorCol,
    required this.clearedRows,
    required this.clearedCols,
    required this.boardCleared,
  });

  final Board newBoard;
  final int anchorRow;
  final int anchorCol;
  final List<int> clearedRows;
  final List<int> clearedCols;
  final bool boardCleared;

  int get linesCleared => clearedRows.length + clearedCols.length;
}
