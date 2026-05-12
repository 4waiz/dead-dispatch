/// Centralized English strings. Replace with `.arb` + `gen-l10n` when ready
/// for full localization. Call sites already go through this indirection so
/// adding a second locale is mechanical.
class Strings {
  const Strings._();

  static const String appTitle = 'Dead Dispatch';
  static const String tapToStart = 'Tap to start';
  static const String menuPlay = 'Play Shift';
  static const String menuDaily = 'Daily Seal';
  static const String menuUpgrades = 'Upgrades';
  static const String menuDepartments = 'Restore Office';
  static const String menuSettings = 'Settings';
  static const String menuQuit = 'Quit';
  static const String menuTutorial = 'How to Play';

  static const String shiftReady = 'Shift ready, dispatcher.';
  static const String shiftStart = 'Start';
  static const String shiftPause = 'Pause';
  static const String shiftResume = 'Resume';
  static const String shiftEnd = 'End of shift';

  static const String resultPayout = 'Payout';
  static const String resultBonus = 'Bonus';
  static const String resultDouble = 'Watch ad to double';
  static const String resultMystery = 'Mystery parcel';
  static const String resultContinue = 'Continue (1 free)';
  static const String resultPlayAgain = 'Play Again';
  static const String resultRestoreOffice = 'Restore Office';

  static const String bestScore = 'Best score';
  static const String linesCleared = 'Lines cleared';
  static const String biggestCombo = 'Biggest combo';
  static const String gameOverTitle = 'Shift Ended';

  static const String upgradesTitle = 'Mailroom upgrades';
  static const String departmentsTitle = 'Restore Office';
  static const String dailyTitle = "Today's seal";

  static const String settingsTitle = 'Settings';
  static const String settingsAudio = 'Audio';
  static const String settingsHaptics = 'Haptics';
  static const String settingsMusic = 'Music';
  static const String settingsSfx = 'Sound effects';
  static const String settingsReducedMotion = 'Reduced motion';
  static const String settingsLargeText = 'Large text';
  static const String settingsResetSave = 'Reset save';
  static const String settingsResetSaveConfirm =
      'This wipes all progress. Continue?';

  // Tutorial slides — 4 steps walking the player through drag, place,
  // clear, and combo.
  static const String tutorialIntro =
      'Welcome to Dead Dispatch! Drag colorful ghost-mail blocks from the '
      'tray onto the haunted desk. Place them anywhere they fit.';
  static const String tutorialFillRow =
      'Fill a whole row or column to clear it. The desk lights up with a '
      'wax-stamp burst when mail gets dispatched.';
  static const String tutorialClearCoins =
      'Every cleared line pays you in coins. Spend coins to restore rooms '
      'in the haunted office and unlock new piece types.';
  static const String tutorialComboDaily =
      'Chain clears for a combo multiplier — bigger combos, bigger payouts. '
      'Daily Seal challenges everyone with the same board for one shot a day.';
}
