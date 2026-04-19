import 'dart:collection';

import '../logger.dart';

/// Tracks rolling frame times so we can detect stutter on real devices.
///
/// This is a pure-Dart sampler — it does not depend on Flutter or Flame.
/// The Flame game ticks `record()` once per frame; UI screens can read
/// `averageFps` to drive a debug overlay.
class PerfMonitor {
  PerfMonitor({this.windowSize = 120});

  final int windowSize;
  final Queue<double> _frameMs = Queue<double>();
  final AppLogger _log = AppLogger('Perf');

  double _peakMs = 0;
  int _droppedFrames = 0;

  void record(double frameMs) {
    _frameMs.addLast(frameMs);
    if (_frameMs.length > windowSize) _frameMs.removeFirst();
    if (frameMs > _peakMs) _peakMs = frameMs;
    if (frameMs > 33.0) _droppedFrames++;
  }

  double get averageMs {
    if (_frameMs.isEmpty) return 0;
    final sum = _frameMs.fold<double>(0, (a, b) => a + b);
    return sum / _frameMs.length;
  }

  double get averageFps => averageMs == 0 ? 0 : 1000.0 / averageMs;
  double get peakMs => _peakMs;
  int get droppedFrames => _droppedFrames;

  void reset() {
    _frameMs.clear();
    _peakMs = 0;
    _droppedFrames = 0;
  }

  void logSnapshot() {
    _log.d(
      'avg=${averageFps.toStringAsFixed(1)}fps '
      'peak=${peakMs.toStringAsFixed(1)}ms '
      'dropped=$_droppedFrames',
    );
  }
}
