import 'package:final_project_velotolouse/data/mock/bike_slot_mock_data.dart';
import 'package:final_project_velotolouse/domain/model/stations/bike_slot.dart';
import 'package:final_project_velotolouse/domain/repositories/bikes/bike_repository.dart';

/// In-memory mock implementation of [BikeRepository].
///
/// Uses [mockCapitoleSlots] as the data source. Changes to slot state
/// (unlock / lock) are kept in a local mutable map for the session.
class MockBikeRepository implements BikeRepository {
  MockBikeRepository({
    this.getBikeDelay = const Duration(milliseconds: 300),
    this.unlockDelay = const Duration(milliseconds: 500),
    this.lockDelay = const Duration(milliseconds: 500),
  });

  final Duration getBikeDelay;
  final Duration unlockDelay;
  final Duration lockDelay;

  /// Mutable in-memory copy of all known slots, keyed by bikeCode.
  final Map<String, BikeSlot> _slots = {
    for (final slot in mockCapitoleSlots)
      if (slot.bikeCode != null) slot.bikeCode!: slot,
  };

  @override
  Future<BikeSlot?> getBikeByCode(String code) async {
    // Simulate a short network delay.
    if (getBikeDelay > Duration.zero) {
      await Future.delayed(getBikeDelay);
    }
    return _slots[code];
  }

  @override
  Future<bool> unlockBike(String code) async {
    if (unlockDelay > Duration.zero) {
      await Future.delayed(unlockDelay);
    }
    final slot = _slots[code];
    if (slot == null || !slot.isAvailable) return false;

    // Mark slot as unavailable (bike taken out).
    _slots[code] = slot.copyWith(
      status: BikeSlotStatus.unavailable,
      bikeCode: null,
    );
    return true;
  }

  @override
  Future<bool> lockBike(String code) async {
    if (lockDelay > Duration.zero) {
      await Future.delayed(lockDelay);
    }
    // For mock purposes, locking always succeeds and restores the slot.
    final slot = _slots[code];
    if (slot != null) {
      _slots[code] = slot.copyWith(
        status: BikeSlotStatus.available,
        bikeCode: code,
      );
    }
    return true;
  }
}
