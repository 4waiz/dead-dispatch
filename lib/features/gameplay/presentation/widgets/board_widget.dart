import 'package:flutter/material.dart';

import '../../../../domain/models/block_type.dart';
import '../../../../presentation/theme/colors.dart';
import '../../game/board/board.dart';
import '../../game/board/piece.dart';

/// Renders the puzzle board. Cells are flat decorations; drag-and-drop
/// is handled by a single board-spanning [DragTarget] that uses the
/// drop pointer position to compute the snap anchor for whichever
/// piece the player is dragging.
class BoardWidget extends StatefulWidget {
  const BoardWidget({
    required this.board,
    required this.cellSize,
    required this.onPlace,
    required this.onPieceHover,
    super.key,
  });

  final Board board;
  final double cellSize;

  /// Called when the player completes a drag over the board. Returns
  /// true if the placement was accepted (so the tray can clear the
  /// piece visually); false on invalid drop.
  final bool Function(Piece piece, int row, int col) onPlace;

  /// Streams the live hover-anchor while a piece is being dragged so
  /// the renderer can show a valid/invalid preview. Called with null
  /// when no piece is being dragged.
  final void Function(BoardHoverState? hover) onPieceHover;

  @override
  State<BoardWidget> createState() => _BoardWidgetState();
}

class _BoardWidgetState extends State<BoardWidget> {
  BoardHoverState? _hover;

  void _setHover(BoardHoverState? next) {
    if (_hover?.equals(next) ?? next == null) return;
    setState(() => _hover = next);
    widget.onPieceHover(next);
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.board.size;
    final boardPx = size * widget.cellSize;

    return SizedBox(
      width: boardPx,
      height: boardPx,
      child: DragTarget<Piece>(
        // Always accept; we use the live position to decide highlight.
        onWillAcceptWithDetails: (_) => true,
        onMove: (details) {
          final local = _localOffset(details.offset, context);
          if (local == null) {
            _setHover(null);
            return;
          }
          final anchor = _anchorFor(details.data, local);
          final valid =
              widget.board.canPlace(details.data, anchor.row, anchor.col);
          _setHover(
            BoardHoverState(
              piece: details.data,
              row: anchor.row,
              col: anchor.col,
              valid: valid,
            ),
          );
        },
        onLeave: (_) => _setHover(null),
        onAcceptWithDetails: (details) {
          final local = _localOffset(details.offset, context);
          if (local == null) {
            _setHover(null);
            return;
          }
          final anchor = _anchorFor(details.data, local);
          widget.onPlace(details.data, anchor.row, anchor.col);
          _setHover(null);
        },
        builder: (context, candidate, rejected) {
          return _BoardBackground(
            board: widget.board,
            cellSize: widget.cellSize,
            hover: _hover,
          );
        },
      ),
    );
  }

  /// Convert a global drag-feedback offset to a board-local offset in
  /// pixels. Returns null if the pointer is outside the board.
  Offset? _localOffset(Offset globalOffset, BuildContext context) {
    final box = context.findRenderObject();
    if (box is! RenderBox) return null;
    final local = box.globalToLocal(globalOffset);
    final size = widget.board.size * widget.cellSize;
    if (local.dx < 0 || local.dy < 0 || local.dx >= size || local.dy >= size) {
      return null;
    }
    return local;
  }

  /// Anchor the piece so the pointer hits the top-left of the piece's
  /// bounding box. Clamps so the piece never overflows the board (the
  /// final canPlace check still rejects invalid placements).
  _Anchor _anchorFor(Piece piece, Offset local) {
    final cellSize = widget.cellSize;
    final size = widget.board.size;
    var row = (local.dy / cellSize).floor();
    var col = (local.dx / cellSize).floor();
    if (row + piece.rows > size) row = size - piece.rows;
    if (col + piece.cols > size) col = size - piece.cols;
    if (row < 0) row = 0;
    if (col < 0) col = 0;
    return _Anchor(row, col);
  }
}

class _Anchor {
  const _Anchor(this.row, this.col);
  final int row;
  final int col;
}

class BoardHoverState {
  const BoardHoverState({
    required this.piece,
    required this.row,
    required this.col,
    required this.valid,
  });
  final Piece piece;
  final int row;
  final int col;
  final bool valid;

  bool equals(BoardHoverState? other) =>
      other != null &&
      other.piece.id == piece.id &&
      other.row == row &&
      other.col == col &&
      other.valid == valid;
}

class _BoardBackground extends StatelessWidget {
  const _BoardBackground({
    required this.board,
    required this.cellSize,
    required this.hover,
  });

  final Board board;
  final double cellSize;
  final BoardHoverState? hover;

  @override
  Widget build(BuildContext context) {
    final size = board.size;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.boardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.7)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 22,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Stack(
          children: [
            // Base cells (always rendered).
            for (var r = 0; r < size; r++)
              for (var c = 0; c < size; c++)
                Positioned(
                  left: c * cellSize,
                  top: r * cellSize,
                  width: cellSize,
                  height: cellSize,
                  child: _Cell(
                    type: board.cellAt(r, c),
                    cellSize: cellSize,
                  ),
                ),
            // Hover preview overlay (valid → cyan glow, invalid → red).
            if (hover != null)
              for (final cell in hover!.piece.cells)
                Positioned(
                  left: (hover!.col + cell.col) * cellSize,
                  top: (hover!.row + cell.row) * cellSize,
                  width: cellSize,
                  height: cellSize,
                  child: IgnorePointer(
                    child: _HoverPreview(valid: hover!.valid),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.type, required this.cellSize});
  final BlockType? type;
  final double cellSize;

  @override
  Widget build(BuildContext context) {
    final filled = type != null;
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Container(
        decoration: BoxDecoration(
          color: filled
              ? AppColors.forBlock(type!)
              : AppColors.cellEmpty,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: filled
                ? Colors.white.withValues(alpha: 0.2)
                : AppColors.outline.withValues(alpha: 0.5),
          ),
          boxShadow: filled
              ? [
                  BoxShadow(
                    color: AppColors.forBlock(type!)
                        .withValues(alpha: 0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        // Soft inner highlight for filled cells.
        child: filled
            ? Container(
                margin: const EdgeInsets.fromLTRB(3, 3, 3, 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.22),
                      Colors.transparent,
                    ],
                  ),
                ),
              )
            : null,
      ),
    );
  }
}

class _HoverPreview extends StatelessWidget {
  const _HoverPreview({required this.valid});
  final bool valid;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Container(
        decoration: BoxDecoration(
          color: valid ? AppColors.cellValidPreview : AppColors.cellInvalid,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: valid
                ? AppColors.accentGhost.withValues(alpha: 0.8)
                : AppColors.accentDanger.withValues(alpha: 0.8),
            width: 1.4,
          ),
        ),
      ),
    );
  }
}
