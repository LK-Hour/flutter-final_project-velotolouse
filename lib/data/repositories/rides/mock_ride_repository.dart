import 'dart:async';

import 'package:final_project_velotolouse/domain/model/stations/ride_session.dart';
import 'package:final_project_velotolouse/domain/repositories/rides/ride_repository.dart';

/// In-memory mock implementation of [RideRepository].
///
/// Persists ride sessions in a local list for the app session.
/// Broadcasts changes to [watchActiveRide] via a [StreamController].
class MockRideRepository implements RideRepository {
  MockRideRepository({
    this.startDelay = const Duration(milliseconds: 300),
    this.endDelay = const Duration(milliseconds: 300),
  });

  final Duration startDelay;
  final Duration endDelay;

  final List<RideSession> _sessions = [];
  final StreamController<RideSession?> _activeRideController =
      StreamController<RideSession?>.broadcast();

  int _idCounter = 1;

  @override
  Future<RideSession> startRide({
    required String bikeCode,
    required String stationId,
  }) async {
    if (startDelay > Duration.zero) {
      await Future.delayed(startDelay);
    }

    final session = RideSession(
      id: 'ride-${_idCounter++}',
      bikeCode: bikeCode,
      stationId: stationId,
      startedAt: DateTime.now(),
    );

    _sessions.add(session);
    _activeRideController.add(session);
    return session;
  }

  @override
  Future<RideSession> endRide(String sessionId) async {
    if (endDelay > Duration.zero) {
      await Future.delayed(endDelay);
    }

    final index = _sessions.indexWhere((s) => s.id == sessionId);
    if (index == -1) throw StateError('Session $sessionId not found.');

    final updated = _sessions[index].copyWith(endedAt: DateTime.now());
    _sessions[index] = updated;

    // Emit null to signal no active ride.
    _activeRideController.add(null);
    return updated;
  }

  @override
  Stream<RideSession?> watchActiveRide() => _activeRideController.stream;

  @override
  Future<RideSession?> getActiveRide() async {
    try {
      return _sessions.lastWhere((s) => s.isActive);
    } on StateError {
      return null;
    }
  }

  /// Call this when the repository is no longer needed to free resources.
  void dispose() => _activeRideController.close();
}
