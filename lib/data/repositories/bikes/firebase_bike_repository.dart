import 'package:final_project_velotolouse/data/firebase/firebase_rtdb_client.dart';
import 'package:final_project_velotolouse/domain/model/stations/bike_slot.dart';
import 'package:final_project_velotolouse/domain/repositories/bikes/bike_repository.dart';

class FirebaseBikeRepository implements BikeRepository {
  FirebaseBikeRepository({FirebaseRtdbClient? client})
    : _client = client ?? FirebaseRtdbClient();

  final FirebaseRtdbClient _client;

  @override
  Future<BikeSlot?> getBikeByCode(String code) async {
    final _BikeInventoryRecord? record = await _findRecordByCode(code);
    return record?.toBikeSlot();
  }

  @override
  Future<bool> unlockBike(String code) async {
    final _BikeInventoryRecord? record = await _findRecordByCode(code);
    if (record == null || !record.slot.isAvailable) {
      return false;
    }

    await _client.patchObject('bikeInventory/$code', <String, dynamic>{
      'status': 'empty',
      'bikeCode': null,
    });
    await _adjustStationAvailability(record.stationId, -1);
    return true;
  }

  @override
  Future<bool> lockBike(String code) async {
    final _BikeInventoryRecord? record = await _findRecordByCode(code);
    if (record == null) {
      return true;
    }

    await _client.patchObject('bikeInventory/$code', <String, dynamic>{
      'status': 'available',
      'bikeCode': code,
    });
    await _adjustStationAvailability(record.stationId, 1);
    return true;
  }

  Future<_BikeInventoryRecord?> _findRecordByCode(String code) async {
    final Map<String, dynamic>? data = await _client.getObject('bikeInventory');
    if (data == null) {
      return null;
    }

    final Object? rawRecord = data[code];
    if (rawRecord is! Map<String, dynamic>) {
      return null;
    }

    return _BikeInventoryRecord.fromJson(code, rawRecord);
  }

  Future<void> _adjustStationAvailability(String stationId, int delta) async {
    final Map<String, dynamic>? stations = await _client.getObject('stations');
    if (stations == null) {
      return;
    }

    final Object? rawStation = stations[stationId];
    if (rawStation is! Map<String, dynamic>) {
      return;
    }

    final int availableBikes = _asInt(rawStation['availableBikes']);
    final int totalCapacity = _asInt(rawStation['totalCapacity']);
    final int nextValue = (availableBikes + delta)
        .clamp(0, totalCapacity)
        .toInt();

    await _client.patchObject('stations/$stationId', <String, dynamic>{
      'availableBikes': nextValue,
    });
  }

  int _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class _BikeInventoryRecord {
  const _BikeInventoryRecord({
    required this.stationId,
    required this.slotId,
    required this.status,
    required this.bikeCode,
  });

  factory _BikeInventoryRecord.fromJson(
    String fallbackCode,
    Map<String, dynamic> json,
  ) {
    final String statusValue = (json['status'] as String? ?? 'empty')
        .toLowerCase();
    return _BikeInventoryRecord(
      stationId: json['stationId'] as String? ?? 'capitole-square',
      slotId: json['slotId'] as String? ?? fallbackCode,
      status: statusValue == 'available'
          ? BikeSlotStatus.available
          : BikeSlotStatus.empty,
      bikeCode: json['bikeCode'] as String?,
    );
  }

  final String stationId;
  final String slotId;
  final BikeSlotStatus status;
  final String? bikeCode;

  BikeSlot get slot => toBikeSlot();

  BikeSlot toBikeSlot() {
    return BikeSlot(id: slotId, status: status, bikeCode: bikeCode);
  }
}
