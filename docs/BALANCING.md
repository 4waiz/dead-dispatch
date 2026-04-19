# Balancing

All tunable numbers live in `assets/config/*.json`. Changing these does
NOT require a code recompile — for dev iteration run `flutter run` and
hot-restart after saving the JSON.

| File | Contains |
|---|---|
| `balance.json` | Shift pacing, target score growth, economy constants. |
| `packages.json` | Per-type base score, speed, fragility, destination lane. |
| `hazards.json` | Duration + severity for each hazard event. |
| `upgrades.json` | Per-level cost + effect for every persistent upgrade. |
| `departments.json` | Floor/room list and what each unlock grants. |
| `shifts.json` | Special shift configs (tutorial today; can grow). |

## Difficulty curve

The target score grows geometrically with the player's progression level:

```
targetScore(level) = baseTargetScore × (targetScoreGrowth ^ level)
```

`progressionLevel = (totalShiftsPlayed ~/ 3) + (restoredDepartments × 2)`

The spawn interval decays linearly:

```
spawnIntervalMs(level) = clamp(
  baseSpawnIntervalMs − spawnIntervalDecayPerLevelMs × level,
  minSpawnIntervalMs,
  baseSpawnIntervalMs,
)
```

## Adding a new package type

1. Add the enum value in `lib/domain/models/package_type.dart`.
2. Add a descriptor entry to `assets/config/packages.json`.
3. Extend `RoutingSystem.resolve` with the new success rule if it needs
   bespoke logic (otherwise the generic "lane match" path applies).
4. Add a colour in `AppColors.forPackage`.
5. Add a routing unit test in `test/domain/routing_system_test.dart`.
6. Optional: add a new lane to `StageLayout.lanePositions`.

## Adding a new hazard

1. Add the enum value in `lib/domain/models/hazard.dart`.
2. Add a descriptor entry to `assets/config/hazards.json`.
3. Gate the unlock behind a progression level in
   `DifficultyService._build`.
4. Implement its visual/gameplay effect in `lib/game/systems/hazard_system.dart`
   (or add to `FeedbackSystem` if it's purely cosmetic).

## Monetization knobs

| Key | Effect |
|---|---|
| `economy.mysteryParcelMin/Max` | Range rolled for the rewarded mystery parcel. |
| `economy.dailyCompletionBonus` | Flat coin bonus for clearing the daily. |
| `economy.failureForgivenessRefund` | Share of payout kept on shift failure (0–1). |
| `economy.comboMultiplierCap` | Max combo multiplier to cap runaway scoring. |
