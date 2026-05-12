# Dead Dispatch

A cozy haunted-mailroom **block puzzle** for mobile. You drag colorful ghost-mail pieces onto an 8×8 desk, fill rows and columns to make them clear with a wax-stamp burst, chain combos for bigger payouts, and spend the coins restoring a haunted post office. No timer in Classic Shift. The Daily Seal challenges everyone with the same board on the same day.

Built with **Flutter + Flame**.

---

## The game in one minute

- **Drag-and-drop.** Three ghost-mail pieces sit in a tray at the bottom of the screen. Drag any one onto the 8×8 desk. Cells under the piece glow cyan when the placement is valid, red when it isn't.
- **Clear lines.** Fill a complete row or column to clear it — the cells burst gold with a "DISPATCHED!" stamp, score and coins go up.
- **Combos.** Every placement that clears at least one line increments your combo. The combo multiplier scales up to **3.0×** (configurable in `balance.json`). A non-clearing placement resets the combo to zero.
- **Game over** when none of the three pieces in your tray can fit anywhere on the board. There is no shift timer in Classic mode — you play as long as you can survive.
- **Bag rules.** Each piece is a polyomino: single, 2-line, 3-line, 2×2 square, L-shapes (4 orientations), T-shape, zigzag, or a 5-block chunky shape. The bag is weighted toward easier shapes early on so the opening of every shift is forgiving.
- **Block types.** Eight cosmetic mail flavors — Standard cream, Priority orange, Frozen blue, Cursed purple, Vault gold, Fragile glassy, Void deep-purple, Ghost cyan. Each type has its own colour but the placement and clear rules are uniform.
- **Power-ups.** Stamp Blast clears a 3×3 area where you tap. Ghost Swap re-rolls all three pieces in the tray. (Return Sender and Lantern Sweep are wired but disabled for v1.)
- **Daily Seal.** Today's date hashes to a deterministic seed — every player gets the same starting board, same piece sequence, and one of 5 daily modifiers:
  - **Frozen Floor** — 4 cells pre-frosted on the starting board.
  - **Priority Rush** — orange Priority pieces pay double coins.
  - **Void Spots** — 2 cells start blocked; clear lines through them to free them.
  - **Golden Mail** — gold Vault pieces pay double coins.
  - **Fragile Batch** — (deferred to v1.1)
- **Meta-progression.** Coins fund persistent upgrades (Steady Hand, Ink Reserves, Forgiving Foreman, Union Negotiation, etc.) and **department restoration** — restore haunted rooms to unlock new block types, board skins, and power-ups.

---

## Technical overview

### Stack

| Concern | Tool |
|---|---|
| App framework | Flutter (Dart ≥ 3.4, Flutter ≥ 3.22) |
| Game engine | Flame ^1.18 (kept for future polish; gameplay itself is Flutter widgets) |
| State / DI | `flutter_riverpod` ^2.5 |
| Routing | `go_router` ^14.2 |
| Persistence | `shared_preferences` ^2.2 |
| Determinism | `clock` + bespoke `SeededRandom` (xorshift32) + `DailySeed` (FNV-1a) |
| Targets | Android, iOS, Web, Windows, macOS, Linux |

### Layered architecture

Strict inward-only dependencies. The domain layer is framework-free — no Flutter, no Flame imports — so scoring, placement, daily-seed, and economy logic is unit-testable in milliseconds.

```
presentation/  Flutter widgets, theme               ← features/*/presentation
features/gameplay/game/
  board/       Board, Piece, PieceBag,              pure-Dart puzzle core
               PlacementService                     (no Flutter, no Flame)
  session/     PuzzleSession, PuzzleState,
               PuzzleEvent (sealed)
  presentation/widgets/                              the Flutter UI for one shift
services/      Platform adapters
data/          Repositories, local storage,
               config loader, save migrations
domain/        Models + services (framework-free)
core/          Logger, env, failures, perf, RNG,
               clock, debug flags
```

