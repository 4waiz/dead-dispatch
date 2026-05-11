/// Centralized English strings. Replace with `.arb` + `gen-l10n` when ready
/// for full localization. Call sites already go through this indirection so
/// adding a second locale is mechanical.
class Strings {
  const Strings._();

  static const String appTitle = 'Dead Dispatch';
  static const String tapToStart = 'Tap to start';
  static const String menuPlay = 'Play Shift';
  static const String menuDaily = 'Daily Challenge';
  static const String menuUpgrades = 'Upgrades';
  static const String menuDepartments = 'Restore';
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

  static const String tutorialIntro =
      'You run a haunted mailroom. Sort cursed parcels to earn coins and restore the Dead Dispatch office.';
  static const String tutorialPriority =
      'Each parcel has a destination. Gold priority parcels must be stamped, then sent to the Secure Vault.';
  static const String tutorialFragile =
      'Other parcels unlock as you restore rooms. Fragile mail goes through the Side Chute or it breaks.';
  static const String tutorialJam =
      'Hit the shift score target before time runs out. More coins means more restored rooms and stranger mail.';
}
