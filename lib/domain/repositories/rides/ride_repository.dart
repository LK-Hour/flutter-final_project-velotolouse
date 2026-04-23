import 'package:final_project_velotolouse/domain/model/stations/ride_session.dart';

/// Abstract contract for ride session data operations.
abstract class RideRepository {
  /// Creates and persists a new [RideSession] for [bikeCode] taken from
  /// [stationId]. Returns the newly created session.
  Future<RideSession> startRide({
    required String bikeCode,
    required String stationId,
  });

  /// Marks the session with [sessionId] as ended by setting [RideSession.endedAt]
  /// to the current time. Returns the updated session.
  Future<RideSession> endRide(String sessionId);

  /// Emits the currently active [RideSession], or null when no ride is ongoing.
  Stream<RideSession?> watchActiveRide();

  /// Returns the most recent active session, or null if none exists.
  Future<RideSession?> getActiveRide();
}