DI lives in [lib/di/providers.dart](lib/di/providers.dart). All async "must succeed" init (storage open, balance JSON load, profile load) runs in [lib/app/bootstrap.dart](lib/app/bootstrap.dart) and overrides the throwing default providers before `runApp`.

### Code map

```
lib/
├── main.dart                                ← bootstrap()
├── app/                                     ← bootstrap, MaterialApp, theme, router, flavors
├── core/                                    ← perf, rng, time, logger, env, failures, constants
├── domain/                                  ← pure Dart
│   ├── balance/                             ← BalanceData (blocks + economy + shifts)
│   ├── models/                              ← BlockType, Piece records via package.dart,
│   │                                          ShiftConfig, ShiftResult, PlayerProfile,
│   │                                          Wallet, OwnedUpgrade, Department, Hazard
│   └── services/                            ← ScoreService, DifficultyService,
│                                              EconomyService, ProgressionService,
│                                              SeededRandom, DailySeed
├── data/                                    ← SaveRepository, ProgressionRepository,
│                                              SettingsRepository, DailyRepository,
│                                              ConfigLoader, SaveMigrator
├── services/                                ← AdsService, AudioService, HapticsService,
│                                              AnalyticsService, RemoteConfigService
├── di/providers.dart                        ← Riverpod composition root
├── presentation/                            ← shared theme, widgets, gameplay_copy
└── features/
    ├── splash/, menu/, tutorial/, shift_brief/, shift_result/,
    ├── upgrades/, meta/ (departments), daily_challenge/, settings/, debug/
    └── gameplay/
        ├── presentation/
        │   ├── game_screen.dart             ← composes board + tray + HUD
        │   └── widgets/
        │       ├── board_widget.dart        ← 8×8 grid + DragTarget
        │       ├── piece_widget.dart        ← polyomino renderer
        │       ├── piece_tray_widget.dart   ← 3-slot Draggable dock
        │       ├── clear_burst_overlay.dart ← "DISPATCHED!" stamp burst
        │       └── power_up_dock.dart       ← Stamp Blast + Ghost Swap
        └── game/
            ├── board/
            │   ├── board.dart               ← immutable grid + clear-lines logic
            │   ├── piece.dart               ← polyomino + cell offsets
            │   ├── piece_library.dart       ← 13 canonical shapes + weights
            │   ├── piece_bag.dart           ← deterministic generator
            │   └── placement_service.dart   ← pure place + clear facade
            └── session/
                ├── puzzle_session.dart      ← shift orchestrator
                ├── puzzle_state.dart        ← immutable snapshot
                └── puzzle_events.dart       ← sealed event hierarchy
```

### Runtime data flow — one shift

```
User taps "Play Shift" or "Daily Seal"
   │
   ▼
GameScreen.initState():
   ├─ DifficultyService.buildClassic(profile)        (or buildDaily for the Daily Seal)
   ├─ new PuzzleSession(config, balance, profile)
   │     ├─ Board.empty(8) + daily-modifier pre-fills
   │     ├─ PieceBag(seed, allowedTypes).nextN(3)    initial queue
   │     └─ ScoreService(balance)
   └─ session.start() → emits QueueRefilledEvent
   │
   ▼
Player drags a piece (Draggable<Piece>):
   ├─ onDragStarted → session.onPiecePickedUp(piece) → PiecePickedUpEvent
   │                  (paper-flick SFX, selection haptic)
   ├─ BoardWidget.onMove → live valid/invalid cyan/red preview
   └─ onAcceptWithDetails → session.tryPlace(pieceId, anchorRow, anchorCol)
   │
   ▼
PuzzleSession.tryPlace:
   1. PlacementService.tryPlace(board, piece, anchor) → PlacementOutcome (or null)
   2. If null → InvalidDropEvent (dull-thud SFX, failure haptic)
   3. Else:
        ScoreService.registerPlacement(type, cellsPlaced, linesCleared, boardCleared)
           ├─ per-cell base score for the placement
           ├─ + clearLineBonus × linesCleared
           ├─ + multiClearBonusPerExtraLine × (linesCleared − 1)
           ├─ + perfectBonus if any clear
           ├─ + perfectClearBonus if board empty after clear
           └─ scaled by comboMultiplier (1 + combo × step, capped)
        Apply daily-modifier coin multiplier (Golden Mail / Priority Rush)
        Drop the piece from the queue; if queue empty, PieceBag.nextN refills it.
   4. Emit: PiecePlacedEvent, LinesClearedEvent (if any),
            ComboChangedEvent (on change), BoardClearedEvent (if any),
            ShiftTargetReachedEvent (first crossing), QueueRefilledEvent (on refill).
   5. PlacementService.isGameOver(board, queue) → GameOverEvent + ShiftResult
   │
   ▼
GameOverEvent → context.pushReplacement('/result', ShiftResult)
ShiftResultScreen → ProgressionService.recordShift + EconomyService.payoutForShift,
                    optional rewarded ad for doubled coins, SaveRepository.save.
```

