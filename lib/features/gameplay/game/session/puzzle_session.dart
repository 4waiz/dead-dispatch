import 'dart:async';

import '../../../../domain/balance/balance_data.dart';
import '../../../../domain/models/block_type.dart';
import '../../../../domain/models/hazard.dart';
import '../../../../domain/models/player_profile.dart';
import '../../../../domain/models/shift_config.dart';
import '../../../../domain/models/shift_result.dart';
import '../../../../domain/models/upgrade.dart';
import '../../../../domain/services/score_service.dart';
import '../../../../domain/services/seeded_random.dart';
import '../board/board.dart';
import '../board/piece.dart';
import '../board/piece_bag.dart';
import '../board/placement_service.dart';
import 'puzzle_events.dart';
import 'puzzle_state.dart';

/// Orchestrates one block-puzzle shift: owns the [Board], [PieceBag],
/// [ScoreService], and emits a typed [PuzzleEvent] stream consumed by
/// the HUD and the audio/haptics adapter.
///
/// The session is pure logic — no Flutter widgets, no `BuildContext`. UI
/// integrates by listening to [events] and calling [tryPlace] /
/// [useStampBlast] / [useGhostSwap] in response to user input.
class PuzzleSession {
  PuzzleSession({
    required ShiftConfig config,
    required BalanceData balance,
    required PlayerProfile profile,
    PlacementService placement = const PlacementService(),
    PieceBag? bag,
  })  : _config = config,
        _placement = placement,
        _score = ScoreService(balance),
        _bag = bag ??
            PieceBag(
              seed: config.seed,
              allowedTypes: config.allowedTypes,
            ) {
    final initialBoard = _applyDailyModifier(
      Board.empty(config.gridSize),
      config.dailyModifier,
    );
    final queue = _bag.nextN(config.pieceQueueSize);
    final stampCharges = profile.upgradeLevel(UpgradeKind.stampBlastCharges);
    _state = PuzzleState(
      board: initialBoard,
      queue: queue,
      score: 0,
      combo: 0,
      coins: 0,
      piecesPlaced: 0,
      linesCleared: 0,
      dailyModifier: config.dailyModifier,
      stampBlastCharges: stampCharges,
      ghostSwapCharges: 1,
      ended: false,
      completed: false,
    );
  }

  final ShiftConfig _config;
  final PlacementService _placement;
  final ScoreService _score;
  final PieceBag _bag;

  final _controller = StreamController<PuzzleEvent>.broadcast();
  late PuzzleState _state;
  bool _started = false;

  Stream<PuzzleEvent> get events => _controller.stream;
  PuzzleState get state => _state;
  ShiftConfig get config => _config;
  ScoreService get scoreService => _score;

  /// Look up a piece in the current queue by id. Returns null if the
  /// player drops a piece that no longer exists (e.g. after Ghost Swap).
  Piece? pieceById(int id) {
    for (final p in _state.queue) {
      if (p.id == id) return p;
    }
    return null;
  }

  void start() {
    if (_started || _state.ended) return;
    _started = true;
    _controller.add(QueueRefilledEvent(_state.queue));
  }

  /// HUD calls this when the player starts dragging a piece (before
  /// drop). Drives haptic + paper-flick SFX.
  void onPiecePickedUp(Piece piece) {
    if (_state.ended) return;
    _controller.add(PiecePickedUpEvent(piece));
  }

