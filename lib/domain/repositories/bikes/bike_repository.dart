import 'package:final_project_velotolouse/domain/model/stations/bike_slot.dart';

/// Abstract contract for bike-related data operations.
abstract class BikeRepository {
  /// Returns the [BikeSlot] whose [BikeSlot.bikeCode] matches [code],
  /// or null if no bike with that code exists.
  Future<BikeSlot?> getBikeByCode(String code);

  /// Marks the bike identified by [code] as unlocked (available → in-use).
  /// Returns true if the unlock succeeded, false otherwise.
  Future<bool> unlockBike(String code);

  /// Marks the bike identified by [code] as locked (in-use → empty slot).
  /// Returns true if the lock succeeded, false otherwise.
  Future<bool> lockBike(String code);
}