### Key design decisions

1. **Domain is framework-free.** Scoring, placement, line-clear, daily-seed, and economy live under `lib/domain/` and `lib/features/gameplay/game/{board,session}/`. Zero Flutter imports. All testable in pure Dart.
2. **Balancing is data, not code.** Every tunable lives in `assets/config/*.json` (`balance.json`, `packages.json` (block descriptors), `hazards.json` (daily modifiers), `upgrades.json`, `departments.json`, `shifts.json`). `BalanceProvider` assembles a single immutable `BalanceData` at boot.
3. **Deterministic Daily Seal.** `DailySeed.seedFor(YYYY-MM-DD)` is FNV-1a over the date string. That seed feeds a `SeededRandom` (xorshift32) used by both the daily-modifier roll and the `PieceBag`. Same date → same starting board, same piece sequence, on every device.
4. **Sealed events.** `PuzzleSession` exposes a `Stream<PuzzleEvent>` of 10 typed events. The HUD listens for visual updates; an audio/haptics adapter listens for SFX cues. Logic and presentation stay decoupled.
5. **Service abstractions everywhere platform-shaped.** `AdsService`, `AnalyticsService`, `AudioService`, `HapticsService`, `RemoteConfigService` each have an interface + an offline stub. Release flavors swap in real SDKs via [lib/app/flavors.dart](lib/app/flavors.dart).
6. **Versioned save migrations.** `AppConstants.saveSchemaVersion` is currently `2`. The `v1 → v2` migration renames conveyor-era upgrade kinds (`beltSpeedTolerance` → `bagSoftness`, etc.) so any pre-pivot saves still load.
7. **Power-ups are state-machine friendly.** Stamp Blast clears a 3×3 area and re-checks game over (a blast can save the player); Ghost Swap re-rolls the queue and re-checks game over too. Both consume a charge.

### Configs at a glance

[assets/config/balance.json](assets/config/balance.json) — the file you'll edit most.

```jsonc
{
  "shifts": {
    "gridSize": 8,
    "pieceQueueSize": 3,
    "classicNoTimer": true,
    "dailyDurationMs": null,
    "baseTargetScore": 1200,
    "targetScoreGrowth": 1.12,
    "unlockOrder": ["standard","priority","frozen","cursed","vault","fragile","void","ghost"]
  },
  "economy": {
    "coinPerScorePoint": 0.10,
    "perfectBonus": 25,
    "comboMultiplierStep": 0.05,
    "comboMultiplierCap": 3.0,
    "dailyCompletionBonus": 150,
    "failureForgivenessRefund": 0.5,
    "mysteryParcelMin": 50,
    "mysteryParcelMax": 250,
    "clearLineBonus": 60,
    "multiClearBonusPerExtraLine": 90,
    "perfectClearBonus": 400
  }
}
```

