import 'package:dead_dispatch/domain/models/block_type.dart';
import 'package:dead_dispatch/features/gameplay/game/board/board.dart';
import 'package:dead_dispatch/features/gameplay/game/board/piece.dart';
import 'package:dead_dispatch/features/gameplay/game/board/placement_service.dart';
import 'package:flutter_test/flutter_test.dart';

Piece _piece({
  required List<PieceCell> cells,
  required int rows,
  required int cols,
  BlockType type = BlockType.standard,
  int id = 0,
  String key = 'shape',
}) =>
    Piece(
      id: id,
      shapeKey: key,
      type: type,
      cells: cells,
      rows: rows,
      cols: cols,
    );

/// Returns a single-cell piece for filling a board in tests.
Piece _cellPiece({BlockType type = BlockType.standard}) => _piece(
      cells: const [PieceCell(0, 0)],
      rows: 1,
      cols: 1,
      type: type,
    );

void main() {
  group('Board basics', () {
    test('Board.empty produces a board of the requested size with no cells', () {
      final board = Board.empty(8);
      expect(board.size, 8);
      expect(board.filledCount, 0);
      expect(board.isBoardEmpty, isTrue);
    });

    test('place puts cells at the right coordinates and is immutable', () {
      final empty = Board.empty(8);
      final piece = _piece(
        cells: const [PieceCell(0, 0), PieceCell(0, 1)],
        rows: 1,
        cols: 2,
      );
      final placed = empty.place(piece, 2, 3);
      // Original is untouched.
      expect(empty.isEmpty(2, 3), isTrue);
      expect(empty.isEmpty(2, 4), isTrue);
      // New board has both cells.
      expect(placed.isFilled(2, 3), isTrue);
      expect(placed.isFilled(2, 4), isTrue);
      expect(placed.cellAt(2, 3), BlockType.standard);
    });

    test('canPlace rejects overlapping placement', () {
      final piece = _cellPiece();
      final board = Board.empty(4).place(piece, 1, 1);
      expect(board.canPlace(piece, 1, 1), isFalse);
    });
  });

  group('Line clearing', () {
    test('single full row is detected and cleared', () {
      var board = Board.empty(4);
      final cell = _cellPiece();
      for (var c = 0; c < 4; c++) {
        board = board.place(cell, 2, c);
      }
      expect(board.fullRows(), [2]);
      expect(board.fullCols(), isEmpty);
      final cleared = board.clearLines([2], const []);
      expect(cleared.board.isFilled(2, 0), isFalse);
      expect(cleared.linesCleared, 1);
    });

    test('single full column is detected and cleared', () {
      var board = Board.empty(4);
      final cell = _cellPiece();
      for (var r = 0; r < 4; r++) {
        board = board.place(cell, r, 1);
      }
      expect(board.fullCols(), [1]);
      expect(board.fullRows(), isEmpty);
      final cleared = board.clearLines(const [], [1]);
      expect(cleared.board.isFilled(0, 1), isFalse);
      expect(cleared.linesCleared, 1);
    });

    test('placement that triggers multi-line clear (2 rows + 1 col)', () {
      // 4x4 board. Pre-fill rows 0 and 1 (except column 3), plus column
      // 3 rows 2 and 3 (so dropping a 2x1 vertical at (0,3) completes
      // both rows AND column 3 in one placement → 2 rows + 1 col).
      var board = Board.empty(4);
      final cell = _cellPiece();
      for (var c = 0; c < 3; c++) {
        board = board.place(cell, 0, c);
        board = board.place(cell, 1, c);
      }
      board = board.place(cell, 2, 3);
      board = board.place(cell, 3, 3);
      final piece = _piece(
        cells: const [PieceCell(0, 0), PieceCell(1, 0)],
        rows: 2,
        cols: 1,
      );
      final out = const PlacementService().tryPlace(
        board: board,
        piece: piece,
        anchorRow: 0,
        anchorCol: 3,
      );
      expect(out, isNotNull);
      expect(out!.clearedRows, containsAll([0, 1]));
      expect(out.clearedCols, contains(3));
      expect(out.linesCleared, 3);
    });

    test('placement leaving the board empty reports boardCleared', () {
      // 2×2 board. Fill (0,1), (1,0), (1,1). Place single at (0,0) →
      // both rows AND both columns are full simultaneously, so 2 rows
      // + 2 cols = 4 lines clear → board empty.
      final cell = _cellPiece();
      var board = Board.empty(2);
      board = board.place(cell, 0, 1);
      board = board.place(cell, 1, 0);
      board = board.place(cell, 1, 1);
      final out = const PlacementService().tryPlace(
        board: board,
        piece: cell,
        anchorRow: 0,
        anchorCol: 0,
      );
      expect(out, isNotNull);
      expect(out!.linesCleared, 4);
      expect(out.boardCleared, isTrue);
      expect(out.newBoard.filledCount, 0);
    });
  });

  group('Game over', () {
    test('isGameOver false when any queued piece can be placed', () {
      final cell = _cellPiece();
      final board = Board.empty(4);
      expect(board.isGameOver([cell]), isFalse);
    });

    test('isGameOver true when no queued piece fits', () {
      final cell = _cellPiece();
      // Fill every cell of a 3×3 board.
      var board = Board.empty(3);
      for (var r = 0; r < 3; r++) {
        for (var c = 0; c < 3; c++) {
          board = board.place(cell, r, c);
        }
      }
      expect(board.isGameOver([cell]), isTrue);
    });

    test('isGameOver true when board is empty but no piece exists', () {
      // Edge case: empty queue triggers game over. (PuzzleSession ensures
      // this never happens in practice, but the predicate should still
      // behave.)
      final board = Board.empty(3);
      expect(board.isGameOver(const <Piece>[]), isTrue);
    });
  });
}
