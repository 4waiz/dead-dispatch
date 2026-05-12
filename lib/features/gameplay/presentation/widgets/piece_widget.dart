import 'package:flutter/material.dart';

import '../../../../presentation/theme/colors.dart';
import '../../game/board/piece.dart';

/// Renders a polyomino [piece] at a fixed [cellSize]. Used both inside
/// the tray (visible piece preview) and as the drag feedback / drop
/// preview on the board. Stateless and cheap to rebuild.
class PieceWidget extends StatelessWidget {
  const PieceWidget({
    required this.piece,
    required this.cellSize,
    this.opacity = 1.0,
    this.dim = false,
    super.key,
  });

  final Piece piece;
  final double cellSize;
  final double opacity;

  /// When true (e.g. piece can't fit anywhere), render desaturated.
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final color = dim
        ? AppColors.outline
        : AppColors.forBlock(piece.type);
    return SizedBox(
      width: piece.cols * cellSize,
      height: piece.rows * cellSize,
      child: Stack(
        children: [
          for (final cell in piece.cells)
            Positioned(
              left: cell.col * cellSize,
              top: cell.row * cellSize,
              width: cellSize,
              height: cellSize,
              child: _GhostMailCell(color: color, opacity: opacity),
            ),
        ],
      ),
    );
  }
}

class _GhostMailCell extends StatelessWidget {
  const _GhostMailCell({required this.color, required this.opacity});
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: opacity),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.18 * opacity),
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35 * opacity),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        // Subtle inner highlight to give the cell some dimension.
        child: Container(
          margin: const EdgeInsets.fromLTRB(3, 3, 3, 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: 0.22 * opacity),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
