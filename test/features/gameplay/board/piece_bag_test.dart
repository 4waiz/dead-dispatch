import 'package:dead_dispatch/domain/models/block_type.dart';
import 'package:dead_dispatch/features/gameplay/game/board/piece.dart';
import 'package:dead_dispatch/features/gameplay/game/board/piece_bag.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PieceBag', () {
    test('same seed + same allowedTypes produces an identical sequence', () {
      final a = PieceBag(
        seed: 4242,
        allowedTypes: const [BlockType.standard, BlockType.priority],
      );
      final b = PieceBag(
        seed: 4242,
        allowedTypes: const [BlockType.standard, BlockType.priority],
      );
      final aSeq = a.nextN(20);
      final bSeq = b.nextN(20);
      for (var i = 0; i < 20; i++) {
        expect(
          aSeq[i].shapeKey,
          bSeq[i].shapeKey,
          reason: 'shape at index $i diverged',
        );
        expect(
          aSeq[i].type,
          bSeq[i].type,
          reason: 'type at index $i diverged',
        );
      }
    });

    test('different seeds diverge within the first triple', () {
      final a = PieceBag(
        seed: 1,
        allowedTypes: const [BlockType.standard, BlockType.priority],
      );
      final b = PieceBag(
        seed: 2,
        allowedTypes: const [BlockType.standard, BlockType.priority],
      );
      // Compare 5 pieces; at least one should differ in shape OR type.
      final aSeq = a.nextN(5);
      final bSeq = b.nextN(5);
      var diverged = false;
      for (var i = 0; i < 5; i++) {
        if (aSeq[i].shapeKey != bSeq[i].shapeKey ||
            aSeq[i].type != bSeq[i].type) {
          diverged = true;
          break;
        }
      }
      expect(diverged, isTrue);
    });

    test('respects allowedTypes — every drawn piece uses one of them', () {
      const allowed = [BlockType.standard, BlockType.frozen];
      final bag = PieceBag(seed: 7, allowedTypes: allowed);
      final pieces = bag.nextN(50);
      for (final p in pieces) {
        expect(allowed, contains(p.type));
      }
    });

    test('assigns unique sequential ids', () {
      final bag = PieceBag(
        seed: 999,
        allowedTypes: const [BlockType.standard],
        startingId: 10,
      );
      final pieces = bag.nextN(5);
      expect(pieces.map((p) => p.id).toList(), [10, 11, 12, 13, 14]);
    });

    test('throws when allowedTypes is empty', () {
      expect(
        () => PieceBag(seed: 1, allowedTypes: const <BlockType>[]),
        throwsArgumentError,
      );
    });

    test('every drawn piece is geometrically valid (cells fit in bbox)', () {
      final bag = PieceBag(
        seed: 31337,
        allowedTypes: const [BlockType.standard],
      );
      for (var i = 0; i < 30; i++) {
        final p = bag.next();
        expect(p.cells, isNotEmpty);
        for (final PieceCell cell in p.cells) {
          expect(cell.row, inInclusiveRange(0, p.rows - 1));
          expect(cell.col, inInclusiveRange(0, p.cols - 1));
        }
      }
    });
  });
}
