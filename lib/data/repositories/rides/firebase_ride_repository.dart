import 'dart:async';

import 'package:final_project_velotolouse/data/firebase/firebase_rtdb_client.dart';
import 'package:final_project_velotolouse/domain/model/stations/ride_session.dart';
import 'package:final_project_velotolouse/domain/repositories/rides/ride_repository.dart';

class FirebaseRideRepository implements RideRepository {
  FirebaseRideRepository({FirebaseRtdbClient? client})
    : _client = client ?? FirebaseRtdbClient();

  final FirebaseRtdbClient _client;

  @override
  Future<RideSession> startRide({
    required String bikeCode,
    required String stationId,
  }) async {
    final RideSession? activeRide = await getActiveRide();
    if (activeRide != null) {
      return activeRide;
    }

    final DateTime startedAt = DateTime.now();
    final String sessionId = await _client
        .postObject('rides', <String, dynamic>{
          'userId': 'demo-user',
          'bikeCode': bikeCode,
          'stationId': stationId,
          'startedAt': startedAt.toIso8601String(),
          'endedAt': null,
        });

    return RideSession(
      id: sessionId,
      userId: 'demo-user',
      bikeCode: bikeCode,
      stationId: stationId,
      startedAt: startedAt,
    );
  }

  @override
  Future<RideSession> endRide(String sessionId) async {
    final Map<String, dynamic>? rawRide = await _client.getObject(
      'rides/$sessionId',
    );
    if (rawRide == null) {
      throw StateError('Session $sessionId not found.');
    }

    final RideSession session = _rideFromJson(sessionId, rawRide);
    final DateTime endedAt = DateTime.now();
    await _client.patchObject('rides/$sessionId', <String, dynamic>{
      'endedAt': endedAt.toIso8601String(),
    });

    return session.copyWith(endedAt: endedAt);
  }

  @override
  Stream<RideSession?> watchActiveRide() async* {
    yield await getActiveRide();
    yield* Stream<void>.periodic(
      const Duration(seconds: 2),
    ).asyncMap((_) => getActiveRide());
  }

  @override
  Future<RideSession?> getActiveRide() async {
    final Map<String, dynamic>? data = await _client.getObject('rides');
    if (data == null || data.isEmpty) {
      return null;
    }

    final List<RideSession> activeRides = <RideSession>[];
    for (final MapEntry<String, dynamic> entry in data.entries) {
      final Object? rawRide = entry.value;
      if (rawRide is! Map<String, dynamic>) {
        continue;
      }
      final RideSession session = _rideFromJson(entry.key, rawRide);
      if (session.isActive) {
        activeRides.add(session);
      }
    }

    if (activeRides.isEmpty) {
      return null;
    }

    activeRides.sort(
      (RideSession left, RideSession right) =>
          right.startedAt.compareTo(left.startedAt),
    );
    return activeRides.first;
  }

  RideSession _rideFromJson(String id, Map<String, dynamic> json) {
    return RideSession(
      id: json['id'] as String? ?? id,
      userId: json['userId'] as String? ?? 'demo-user',
      bikeCode: json['bikeCode'] as String? ?? '',
      stationId: json['stationId'] as String? ?? '',
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt: json['endedAt'] == null
          ? null
          : DateTime.parse(json['endedAt'] as String),
    );
  }
}
