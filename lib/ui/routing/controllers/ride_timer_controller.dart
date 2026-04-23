import 'dart:async';

import 'package:flutter/foundation.dart';

/// Stopwatch-backed controller that tracks ride duration.
///
/// Uses [Stopwatch] as the source of truth so elapsed time is immune to
/// tick jitter or frame-budget overruns. A [Timer.periodic] fires every
/// second solely to notify listeners so the UI can redraw.
///
/// Usage with ChangeNotifierProvider:
/// ```dart
/// ChangeNotifierProvider(create: (_) => RideTimerController()..start())
/// ```
///
/// Or standalone inside a [StatefulWidget]:
/// ```dart
/// late final RideTimerController _timer;
///
/// @override
/// void initState() {
///   super.initState();
///   _timer = RideTimerController()..start();
/// }
///
/// @override
/// void dispose() {
///   _timer.dispose();
///   super.dispose();
/// }
/// ```
class RideTimerController extends ChangeNotifier {
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _ticker;

  // ── State ──────────────────────────────────────────────────────────────────

  bool get isRunning => _stopwatch.isRunning;

  /// Total elapsed duration sourced from the [Stopwatch].
  Duration get elapsed => _stopwatch.elapsed;

  /// Elapsed time formatted as `HH:MM:SS`.
  String get formattedTime {
    final int total = elapsed.inSeconds;
    final int h = total ~/ 3600;
    final int m = (total % 3600) ~/ 60;
    final int s = total % 60;
    return '${_pad(h)}:${_pad(m)}:${_pad(s)}';
  }

  // ── Control ────────────────────────────────────────────────────────────────

  /// Starts (or resumes) the timer.
  void start() {
    if (_stopwatch.isRunning) return;
    _stopwatch.start();
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) {
      notifyListeners();
    });
  }

  /// Pauses the timer without resetting elapsed time.
  void pause() {
    _stopwatch.stop();
    _ticker?.cancel();
    _ticker = null;
    notifyListeners();
  }

  /// Stops the timer and resets elapsed time to zero.
  void reset() {
    _stopwatch
      ..stop()
      ..reset();
    _ticker?.cancel();
    _ticker = null;
    notifyListeners();
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _stopwatch.stop();
    _ticker?.cancel();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static String _pad(int value) => value.toString().padLeft(2, '0');
}
