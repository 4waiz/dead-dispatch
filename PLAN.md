# Dead Dispatch — Implementation Plan (Scaffold → Playable v1)

## Context

Dead Dispatch is a Flutter + Flame hybrid-casual game (haunted postal sorting) currently at **v0.1.0 scaffold**. The domain layer, balancing JSON, repositories, screens, services, and DI are ~95% complete and tested. What's missing is the **Flame gameplay world** (belt, packages, hazards, input) and a few **compile-breaking bugs** in the wiring between `GameScreen` and `DeadDispatchGame`. This plan gets the app from "compiles-with-errors and has no belt" to **end-to-end playable shift → score → rewards → upgrades loop**.

Goal: a buildable, playable v1 that a human (or another AI) can ship to Android in one sitting.

---

## Phase 0 — Make It Compile (critical bugs, ~30 min)

These break `flutter analyze` / `flutter run` today.

### 0.1 GameScreen ↔ DeadDispatchGame constructor mismatch
- [lib/features/gameplay/presentation/game_screen.dart:54-61](lib/features/gameplay/presentation/game_screen.dart#L54-L61) passes `balance`, `session`, `audio`, `haptics`, `perf`.
- [lib/features/gameplay/game/dead_dispatch_game.dart:23-28](lib/features/gameplay/game/dead_dispatch_game.dart#L23-L28) only accepts `config`, `perf`, `onRequestEnd`, `onFirstFrame`.
- **Fix:** expand `DeadDispatchGame` constructor to accept `session`, `balance`, `audio`, `haptics` (needed anyway for Phase 1). Store them as fields so systems can read them.

### 0.2 Missing game-event types
- [lib/features/gameplay/presentation/game_screen.dart:76-90](lib/features/gameplay/presentation/game_screen.dart#L76-L90) pattern-matches on `ComboChangedEvent`, `PackageResolvedEvent`, `ShiftEndedEvent`, `PackageSpawnedEvent`, `HazardStartedEvent`, `HazardEndedEvent` — **none exist**.
- **Fix:** create them in new file `lib/features/gameplay/game/game_events.dart` (see 1.1).

### 0.3 Missing `GameSession` / `GameState` imports
- [lib/features/gameplay/presentation/game_screen.dart:10-11](lib/features/gameplay/presentation/game_screen.dart#L10-L11) imports `../game/game_session.dart` and `../game/game_state.dart` — neither exists.
- **Fix:** create them (see Phase 1).

### 0.4 Missing `scoreServiceProvider`
- [lib/di/providers.dart](lib/di/providers.dart) never defines it; `ScoreService` is only instantiated in tests.
- **Fix:** add `final scoreServiceProvider = Provider((ref) => ScoreService(balance: ref.watch(balanceDataProvider)));` — or construct it per-shift inside `GameSession` (preferred, since ScoreService is stateful per run).

### 0.5 `flutter create` the platform folders
No `android/`, `ios/`, or `web/` folders exist. Run once at repo root:
```bash
flutter create --org com.deaddispatch --project-name dead_dispatch --platforms=android,ios,web .
flutter pub get
```
Do **not** let `flutter create` overwrite `lib/main.dart` or `pubspec.yaml` — back them up first or use `--no-overwrite`.

---

## Phase 1 — Flame Gameplay World (core deliverable)

The domain doc at [docs/ARCHITECTURE.md:60-90](docs/ARCHITECTURE.md#L60-L90) already specifies the runtime contract. Build exactly that.

### 1.1 Session + events + state (pure Dart, no Flame)

New files under `lib/features/gameplay/game/`:

**`game_events.dart`** — sealed class hierarchy:
```dart
sealed class GameEvent { const GameEvent(); }
class PackageSpawnedEvent extends GameEvent { final GamePackage pkg; ... }
class PackageResolvedEvent extends GameEvent { final GamePackage pkg; final SortOutcome outcome; ... }
class ComboChangedEvent extends GameEvent { final int combo; final double multiplier; ... }
class HazardStartedEvent extends GameEvent { final HazardKind kind; ... }
class HazardEndedEvent extends GameEvent { final HazardKind kind; ... }
class ShiftEndedEvent extends GameEvent { final ShiftResult result; ... }
```

**`game_state.dart`** — plain data class:
```dart
class GameState {
  final Duration elapsed;
  final Duration remaining;
  final Set<HazardKind> activeHazards;
  final int stamps;               // priority stamps remaining (from ShiftConfig.stampBudget)
  final bool paused;
}
```

**`game_session.dart`** — orchestrator. Owns `ScoreService`, `SeededRandom`, a `StreamController<GameEvent>`, and the authoritative `GameState`. API:
```dart
class GameSession {
  GameSession({required ShiftConfig config, required BalanceData balance, required Clock clock});
  Stream<GameEvent> get events;
  GameState get state;
  ScoreService get score;
  void start();
  void pause();
  void resume();
  void tick(double dt);                      // called by Flame update()
  void submitRouting(GamePackage pkg, Lane lane);
  void consumeStamp();
  void dispose();
}
```
`tick()` advances elapsed time, fires `ShiftEndedEvent` when `remaining <= 0`, emits the `ShiftResult` built from `ScoreService.finalize()`.

### 1.2 Flame systems

New files under `lib/features/gameplay/game/systems/`. Per [docs/ARCHITECTURE.md:112-114](docs/ARCHITECTURE.md#L112-L114) these must be allocation-free hot paths.

- **`spawner_system.dart`** — reads `ShiftConfig.spawnInterval`, `allowedPackageTypes`, uses `SeededRandom` to pick a type, instantiates a `PackageComponent`, emits `PackageSpawnedEvent`.
- **`hazard_system.dart`** — weighted sampler over `ShiftConfig.allowedHazards` + `hazards.json` severity; respects `hazardWarning` upgrade (telegraph duration); emits `HazardStartedEvent` / `HazardEndedEvent`; mutates `GameState.activeHazards`.
- **`routing_system.dart`** — detects when a `PackageComponent` crosses belt-end or a lane gate, calls [lib/domain/services/routing_service.dart](lib/domain/services/routing_service.dart) `resolve()`, passes outcome to `session.score.registerOutcome(...)`, emits `PackageResolvedEvent`.
- **`feedback_system.dart`** — listens to `session.events`; for each outcome plays SFX via `AudioService`, fires haptic via `HapticsService`, triggers particle/shake components.

### 1.3 Flame components

New files under `lib/features/gameplay/game/components/`:

- **`belt_component.dart`** — scrolling conveyor texture (simple tiled `RectangleComponent` with UV scroll for v1).
- **`package_component.dart`** — `SpriteComponent` (or `RectangleComponent` with label for v1 if art not ready) carrying a `GamePackage`. Moves left-to-right at belt speed × hazard severity.
- **`lane_gate_component.dart`** — tappable button per department lane. On tap, calls `session.submitRouting(pkg, lane)` for the frontmost package.
- **`stamp_button_component.dart`** — consumes a priority stamp on tap.
- **`hazard_overlay_component.dart`** — blackout vignette, jam indicator, flicker filter. Driven by `GameState.activeHazards`.
- **`particle_burst.dart`** — perfect/miss/destroyed feedback.

### 1.4 DeadDispatchGame rewrite

Rewrite [lib/features/gameplay/game/dead_dispatch_game.dart](lib/features/gameplay/game/dead_dispatch_game.dart) (~100 LOC):

```dart
class DeadDispatchGame extends FlameGame with HasTappables {
  final GameSession session;
  final BalanceData balance;
  final AudioService audio;
  final HapticsService haptics;
  final PerfMonitor perf;

  late final SpawnerSystem spawner;
  late final HazardSystem hazards;
  late final RoutingSystem routing;
  late final FeedbackSystem feedback;
  late final BeltComponent belt;

  @override
  Future<void> onLoad() async {
    add(belt = BeltComponent());
    // add lane gates per department
    // add stamp button
    // add hazard overlay
    spawner = SpawnerSystem(session: session, game: this);
    hazards = HazardSystem(session: session, game: this);
    routing = RoutingSystem(session: session, game: this);
    feedback = FeedbackSystem(session: session, audio: audio, haptics: haptics, game: this);
  }

  @override
  void update(double dt) {
    super.update(dt);
    perf.sample(dt);
    session.tick(dt);
    spawner.tick(dt);
    hazards.tick(dt);
    routing.tick(dt);
  }
}
```

### 1.5 GameScreen cleanup
- [lib/features/gameplay/presentation/game_screen.dart](lib/features/gameplay/presentation/game_screen.dart) already listens to `session.events` — once event types exist, the pattern match at L76-90 compiles.
- Remove the placeholder `Future.delayed` → `_session.start()` kickoff; instead call `_session.start()` inside `onLoad()` after components register.
- Pass the now-extended `DeadDispatchGame` constructor args (Phase 0.1).

---

## Phase 2 — Polish & Data Hygiene (~1-2 hours)

### 2.1 Domain cleanups
- Add `int get acceptableCount => records.where((r) => r.outcome == SortOutcome.acceptable).length;` to [lib/domain/models/shift_result.dart:28-33](lib/domain/models/shift_result.dart#L28-L33).
- Add test file `test/domain/progression_service_test.dart` mirroring [test/domain/economy_service_test.dart](test/domain/economy_service_test.dart) structure — cover `recordShift`, department visibility gating.
- Add round-trip serialization test for `PlayerProfile`, `SettingsSnapshot`, `Wallet`, `OwnedUpgrade`, `DailyAttempt`, `RestoredDepartment` (one test file: `test/domain/models_serialization_test.dart`).

### 2.2 Routing consistency
Replace all `Navigator.pushNamed(...)` in screens with `context.go(...)` / `context.push(...)` for go_router consistency. Call sites:
- [lib/features/menu/presentation/main_menu_screen.dart:54-104](lib/features/menu/presentation/main_menu_screen.dart#L54-L104)
- [lib/features/tutorial/presentation/tutorial_screen.dart](lib/features/tutorial/presentation/tutorial_screen.dart)
- [lib/features/shift_brief/presentation/shift_brief_screen.dart](lib/features/shift_brief/presentation/shift_brief_screen.dart)
- [lib/features/daily_challenge/presentation/daily_challenge_screen.dart](lib/features/daily_challenge/presentation/daily_challenge_screen.dart)
- [lib/features/gameplay/presentation/game_screen.dart](lib/features/gameplay/presentation/game_screen.dart)

### 2.3 Tutorial integration
Wire [lib/presentation/widgets/tutorial_overlay.dart](lib/presentation/widgets/tutorial_overlay.dart) into `GameScreen` — show on first `HazardStartedEvent` if `profile.tutorialCompleted` was just flipped, using the `tutorialHint` from each hazard JSON entry ([assets/config/hazards.json](assets/config/hazards.json)).

---

## Phase 3 — Asset & Build Pipeline (optional for v1)

- Replace rectangle placeholders in [assets/images/](assets/images/) with real sprites (belt, package types, lane gates). `.gitkeep` only today.
- Add `.wav`/`.mp3` to [assets/audio/](assets/audio/) and swap `LoggingAudioService` for a `flame_audio`-backed implementation in [lib/di/providers.dart](lib/di/providers.dart).
- Real AdMob swap at [lib/di/providers.dart:127-138](lib/di/providers.dart#L127-L138).
- Firebase Analytics/Crashlytics at the `analyticsServiceProvider` override.

---

## Critical Files

**New (must create):**
- `lib/features/gameplay/game/game_session.dart`
- `lib/features/gameplay/game/game_state.dart`
- `lib/features/gameplay/game/game_events.dart`
- `lib/features/gameplay/game/systems/spawner_system.dart`
- `lib/features/gameplay/game/systems/hazard_system.dart`
- `lib/features/gameplay/game/systems/routing_system.dart`
- `lib/features/gameplay/game/systems/feedback_system.dart`
- `lib/features/gameplay/game/components/belt_component.dart`
- `lib/features/gameplay/game/components/package_component.dart`
- `lib/features/gameplay/game/components/lane_gate_component.dart`
- `lib/features/gameplay/game/components/stamp_button_component.dart`
- `lib/features/gameplay/game/components/hazard_overlay_component.dart`
- `test/domain/progression_service_test.dart`
- `test/domain/models_serialization_test.dart`

**Modify:**
- [lib/features/gameplay/game/dead_dispatch_game.dart](lib/features/gameplay/game/dead_dispatch_game.dart) — constructor + onLoad + update
- [lib/features/gameplay/presentation/game_screen.dart](lib/features/gameplay/presentation/game_screen.dart) — constructor call, event wiring
- [lib/domain/models/shift_result.dart](lib/domain/models/shift_result.dart) — add `acceptableCount`
- [lib/di/providers.dart](lib/di/providers.dart) — optional `scoreServiceProvider`
- Router call-site cleanup in 5 screens (Phase 2.2)

## Reuse — do NOT reinvent

- **Routing math** lives in [lib/domain/services/routing_service.dart](lib/domain/services/routing_service.dart) `resolve()` — systems call it, never reimplement.
- **RNG** must go through [lib/domain/services/seeded_random.dart](lib/domain/services/seeded_random.dart) (daily challenges depend on determinism per [docs/ARCHITECTURE.md:50-53](docs/ARCHITECTURE.md#L50-L53)).
- **Balance tunables** always read from [lib/domain/balance/balance_data.dart](lib/domain/balance/balance_data.dart), never hardcode.
- **Clock** — use [lib/core/time/clock.dart](lib/core/time/clock.dart) in `GameSession`, not `DateTime.now()`.
- **Logger** — [lib/core/logger.dart](lib/core/logger.dart) for anything worth logging.

---

## Verification

```bash
# 1. Platform folders exist
flutter create --org com.deaddispatch --project-name dead_dispatch --platforms=android,ios,web .

# 2. Analyzer clean
flutter pub get
flutter analyze

# 3. All existing + new tests green
flutter test

# 4. Boot on Android emulator / desktop
flutter run -d windows   # or -d chrome, -d <android-device-id>
```

**Manual smoke test (in running app):**
1. Splash → Main Menu renders with wallet + best score.
2. First launch auto-routes to Tutorial → 4 slides → "Start".
3. Shift Brief shows target score/duration → tap Play.
4. **GameScreen:** belt scrolls, packages spawn, tap lane gates to route, priority stamp button consumes stamps, combo meter ticks up on perfects, hazards fire visually (blackout darkens, jam shows red light).
5. Timer hits zero → `ShiftEndedEvent` → Shift Result screen with score breakdown.
6. Rewarded-ad stub grants double coins → returns to Main Menu with updated wallet.
7. Upgrades screen: purchase one upgrade, verify coin deduction + level increment persist across app restart.
8. Departments screen: restore one department, verify unlock appears in next shift.
9. Daily Challenge: same seed on two launches → same package order (determinism).
10. Settings: toggle haptics off → subsequent misses don't vibrate.
11. Debug screen (debug build): grant coins cheat works.

**Perf target:** [docs/ARCHITECTURE.md:110-111](docs/ARCHITECTURE.md#L110-L111) — ≤16.6 ms/frame on Pixel 4a. Check via debug screen `PerfMonitor` readout.