JSON edits are hot-reloadable in dev — `flutter run`, save the file, hot-restart. For more guidance see [docs/BALANCING.md](docs/BALANCING.md) and [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) (note: both still describe the pre-pivot routing game; they will be refreshed in a follow-up pass).

### Testing

| Concern | Test file |
|---|---|
| Seeded RNG determinism | [test/domain/seeded_random_test.dart](test/domain/seeded_random_test.dart) |
| Daily-seed stability | [test/domain/daily_seed_test.dart](test/domain/daily_seed_test.dart) |
| Score + combo math | [test/domain/score_service_test.dart](test/domain/score_service_test.dart) |
| Economy: purchases, mystery roll, payouts | [test/domain/economy_service_test.dart](test/domain/economy_service_test.dart) |
| Difficulty curve + Daily Seal determinism | [test/domain/difficulty_service_test.dart](test/domain/difficulty_service_test.dart) |
| Progression / department gating | [test/domain/progression_service_test.dart](test/domain/progression_service_test.dart) |
| Model JSON round-trip + legacy kind migration | [test/domain/models_serialization_test.dart](test/domain/models_serialization_test.dart) |
| Save migration v0→v1, v1→v2 | [test/data/save_migrator_test.dart](test/data/save_migrator_test.dart) |
| Board: place, immutability, clear, game over | [test/features/gameplay/board/board_test.dart](test/features/gameplay/board/board_test.dart) |
| Placement service: valid/invalid/edge | [test/features/gameplay/board/placement_service_test.dart](test/features/gameplay/board/placement_service_test.dart) |
| Piece bag determinism + weighting | [test/features/gameplay/board/piece_bag_test.dart](test/features/gameplay/board/piece_bag_test.dart) |
| Puzzle session orchestration + events | [test/features/gameplay/session/puzzle_session_test.dart](test/features/gameplay/session/puzzle_session_test.dart) |

77 tests at last check; `flutter test` should be green end-to-end.

---

## Running the game

```powershell
flutter pub get
flutter analyze            # must be 0 errors
flutter test               # must be green
flutter run -d windows     # or -d chrome, -d <android-device-id>
flutter build apk --release   # verify no Debug tile on the menu
```

### Manual smoke test
1. Splash → Main Menu (or Tutorial on first launch).
2. Main Menu: title, coin balance, **Play Shift** primary CTA, **Daily Seal** secondary CTA, Restore Office card, Upgrades / Departments / Settings tiles.
3. Tap **Play Shift** → Brief screen → tap **PLAY SHIFT**.
4. Game screen renders an 8×8 board, 3 colourful ghost-mail pieces in the tray, HUD (score / best / combo / coins / pause).
5. Drag a piece — cells glow cyan when valid, red when not. Drop on valid cells → soft-tap SFX, gentle haptic.
6. Complete a row or column → gold "DISPATCHED!" burst, score and coins update, combo ticks up.
7. Place all 3 pieces → tray auto-refills.
8. Use **Ghost Swap** (bottom dock) → tray re-rolls. **Stamp Blast** → arm, then tap the board to clear a 3×3.
9. Game over when no piece fits → result screen with Score / Best / Lines cleared / Biggest combo / Coins, Play Again + Restore Office + Back-to-menu buttons.
10. **Daily Seal**: two launches with the same date → identical initial board and piece sequence (determinism check). Today's modifier is shown on the daily entry screen and the brief.
11. Settings: haptics off → invalid drop doesn't vibrate.
12. Restart app → coins, best score, restored departments, upgrades persist; save migrates cleanly.
13. Release build (`flutter build apk --release`) → no Debug tile on the menu.

---

## Status

Block-puzzle pivot complete: Classic Shift + Daily Seal end-to-end, full menu chain, persistence, deterministic dailies, Stamp Blast + Ghost Swap. Real AdMob / Firebase / final art + audio are flavor-gated TODOs at [lib/di/providers.dart](lib/di/providers.dart).
