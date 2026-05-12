import 'package:dead_dispatch/domain/models/block_type.dart';
import 'package:dead_dispatch/features/gameplay/game/board/board.dart';
import 'package:dead_dispatch/features/gameplay/game/board/piece.dart';
import 'package:dead_dispatch/features/gameplay/game/board/placement_service.dart';
import 'package:flutter_test/flutter_test.dart';

Piece _piece({
  int id = 0,
  String key = 'single',
  BlockType type = BlockType.standard,
  required List<PieceCell> cells,
  required int rows,
  required int cols,
}) =>
    Piece(
      id: id,
      shapeKey: key,
      type: type,
      cells: cells,
      rows: rows,
      cols: cols,
    );

void main() {
  const svc = PlacementService();

  group('PlacementService.tryPlace', () {
    test('valid placement on an empty board returns the new board', () {
      final board = Board.empty(8);
      final piece = _piece(
        cells: const [PieceCell(0, 0), PieceCell(0, 1)],
        rows: 1,
        cols: 2,
      );
      final out = svc.tryPlace(
        board: board,
        piece: piece,
        anchorRow: 3,
        anchorCol: 4,
      );
      expect(out, isNotNull);
      expect(out!.newBoard.isFilled(3, 4), isTrue);
      expect(out.newBoard.isFilled(3, 5), isTrue);
      expect(out.linesCleared, 0);
    });

    test('invalid placement (out of bounds) returns null', () {
      final board = Board.empty(8);
      final piece = _piece(
        cells: const [PieceCell(0, 0), PieceCell(0, 1)],
        rows: 1,
        cols: 2,
      );
      // Anchor at column 7 with a 2-wide piece overflows the right edge.
      final out = svc.tryPlace(
        board: board,
        piece: piece,
        anchorRow: 0,
        anchorCol: 7,
      );
      expect(out, isNull);
    });

    test('invalid placement (overlap with filled cell) returns null', () {
      final piece = _piece(
        cells: const [PieceCell(0, 0)],
        rows: 1,
        cols: 1,
      );
      final board = Board.empty(8).place(piece, 2, 2);
      final out = svc.tryPlace(
        board: board,
        piece: piece,
        anchorRow: 2,
        anchorCol: 2,
      );
      expect(out, isNull);
    });

    test('placement at top-left corner is valid', () {
      final piece = _piece(
        cells: const [PieceCell(0, 0)],
        rows: 1,
        cols: 1,
      );
      final out = svc.tryPlace(
        board: Board.empty(8),
        piece: piece,
        anchorRow: 0,
        anchorCol: 0,
      );
      expect(out, isNotNull);
      expect(out!.newBoard.isFilled(0, 0), isTrue);
    });

    test('placement at bottom-right corner is valid for a fitting piece', () {
      final piece = _piece(
        cells: const [PieceCell(0, 0)],
        rows: 1,
        cols: 1,
      );
      final out = svc.tryPlace(
        board: Board.empty(8),
        piece: piece,
        anchorRow: 7,
        anchorCol: 7,
      );
      expect(out, isNotNull);
      expect(out!.newBoard.isFilled(7, 7), isTrue);
    });

    test('off-grid anchor (negative) returns null', () {
      final piece = _piece(
        cells: const [PieceCell(0, 0)],
        rows: 1,
        cols: 1,
      );
      final out = svc.tryPlace(
        board: Board.empty(8),
        piece: piece,
        anchorRow: -1,
        anchorCol: 0,
      );
      expect(out, isNull);
    });
  });

  group('PlacementService.isGameOver', () {
    test('returns false when at least one piece can fit', () {
      final board = Board.empty(8);
      final piece = _piece(
        cells: const [PieceCell(0, 0)],
        rows: 1,
        cols: 1,
      );
      expect(svc.isGameOver(board, [piece]), isFalse);
    });

    test('returns true when nothing fits', () {
      // Fill every cell.
      final piece1x1 = _piece(
        cells: const [PieceCell(0, 0)],
        rows: 1,
        cols: 1,
      );
      var board = Board.empty(8);
      for (var r = 0; r < 8; r++) {
        for (var c = 0; c < 8; c++) {
          board = board.place(piece1x1, r, c);
        }
      }
      expect(svc.isGameOver(board, [piece1x1]), isTrue);
    });
  });
}
