import '../core/logger.dart';

/// Sound IDs the game can request. The audio service decides what file
/// (or generated tone) backs each ID — call sites stay decoupled.
enum SoundId {
  uiTap,
  uiBack,
  // Conveyor-era sounds kept so any in-flight call sites still resolve;
  // they no longer fire from gameplay.
  packageSpawn,
  packageStamp,
  packageSorted,
  packageMissed,
  packageDestroyed,
  comboUp,
  hazardWarn,
  hazardClear,
  shiftStart,
  shiftEnd,
  reward,
  // Block-puzzle sounds.
  piecePickUp,
  piecePlaced,
  linesCleared,
  comboChime,
  invalidDrop,
  gameOverSigh,
  coinSparkle;

  String get key => name;
}

abstract class AudioService {
  Future<void> initialize();
  Future<void> playSfx(SoundId id, {double? volume});
  Future<void> playMusic(String trackId, {bool loop = true});
  Future<void> stopMusic();
  Future<void> setMusicVolume(double v);
  Future<void> setSfxVolume(double v);
  void dispose();
}

/// Logs-only fallback. Keeps the game shippable before audio assets land
/// and is a no-op on devices that fail to initialize the mixer.
class LoggingAudioService implements AudioService {
  final AppLogger _log = AppLogger('Audio');

  double _music = 0.7;
  double _sfx = 0.9;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> playSfx(SoundId id, {double? volume}) async {
    _log.d('sfx=${id.key} vol=${volume ?? _sfx}');
  }

  @override
  Future<void> playMusic(String trackId, {bool loop = true}) async {
    _log.d('music=$trackId loop=$loop vol=$_music');
  }

  @override
  Future<void> stopMusic() async => _log.d('music=stop');

  @override
  Future<void> setMusicVolume(double v) async => _music = v.clamp(0, 1);

  @override
  Future<void> setSfxVolume(double v) async => _sfx = v.clamp(0, 1);

  @override
  void dispose() {}
}
