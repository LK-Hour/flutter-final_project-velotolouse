import 'package:final_project_velotolouse/domain/model/stations/ride_session.dart';
import 'package:final_project_velotolouse/domain/repositories/rides/ride_repository.dart';
import 'package:flutter/foundation.dart';

/// Global state for managing ride sessions.
/// 
/// Handles:
/// - Current active ride session
/// - Ride state transitions (start/end)
/// - Streaming ride updates from repository
/// 
/// This is a global ChangeNotifier that can be listened to by multiple ViewModels.
class RideState extends ChangeNotifier {
  final RideRepository _repository;

  RideSession? _activeRide;
  bool _hasActiveRide = false;
  bool _isReturnBannerDismissed = false;

  RideState(this._repository) {
    _watchActiveRide();
  }

  // Getters
  RideSession? get activeRide => _activeRide;
  bool get hasActiveRide => _hasActiveRide;
  bool get isReturnMode => _hasActiveRide;
  bool get isReturnBannerDismissed => _isReturnBannerDismissed;

  /// Watch for active ride changes from repository.
  void _watchActiveRide() {
    _repository.watchActiveRide().listen((RideSession? session) {
      _activeRide = session;
      _hasActiveRide = session != null && session.isActive;
      
      // Reset banner dismissal when new ride starts
      if (_hasActiveRide && _activeRide != session) {
        _isReturnBannerDismissed = false;
      }
      
      notifyListeners();
    });
  }

  /// Starts a new ride session.
  Future<RideSession> startRide({
    required String bikeCode,
    required String stationId,
  }) async {
    final session = await _repository.startRide(
      bikeCode: bikeCode,
      stationId: stationId,
    );
    
    _activeRide = session;
    _hasActiveRide = true;
    _isReturnBannerDismissed = false;
    notifyListeners();
    
    return session;
  }

  /// Ends the current active ride.
  /// 
  /// Returns false if no active ride exists.
  Future<bool> endActiveRide() async {
    if (_activeRide == null || !_hasActiveRide) {
      return false;
    }

    await _repository.endRide(_activeRide!.id);
    
    _hasActiveRide = false;
    notifyListeners();
    
    return true;
  }

  /// Manually sets the active ride state (for testing or manual control).
  void setHasActiveRide(bool value) {
    if (_hasActiveRide == value) {
      return;
    }
    
    _hasActiveRide = value;
    
    if (!value) {
      _isReturnBannerDismissed = false;
    }
    
    notifyListeners();
  }

  /// Dismisses the return mode banner.
  /// 
  /// Returns false if banner is already dismissed or no active ride.
  bool dismissReturnBanner() {
    if (_isReturnBannerDismissed || !_hasActiveRide) {
      return false;
    }
    
    _isReturnBannerDismissed = true;
    notifyListeners();
    return true;
  }

  /// Activates return mode from a scan action.
  /// 
  /// Returns false if already in return mode.
  bool activateFromScan() {
    if (_hasActiveRide) {
      return false;
    }
    
    _hasActiveRide = true;
    _isReturnBannerDismissed = false;
    notifyListeners();
    return true;
  }
}