  /// Try to place `piece` (by id) with its top-left cell anchored at
  /// (row, col). Returns true on success.
  bool tryPlace({
    required int pieceId,
    required int anchorRow,
    required int anchorCol,
  }) {
    if (_state.ended) return false;
    final piece = pieceById(pieceId);
    if (piece == null) return false;

    final outcome = _placement.tryPlace(
      board: _state.board,
      piece: piece,
      anchorRow: anchorRow,
      anchorCol: anchorCol,
    );
    if (outcome == null) {
      _controller.add(
        InvalidDropEvent(
          piece: piece,
          anchorRow: anchorRow,
          anchorCol: anchorCol,
        ),
      );
      return false;
    }

    final prevCombo = _score.combo;
    final record = _score.registerPlacement(
      pieceId: piece.id,
      type: piece.type,
      cellsPlaced: piece.cellCount,
      linesCleared: outcome.linesCleared,
      boardCleared: outcome.boardCleared,
    );

    // Apply daily-modifier coin multiplier (e.g. Golden Mail doubles
    // coins on Vault pieces, Priority Rush doubles coins on Priority).
    final coinMul = _coinMultiplierFor(piece.type);
    final coinDelta = (record.coinDelta * coinMul).round();

    final newQueue = _state.queue.where((p) => p.id != piece.id).toList();
    final refilled = newQueue.isEmpty
        ? _bag.nextN(_config.pieceQueueSize)
        : newQueue;

    _state = _state.copyWith(
      board: outcome.newBoard,
      queue: refilled,
      score: _score.score,
      combo: _score.combo,
      coins: _state.coins + coinDelta,
      piecesPlaced: _state.piecesPlaced + 1,
      linesCleared: _state.linesCleared + outcome.linesCleared,
      completed: _state.completed || _score.score >= _config.targetScore,
    );

    _controller.add(
      PiecePlacedEvent(
        piece: piece,
        anchorRow: anchorRow,
        anchorCol: anchorCol,
        linesCleared: outcome.linesCleared,
        scoreDelta: record.scoreDelta,
        coinDelta: coinDelta,
      ),
    );
    if (outcome.linesCleared > 0) {
      _controller.add(
        LinesClearedEvent(
          rows: outcome.clearedRows,
          cols: outcome.clearedCols,
        ),
      );
    }
    if (_score.combo != prevCombo) {
      _controller.add(
        ComboChangedEvent(
          combo: _score.combo,
          multiplier: _score.comboMultiplier,
        ),
      );
    }
    if (outcome.boardCleared) {
      _controller.add(const BoardClearedEvent());
    }
    if (!_wasTargetReached(before: _state.score - record.scoreDelta) &&
        _state.score >= _config.targetScore) {
      _controller.add(ShiftTargetReachedEvent(_state.score));
    }
    if (newQueue.isEmpty) {
      _controller.add(QueueRefilledEvent(refilled));
    }

    if (_placement.isGameOver(_state.board, _state.queue)) {
      _endGame();
    }
    return true;
  }

  bool _wasTargetReached({required int before}) =>
      before >= _config.targetScore;

  /// Power-up: clear a 3×3 area centred on (row, col). Consumes one
  /// charge. Returns true on success.
  bool useStampBlast({required int row, required int col}) {
    if (_state.ended) return false;
    if (_state.stampBlastCharges <= 0) return false;
    final clearedCells = <List<int>>[];
    final flat = _state.board.cells.toList();
    final size = _state.board.size;
    for (var dr = -1; dr <= 1; dr++) {
      for (var dc = -1; dc <= 1; dc++) {
        final r = row + dr;
        final c = col + dc;
        if (r < 0 || c < 0 || r >= size || c >= size) continue;
        if (flat[r * size + c] != null) {
          flat[r * size + c] = null;
          clearedCells.add([r, c]);
        }
      }
    }
    if (clearedCells.isEmpty) return false;
    final newBoard = _rebuildBoard(size, flat);
    _state = _state.copyWith(
      board: newBoard,
      stampBlastCharges: _state.stampBlastCharges - 1,
    );
    _controller.add(const PowerUpUsedEvent(PowerUpId.stampBlast));
    // After a blast the tray may now fit again — re-check game over.
    if (_placement.isGameOver(_state.board, _state.queue)) {
      _endGame();
    }
    return true;
  }

