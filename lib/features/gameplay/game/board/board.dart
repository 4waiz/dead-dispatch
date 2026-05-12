import '../../../../domain/models/block_type.dart';
import 'piece.dart';

/// Square board of [size]×[size] cells. Each cell is either empty
/// (`null`) or holds a [BlockType] indicating colour and (later) the
/// origin piece of the placed cell.
///
/// `Board` is logically immutable: every mutator returns a new instance.
/// Internally it stores cells in a single flat list to keep allocations
/// cheap; `copy()` allocates one list of size² and one new wrapper.
class Board {
  Board._(this.size, this._cells);

  final int size;
  final List<BlockType?> _cells;

  /// An all-empty board of the given size.
  factory Board.empty(int size) {
    final cells = List<BlockType?>.filled(size * size, null);
    return Board._(size, cells);
  }

  /// Build a board from an explicit row-major grid (useful for tests).
  /// Each inner list must have length [size].
  factory Board.fromRows(List<List<BlockType?>> rows) {
    final size = rows.length;
    final flat = List<BlockType?>.filled(size * size, null);
    for (var r = 0; r < size; r++) {
      assert(rows[r].length == size, 'row $r has wrong width');
      for (var c = 0; c < size; c++) {
        flat[r * size + c] = rows[r][c];
      }
    }
    return Board._(size, flat);
  }

  /// Returns the cell at `(row, col)`, or null if off-grid or empty.
  BlockType? cellAt(int row, int col) {
    if (!_inBounds(row, col)) return null;
    return _cells[row * size + col];
  }

  bool isEmpty(int row, int col) {
    if (!_inBounds(row, col)) return false;
    return _cells[row * size + col] == null;
  }

  bool isFilled(int row, int col) {
    if (!_inBounds(row, col)) return false;
    return _cells[row * size + col] != null;
  }

  bool _inBounds(int row, int col) =>
      row >= 0 && col >= 0 && row < size && col < size;

  /// Count of filled cells. O(size²).
  int get filledCount {
    var n = 0;
    for (final cell in _cells) {
      if (cell != null) n++;
    }
    return n;
  }

  bool get isBoardEmpty => filledCount == 0;

  /// Returns true if every cell of [piece] anchored at (anchorRow,
  /// anchorCol) is in bounds and currently empty.
  bool canPlace(Piece piece, int anchorRow, int anchorCol) {
    for (final cell in piece.cells) {
      final r = anchorRow + cell.row;
      final c = anchorCol + cell.col;
      if (!_inBounds(r, c)) return false;
      if (_cells[r * size + c] != null) return false;
    }
    return true;
  }

  /// Place [piece] at (anchorRow, anchorCol) and return the new board.
  /// Throws if the placement is invalid — callers should pre-check via
  /// [canPlace].
  Board place(Piece piece, int anchorRow, int anchorCol) {
    if (!canPlace(piece, anchorRow, anchorCol)) {
      throw StateError(
        'Invalid placement: piece ${piece.shapeKey} at '
        '($anchorRow,$anchorCol) on $size×$size board',
      );
    }
    final next = List<BlockType?>.from(_cells);
    for (final cell in piece.cells) {
      final r = anchorRow + cell.row;
      final c = anchorCol + cell.col;
      next[r * size + c] = piece.type;
    }
    return Board._(size, next);
  }

  /// Returns the indices of rows that are completely filled.
  List<int> fullRows() {
    final rows = <int>[];
    for (var r = 0; r < size; r++) {
      var allFilled = true;
      for (var c = 0; c < size; c++) {
        if (_cells[r * size + c] == null) {
          allFilled = false;
          break;
        }
      }
      if (allFilled) rows.add(r);
    }
    return rows;
  }

  /// Returns the indices of columns that are completely filled.
  List<int> fullCols() {
    final cols = <int>[];
    for (var c = 0; c < size; c++) {
      var allFilled = true;
      for (var r = 0; r < size; r++) {
        if (_cells[r * size + c] == null) {
          allFilled = false;
          break;
        }
      }
      if (allFilled) cols.add(c);
    }
    return cols;
  }

  /// Clear the given rows and columns. Returns a [ClearResult] with the
  /// new board state and the cells that were cleared (for animation).
  ClearResult clearLines(List<int> rows, List<int> cols) {
    if (rows.isEmpty && cols.isEmpty) {
      return ClearResult(board: this, clearedRows: const [], clearedCols: const []);
    }
    final next = List<BlockType?>.from(_cells);
    for (final r in rows) {
      for (var c = 0; c < size; c++) {
        next[r * size + c] = null;
      }
    }
    for (final c in cols) {
      for (var r = 0; r < size; r++) {
        next[r * size + c] = null;
      }
    }
    return ClearResult(
      board: Board._(size, next),
      clearedRows: List.unmodifiable(rows),
      clearedCols: List.unmodifiable(cols),
    );
  }

  /// True when none of the given pieces can be placed anywhere on the
  /// board. Used by the session to decide game over after the queue
  /// refills or after a placement.
  bool isGameOver(Iterable<Piece> queue) {
    for (final piece in queue) {
      if (_anyValidPlacement(piece)) return false;
    }
    return true;
  }

  bool _anyValidPlacement(Piece piece) {
    for (var r = 0; r <= size - piece.rows; r++) {
      for (var c = 0; c <= size - piece.cols; c++) {
        if (canPlace(piece, r, c)) return true;
      }
    }
    return false;
  }

  /// Direct cell access for renderers (read-only view).
  Iterable<BlockType?> get cells => List.unmodifiable(_cells);
}

/// Result of clearing rows + columns from a board.
class ClearResult {
  const ClearResult({
    required this.board,
    required this.clearedRows,
    required this.clearedCols,
  });

  final Board board;
  final List<int> clearedRows;
  final List<int> clearedCols;

  /// Total number of lines cleared (rows + cols).
  int get linesCleared => clearedRows.length + clearedCols.length;

  /// Total cells that became empty as a result of the clear (cells at
  /// row+col intersections are counted once).
  int cellCount(int boardSize) {
    if (clearedRows.isEmpty && clearedCols.isEmpty) return 0;
    return clearedRows.length * boardSize +
        clearedCols.length * boardSize -
        clearedRows.length * clearedCols.length;
  }
}
