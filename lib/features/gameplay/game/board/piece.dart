import '../../../../domain/models/block_type.dart';

/// A polyomino piece the player drags onto the board. `cells` lists the
/// occupied cell offsets in piece-local coordinates (row, col); (0,0) is
/// the top-left of the piece's bounding box. Pieces do not rotate in v1.
class Piece {
  const Piece({
    required this.id,
    required this.shapeKey,
    required this.type,
    required this.cells,
    required this.rows,
    required this.cols,
  });

  /// Per-shift unique id (assigned by [PieceBag]).
  final int id;

  /// Stable identifier for the shape (e.g. "single", "lH3", "square2",
  /// "tShape"). Used by debug screens and analytics.
  final String shapeKey;

  final BlockType type;

  /// Cell offsets, sorted (row, col) ascending. List is treated as
  /// immutable.
  final List<PieceCell> cells;

  /// Bounding-box dimensions. `cells` always fits within
  /// `rows × cols`.
  final int rows;
  final int cols;

  int get cellCount => cells.length;

  Piece withId(int newId) => Piece(
        id: newId,
        shapeKey: shapeKey,
        type: type,
        cells: cells,
        rows: rows,
        cols: cols,
      );

  Piece withType(BlockType newType) => Piece(
        id: id,
        shapeKey: shapeKey,
        type: newType,
        cells: cells,
        rows: rows,
        cols: cols,
      );
}

/// Single (row, col) offset within a piece's bounding box.
class PieceCell {
  const PieceCell(this.row, this.col);
  final int row;
  final int col;

  @override
  bool operator ==(Object other) =>
      other is PieceCell && other.row == row && other.col == col;

  @override
  int get hashCode => row * 31 + col;
}
