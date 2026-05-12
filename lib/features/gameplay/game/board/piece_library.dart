import '../../../../domain/models/block_type.dart';
import 'piece.dart';

/// Canonical polyomino shapes the bag draws from. Each entry has a weight
/// used by [PieceBag] — higher weight = more common. Heavier (5-cell)
/// shapes have lower weight to keep the bag forgiving in early game.
///
/// Rotations are not modeled in v1 — every shape lists its single
/// canonical orientation. To get an "L rotated", we list it as a distinct
/// shape (lL2, lJ2, etc.) so the bag's distribution stays explicit.
class ShapeTemplate {
  const ShapeTemplate({
    required this.key,
    required this.rows,
    required this.cols,
    required this.cells,
    required this.weight,
  });

  final String key;
  final int rows;
  final int cols;
  final List<PieceCell> cells;

  /// Relative draw weight. Sums across templates do not need to be 1 —
  /// `PieceBag.weightedPick` normalises internally.
  final double weight;

  /// Build a [Piece] from this template. `id` and `type` are assigned by
  /// the bag.
  Piece toPiece({required int id, required BlockType type}) => Piece(
        id: id,
        shapeKey: key,
        type: type,
        cells: cells,
        rows: rows,
        cols: cols,
      );
}

class PieceLibrary {
  const PieceLibrary._();

  /// All canonical shapes used by the bag.
  static const List<ShapeTemplate> all = [
    // Singles and small lines — easy to place anywhere.
    ShapeTemplate(
      key: 'single',
      rows: 1,
      cols: 1,
      cells: [PieceCell(0, 0)],
      weight: 1.4,
    ),
    ShapeTemplate(
      key: 'line2H',
      rows: 1,
      cols: 2,
      cells: [PieceCell(0, 0), PieceCell(0, 1)],
      weight: 1.4,
    ),
    ShapeTemplate(
      key: 'line2V',
      rows: 2,
      cols: 1,
      cells: [PieceCell(0, 0), PieceCell(1, 0)],
      weight: 1.4,
    ),
    ShapeTemplate(
      key: 'line3H',
      rows: 1,
      cols: 3,
      cells: [PieceCell(0, 0), PieceCell(0, 1), PieceCell(0, 2)],
      weight: 1.2,
    ),
    ShapeTemplate(
      key: 'line3V',
      rows: 3,
      cols: 1,
      cells: [PieceCell(0, 0), PieceCell(1, 0), PieceCell(2, 0)],
      weight: 1.2,
    ),

    // 2×2 square.
    ShapeTemplate(
      key: 'square2',
      rows: 2,
      cols: 2,
      cells: [
        PieceCell(0, 0),
        PieceCell(0, 1),
        PieceCell(1, 0),
        PieceCell(1, 1),
      ],
      weight: 1.0,
    ),

    // L-tetrominoes (4 cells) — 4 orientations, treated as distinct shapes.
    ShapeTemplate(
      key: 'lA',
      rows: 2,
      cols: 2,
      cells: [
        PieceCell(0, 0),
        PieceCell(1, 0),
        PieceCell(1, 1),
      ],
      weight: 1.0,
    ),
    ShapeTemplate(
      key: 'lB',
      rows: 2,
      cols: 2,
      cells: [
        PieceCell(0, 0),
        PieceCell(0, 1),
        PieceCell(1, 0),
      ],
      weight: 1.0,
    ),
    ShapeTemplate(
      key: 'lC',
      rows: 2,
      cols: 2,
      cells: [
        PieceCell(0, 0),
        PieceCell(0, 1),
        PieceCell(1, 1),
      ],
      weight: 1.0,
    ),
    ShapeTemplate(
      key: 'lD',
      rows: 2,
      cols: 2,
      cells: [
        PieceCell(0, 1),
        PieceCell(1, 0),
        PieceCell(1, 1),
      ],
      weight: 1.0,
    ),

    // T-shape.
    ShapeTemplate(
      key: 'tShape',
      rows: 2,
      cols: 3,
      cells: [
        PieceCell(0, 0),
        PieceCell(0, 1),
        PieceCell(0, 2),
        PieceCell(1, 1),
      ],
      weight: 0.8,
    ),

    // Zigzag (S-piece).
    ShapeTemplate(
      key: 'zigzag',
      rows: 2,
      cols: 3,
      cells: [
        PieceCell(0, 1),
        PieceCell(0, 2),
        PieceCell(1, 0),
        PieceCell(1, 1),
      ],
      weight: 0.7,
    ),

    // 5-block chunky (P-pentomino-ish).
    ShapeTemplate(
      key: 'chunky5',
      rows: 3,
      cols: 2,
      cells: [
        PieceCell(0, 0),
        PieceCell(0, 1),
        PieceCell(1, 0),
        PieceCell(1, 1),
        PieceCell(2, 0),
      ],
      weight: 0.4,
    ),
  ];

  /// Lighter-weighted subset for the very first shift (used when the
  /// `bagSoftness` upgrade is active or when level == 0).
  static const List<String> easyShapeKeys = [
    'single',
    'line2H',
    'line2V',
    'line3H',
    'line3V',
    'square2',
    'lA',
    'lB',
  ];
}