  /// Power-up: re-roll all pieces currently in the queue. Consumes one
  /// charge.
  bool useGhostSwap() {
    if (_state.ended) return false;
    if (_state.ghostSwapCharges <= 0) return false;
    final newQueue = _bag.nextN(_config.pieceQueueSize);
    _state = _state.copyWith(
      queue: newQueue,
      ghostSwapCharges: _state.ghostSwapCharges - 1,
    );
    _controller.add(const PowerUpUsedEvent(PowerUpId.ghostSwap));
    _controller.add(QueueRefilledEvent(newQueue));
    // Re-roll may help or doom — re-check game over.
    if (_placement.isGameOver(_state.board, _state.queue)) {
      _endGame();
    }
    return true;
  }

  void _endGame() {
    if (_state.ended) return;
    _state = _state.copyWith(ended: true);
    final result = ShiftResult(
      shiftId: _config.id,
      score: _score.score,
      combo: _score.combo,
      maxCombo: _score.maxCombo,
      coins: _state.coins,
      records: _score.records.toList(),
      completed: _state.completed,
      failureReason: _state.completed ? null : 'no-fit',
      duration: Duration.zero,
    );
    _controller.add(GameOverEvent(result));
  }

  void dispose() {
    _controller.close();
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  /// Pre-fill cells when a daily modifier mandates a special starting
  /// board.
  ///   • Frozen Floor → 4 pre-frosted (Frozen-typed) cells.
  ///   • Void Spots   → 2 pre-blocked (Void-typed) cells.
  /// Other modifiers don't touch the board.
  Board _applyDailyModifier(Board board, HazardKind? modifier) {
    if (modifier == null) return board;
    final rng = SeededRandom(_config.seed ^ 0x5EED);
    switch (modifier) {
      case HazardKind.frozenFloor:
        return _seedRandomCells(board, BlockType.frozen, 4, rng);
      case HazardKind.voidSpots:
        return _seedRandomCells(board, BlockType.voidMail, 2, rng);
      case HazardKind.priorityRush:
      case HazardKind.goldenMail:
      case HazardKind.fragileBatch:
        return board;
    }
  }

  /// Place `count` cells of `type` at distinct random positions on the
  /// board. If `count` exceeds the empty-cell budget the function
  /// silently stops.
  Board _seedRandomCells(
    Board board,
    BlockType type,
    int count,
    SeededRandom rng,
  ) {
    final size = board.size;
    final rows = List<List<BlockType?>>.generate(
      size,
      (r) => List<BlockType?>.generate(size, (c) => board.cellAt(r, c)),
    );
    final placed = <int>{};
    var attempts = 0;
    while (placed.length < count && attempts < count * 20) {
      attempts++;
      final idx = rng.nextIntRange(0, size * size);
      if (placed.contains(idx)) continue;
      final r = idx ~/ size;
      final c = idx % size;
      if (rows[r][c] != null) continue;
      rows[r][c] = type;
      placed.add(idx);
    }
    return Board.fromRows(rows);
  }

  /// Returns the coin multiplier the active daily modifier applies for
  /// the given block type. Default 1.0.
  double _coinMultiplierFor(BlockType type) {
    switch (_state.dailyModifier) {
      case HazardKind.goldenMail:
        return type == BlockType.vault ? 2.0 : 1.0;
      case HazardKind.priorityRush:
        return type == BlockType.priority ? 2.0 : 1.0;
      case HazardKind.frozenFloor:
      case HazardKind.voidSpots:
      case HazardKind.fragileBatch:
      case null:
        return 1.0;
    }
  }

  /// Reconstructs a board from a flat list. Wraps the package-private
  /// constructor by going through fromRows; cheap on small boards.
  Board _rebuildBoard(int size, List<BlockType?> flat) {
    final rows = List<List<BlockType?>>.generate(size, (r) {
      return List<BlockType?>.generate(size, (c) => flat[r * size + c]);
    });
    return Board.fromRows(rows);
  }

}
