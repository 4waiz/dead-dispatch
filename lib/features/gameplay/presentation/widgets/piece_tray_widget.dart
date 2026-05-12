import 'package:flutter/material.dart';

import '../../../../presentation/theme/colors.dart';
import '../../game/board/piece.dart';
import 'piece_widget.dart';

/// Bottom dock showing the 3 pieces the player can drag onto the board.
/// Pieces that can't fit anywhere are dimmed (game-over preview) but
/// still draggable so the player can confirm the impossibility.
class PieceTrayWidget extends StatelessWidget {
  const PieceTrayWidget({
    required this.pieces,
    required this.cellSize,
    required this.canFit,
    required this.onPickUp,
    super.key,
  });

  final List<Piece> pieces;
  final double cellSize;

  /// Returns true if `piece` can fit somewhere on the current board.
  /// Used purely for cosmetic dimming.
  final bool Function(Piece piece) canFit;

  /// Fired when the player begins dragging a piece (for SFX + haptics).
  final void Function(Piece piece) onPickUp;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: pieces
            .map(
              (p) => _TraySlot(
                piece: p,
                cellSize: cellSize,
                dim: !canFit(p),
                onPickUp: onPickUp,
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _TraySlot extends StatelessWidget {
  const _TraySlot({
    required this.piece,
    required this.cellSize,
    required this.dim,
    required this.onPickUp,
  });

  final Piece piece;
  final double cellSize;
  final bool dim;
  final void Function(Piece piece) onPickUp;

  @override
  Widget build(BuildContext context) {
    // Tray cells are slightly smaller than board cells so big pieces fit.
    final preview = PieceWidget(piece: piece, cellSize: cellSize, dim: dim);
    // While dragging, render the piece at full board-cell size so the
    // drop preview lines up with the board grid.
    final dragFeedback = Material(
      type: MaterialType.transparency,
      child: PieceWidget(piece: piece, cellSize: cellSize * 1.5),
    );

    return Draggable<Piece>(
      data: piece,
      maxSimultaneousDrags: dim ? 1 : 1,
      feedback: dragFeedback,
      childWhenDragging: Opacity(opacity: 0.25, child: preview),
      onDragStarted: () => onPickUp(piece),
      child: preview,
    );
  }
}
