import 'package:flutter/services.dart' show AssetManifest, rootBundle;

import '../../core/failures.dart';
import '../../core/logger.dart';
import '../../core/result.dart';

/// Warms the bundle cache for assets we expect to need in the first shift
/// — lane icons, stamp sprite, HUD chrome. Runs once at bootstrap; the
/// splash screen waits on it so the first frame of gameplay doesn't hitch.
///
/// Manifest-driven so missing assets surface as a clear startup error
/// rather than a silent failure mid-game.
class AssetPreloader {
  const AssetPreloader();

  /// Pattern prefixes we care about. Missing matches are tolerated (the
  /// game ships before art lands) but reported to the logger.
  static const List<String> _preloadPrefixes = [
    'assets/images/hud/',
    'assets/images/packages/',
    'assets/audio/sfx/',
  ];

  Future<Result<int>> preload() async {
    final log = AppLogger('AssetPreloader');
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final paths = manifest.listAssets();
      final targets = paths
          .where((p) => _preloadPrefixes.any(p.startsWith))
          .toList(growable: false);

      for (final path in targets) {
        await rootBundle.load(path);
      }
      log.i('Preloaded ${targets.length} asset(s).');
      return Ok(targets.length);
    } catch (e, st) {
      log.w('Preload failed (non-fatal): $e');
      log.d('$st');
      return Err(ConfigFailure('Asset preload failed: $e'));
    }
  }
}
