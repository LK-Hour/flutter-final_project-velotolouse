import 'package:final_project_velotolouse/domain/model/location/geo_coordinate.dart';
import 'package:final_project_velotolouse/domain/model/location/user_location_result.dart';
import 'package:final_project_velotolouse/domain/model/stations/station.dart';
import 'package:final_project_velotolouse/domain/repositories/location/user_location_repository.dart';
import 'package:final_project_velotolouse/domain/repositories/navigation/navigation_launcher_repository.dart';
import 'package:final_project_velotolouse/domain/repositories/routes/station_route_repository.dart';
import 'package:final_project_velotolouse/domain/repositories/stations/station_repository.dart';
import 'package:final_project_velotolouse/ui/screens/station_map/view_model/station_map_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StationMapViewModel', () {
    test('loads stations and clears loading/error state', () async {
      final StationMapViewModel viewModel = StationMapViewModel(
        repository: _SuccessStationRepository(),
      );

      await viewModel.loadStations();

      expect(viewModel.isLoading, isFalse);
      expect(viewModel.errorMessage, isNull);
      expect(viewModel.stations.length, 1);
      expect(viewModel.stations.first.availableBikes, 3);
    });

    test('selects and clears a station', () async {
      final StationMapViewModel viewModel = StationMapViewModel(
        repository: _SuccessStationRepository(),
      );

      await viewModel.loadStations();
      viewModel.selectStation('station-a');

      expect(viewModel.selectedStation, isNotNull);
      expect(viewModel.selectedStation!.id, 'station-a');

      viewModel.clearSelectedStation();
      expect(viewModel.selectedStation, isNull);
    });

    test('focuses map center to station coordinates', () async {
      final StationMapViewModel viewModel = StationMapViewModel(
        repository: _SuccessStationRepository(),
      );

      await viewModel.loadStations();

      expect(viewModel.mapCenter.latitude, 11.5564);
      expect(viewModel.mapCenter.longitude, 104.9282);

      expect(viewModel.focusOnStation('station-a'), isTrue);
      expect(viewModel.mapCenter.latitude, 43.6);
      expect(viewModel.mapCenter.longitude, 1.44);
      expect(viewModel.focusOnStation('missing-station'), isFalse);
    });

    test('builds route using road path repository when available', () async {
      final _FakeStationRouteRepository routeRepository =
          _FakeStationRouteRepository();
      final StationMapViewModel viewModel = StationMapViewModel(
        repository: _SuccessStationRepository(),
        userLocationRepository: _SuccessUserLocationRepository(),
        stationRouteRepository: routeRepository,
      );

      await viewModel.loadStations();
      final UserLocationStatus status = await viewModel.showRouteToStation(
        viewModel.stations.first,
      );

      expect(status, UserLocationStatus.located);
      expect(routeRepository.calls, 1);
      expect(viewModel.activeRoutePath.length, 3);
      expect(viewModel.activeRoutePath[1].latitude, 11.5620);
      expect(viewModel.activeRoutePath[1].longitude, 104.9140);
    });

    test('switches to return mode only when user has active ride', () async {
      final StationMapViewModel viewModel = StationMapViewModel(
        repository: _SuccessStationRepository(),
      );

      expect(viewModel.isReturnMode, isFalse);
      viewModel.setHasActiveRide(true);
      expect(viewModel.isReturnMode, isTrue);
      viewModel.setHasActiveRide(false);
      expect(viewModel.isReturnMode, isFalse);
    });

    test('toggles return mode for testing', () {
      final StationMapViewModel viewModel = StationMapViewModel(
        repository: _SuccessStationRepository(),
      );

      expect(viewModel.isReturnMode, isFalse);
      viewModel.toggleReturnModeForTesting();
      expect(viewModel.isReturnMode, isTrue);
      viewModel.toggleReturnModeForTesting();
      expect(viewModel.isReturnMode, isFalse);
    });

    test('activates ride from scan only when no ride is active', () {
      final StationMapViewModel viewModel = StationMapViewModel(
        repository: _SuccessStationRepository(),
      );

      expect(viewModel.hasActiveRide, isFalse);
      final bool firstActivation = viewModel.activateRideFromScan();
      expect(firstActivation, isTrue);
      expect(viewModel.hasActiveRide, isTrue);
      expect(viewModel.isReturnMode, isTrue);

      final bool secondActivation = viewModel.activateRideFromScan();
      expect(secondActivation, isFalse);
      expect(viewModel.hasActiveRide, isTrue);
    });

    test('dismisses return banner without ending active ride', () {
      final StationMapViewModel viewModel = StationMapViewModel(
        repository: _SuccessStationRepository(),
      );

      viewModel.activateRideFromScan();
      expect(viewModel.isReturnMode, isTrue);
      expect(viewModel.showReturnModeBanner, isTrue);

      expect(viewModel.dismissReturnModeBanner(), isTrue);
      expect(viewModel.showReturnModeBanner, isFalse);
      expect(viewModel.isReturnMode, isTrue);
      expect(viewModel.hasActiveRide, isTrue);
    });

    test('ends active ride only when explicitly requested', () {
      final StationMapViewModel viewModel = StationMapViewModel(
        repository: _SuccessStationRepository(),
      );

      expect(viewModel.hasActiveRide, isFalse);
      expect(viewModel.endActiveRide(), isFalse);

      viewModel.activateRideFromScan();
      expect(viewModel.hasActiveRide, isTrue);
      expect(viewModel.isReturnMode, isTrue);

      expect(viewModel.endActiveRide(), isTrue);
      expect(viewModel.hasActiveRide, isFalse);
      expect(viewModel.isReturnMode, isFalse);
    });

    test(
      'returns bike and exits return mode only at available station',
      () async {
        final StationMapViewModel viewModel = StationMapViewModel(
          repository: _SuccessStationRepository(),
        );
        await viewModel.loadStations();

        final Station station = viewModel.stations.first;
        expect(
          viewModel.returnBikeToStation(station),
          ReturnBikeResult.noActiveRide,
        );

        viewModel.activateRideFromScan();
        expect(
          viewModel.returnBikeToStation(station),
          ReturnBikeResult.success,
        );
        expect(viewModel.hasActiveRide, isFalse);
        expect(viewModel.isReturnMode, isFalse);
        expect(viewModel.stations.first.availableBikes, 4);
        expect(viewModel.stations.first.freeDocks, 6);

        viewModel.activateRideFromScan();
        const Station fullStation = Station(
          id: 'full',
          name: 'Full',
          address: 'Address',
          availableBikes: 5,
          totalCapacity: 5,
          latitude: 43.6,
          longitude: 1.44,
        );
        expect(
          viewModel.returnBikeToStation(fullStation),
          ReturnBikeResult.stationFull,
        );
        expect(viewModel.hasActiveRide, isTrue);
        expect(viewModel.isReturnMode, isTrue);
      },
    );

    test(
      'suggests nearest dock and reroutes when selected return station is full',
      () async {
        final StationMapViewModel viewModel = StationMapViewModel(
          repository: _RerouteStationRepository(),
        );

        await viewModel.loadStations();
        viewModel.setHasActiveRide(true);
        viewModel.selectStation('full-station');

        expect(viewModel.showFullStationRerouteAlert, isTrue);
        expect(viewModel.suggestedAlternativeDockStation, isNotNull);
        expect(viewModel.suggestedAlternativeDockStation!.id, 'near-open');

        viewModel.rerouteToSuggestedDock();
        expect(viewModel.selectedStation?.id, 'near-open');
        expect(viewModel.showFullStationRerouteAlert, isFalse);
      },
    );

    test(
      'suggests nearest bike station and reroutes when selected renting station is empty',
      () async {
        final StationMapViewModel viewModel = StationMapViewModel(
          repository: _MixedAvailabilityStationRepository(),
        );

        await viewModel.loadStations();
        viewModel.selectStation('empty-a');

        expect(viewModel.isReturnMode, isFalse);
        expect(viewModel.showEmptyStationRerouteAlert, isTrue);
        expect(viewModel.suggestedAlternativeBikeStation, isNotNull);
        expect(viewModel.suggestedAlternativeBikeStation!.id, 'bike-b');

        viewModel.rerouteToSuggestedBikeStation();
        expect(viewModel.selectedStation?.id, 'bike-b');
        expect(viewModel.showEmptyStationRerouteAlert, isFalse);
      },
    );

    test('prioritizes stations with bikes first in renting search', () async {
      final StationMapViewModel viewModel = StationMapViewModel(
        repository: _MixedAvailabilityStationRepository(),
      );

      await viewModel.loadStations();
      final List<Station> results = viewModel.searchStations('');

      expect(results.map((Station station) => station.id), <String>[
        'bike-a',
        'bike-b',
        'empty-a',
      ]);
    });

    test('locates current user and updates map center', () async {
      final StationMapViewModel viewModel = StationMapViewModel(
        repository: _SuccessStationRepository(),
        userLocationRepository: _SuccessUserLocationRepository(),
      );

      expect(viewModel.mapCenter.latitude, 11.5564);
      expect(viewModel.mapCenter.longitude, 104.9282);
      expect(viewModel.currentUserLocation, isNull);
      expect(viewModel.locateRequestVersion, 0);

      final UserLocationStatus status = await viewModel.locateCurrentUser();

      expect(status, UserLocationStatus.located);
      expect(viewModel.mapCenter.latitude, 11.5625);
      expect(viewModel.mapCenter.longitude, 104.9160);
      expect(viewModel.currentUserLocation, isNotNull);
      expect(viewModel.currentUserLocation!.latitude, 11.5625);
      expect(viewModel.currentUserLocation!.longitude, 104.9160);
      expect(viewModel.locateRequestVersion, 1);
    });

    test(
      'increments locate request version on every successful locate',
      () async {
        final _CountingUserLocationRepository locationRepository =
            _CountingUserLocationRepository();
        final StationMapViewModel viewModel = StationMapViewModel(
          repository: _SuccessStationRepository(),
          userLocationRepository: locationRepository,
        );

        await viewModel.locateCurrentUser();
        await viewModel.locateCurrentUser();

        expect(locationRepository.calls, 2);
        expect(viewModel.locateRequestVersion, 2);
        expect(viewModel.mapCenter.latitude, 11.5625);
        expect(viewModel.mapCenter.longitude, 104.9160);
      },
    );

    test(
      'reports denied location permission when GPS access is blocked',
      () async {
        final StationMapViewModel viewModel = StationMapViewModel(
          repository: _SuccessStationRepository(),
          userLocationRepository: _DeniedUserLocationRepository(),
        );

        final UserLocationStatus status = await viewModel.locateCurrentUser();

        expect(status, UserLocationStatus.permissionDenied);
        expect(viewModel.mapCenter.latitude, 11.5564);
        expect(viewModel.mapCenter.longitude, 104.9282);
      },
    );

    test('opens external navigation directions for selected station', () async {
      final _FakeNavigationLauncherRepository launcherRepository =
          _FakeNavigationLauncherRepository();
      final StationMapViewModel viewModel = StationMapViewModel(
        repository: _SuccessStationRepository(),
        userLocationRepository: _SuccessUserLocationRepository(),
        navigationLauncherRepository: launcherRepository,
      );

      await viewModel.loadStations();
      final StationNavigationResult result = await viewModel.navigateToStation(
        viewModel.stations.first,
      );

      expect(result, StationNavigationResult.opened);
      expect(launcherRepository.calls, 1);
      expect(launcherRepository.lastOrigin, isNotNull);
      expect(launcherRepository.lastDestination, isNotNull);
      expect(launcherRepository.lastOrigin!.latitude, 11.5625);
      expect(launcherRepository.lastOrigin!.longitude, 104.9160);
      expect(launcherRepository.lastDestination!.latitude, 43.6);
      expect(launcherRepository.lastDestination!.longitude, 1.44);
    });

    test('returns permissionDenied when location access is blocked', () async {
      final _FakeNavigationLauncherRepository launcherRepository =
          _FakeNavigationLauncherRepository();
      final StationMapViewModel viewModel = StationMapViewModel(
        repository: _SuccessStationRepository(),
        userLocationRepository: _DeniedUserLocationRepository(),
        navigationLauncherRepository: launcherRepository,
      );

      await viewModel.loadStations();
      final StationNavigationResult result = await viewModel.navigateToStation(
        viewModel.stations.first,
      );

      expect(result, StationNavigationResult.permissionDenied);
      expect(launcherRepository.calls, 0);
    });

    test('exposes an error message when repository fails', () async {
      final StationMapViewModel viewModel = StationMapViewModel(
        repository: _FailingStationRepository(),
      );

      await viewModel.loadStations();

      expect(viewModel.isLoading, isFalse);
      expect(viewModel.stations, isEmpty);
      expect(viewModel.errorMessage, isNotNull);
    });
  });
}

class _SuccessStationRepository implements StationRepository {
  @override
  Future<List<Station>> fetchStations() async {
    return const <Station>[
      Station(
        id: 'station-a',
        name: 'Station A',
        address: 'Address A',
        availableBikes: 3,
        totalCapacity: 10,
        latitude: 43.6,
        longitude: 1.44,
      ),
    ];
  }
}

class _FailingStationRepository implements StationRepository {
  @override
  Future<List<Station>> fetchStations() async {
    throw Exception('Network failed');
  }
}

class _RerouteStationRepository implements StationRepository {
  @override
  Future<List<Station>> fetchStations() async {
    return const <Station>[
      Station(
        id: 'full-station',
        name: 'Full Station',
        address: 'Address F',
        availableBikes: 6,
        totalCapacity: 6,
        latitude: 43.6061,
        longitude: 1.4492,
      ),
      Station(
        id: 'near-open',
        name: 'Near Open',
        address: 'Address N',
        availableBikes: 2,
        totalCapacity: 10,
        latitude: 43.6059,
        longitude: 1.4486,
      ),
      Station(
        id: 'far-open',
        name: 'Far Open',
        address: 'Address R',
        availableBikes: 1,
        totalCapacity: 9,
        latitude: 43.5994,
        longitude: 1.4449,
      ),
    ];
  }
}

class _MixedAvailabilityStationRepository implements StationRepository {
  @override
  Future<List<Station>> fetchStations() async {
    return const <Station>[
      Station(
        id: 'empty-a',
        name: 'Alpha Empty',
        address: 'Address E',
        availableBikes: 0,
        totalCapacity: 8,
        latitude: 43.6061,
        longitude: 1.4492,
      ),
      Station(
        id: 'bike-b',
        name: 'Beta Ready',
        address: 'Address B',
        availableBikes: 1,
        totalCapacity: 8,
        latitude: 43.6059,
        longitude: 1.4486,
      ),
      Station(
        id: 'bike-a',
        name: 'Alpha Ready',
        address: 'Address A',
        availableBikes: 2,
        totalCapacity: 8,
        latitude: 43.5994,
        longitude: 1.4449,
      ),
    ];
  }
}

class _SuccessUserLocationRepository implements UserLocationRepository {
  @override
  Future<UserLocationResult> getCurrentLocation() async {
    return const UserLocationResult(
      status: UserLocationStatus.located,
      coordinate: GeoCoordinate(latitude: 11.5625, longitude: 104.9160),
    );
  }
}

class _DeniedUserLocationRepository implements UserLocationRepository {
  @override
  Future<UserLocationResult> getCurrentLocation() async {
    return const UserLocationResult(
      status: UserLocationStatus.permissionDenied,
    );
  }
}

class _CountingUserLocationRepository implements UserLocationRepository {
  int calls = 0;

  @override
  Future<UserLocationResult> getCurrentLocation() async {
    calls += 1;
    return const UserLocationResult(
      status: UserLocationStatus.located,
      coordinate: GeoCoordinate(latitude: 11.5625, longitude: 104.9160),
    );
  }
}

class _FakeNavigationLauncherRepository
    implements NavigationLauncherRepository {
  int calls = 0;
  GeoCoordinate? lastOrigin;
  GeoCoordinate? lastDestination;

  @override
  Future<bool> openDirections({
    GeoCoordinate? origin,
    required GeoCoordinate destination,
  }) async {
    calls += 1;
    lastOrigin = origin;
    lastDestination = destination;
    return true;
  }
}

class _FakeStationRouteRepository implements StationRouteRepository {
  int calls = 0;

  @override
  Future<List<GeoCoordinate>> fetchCyclingRoute({
    required GeoCoordinate origin,
    required GeoCoordinate destination,
  }) async {
    calls += 1;
    return <GeoCoordinate>[
      origin,
      const GeoCoordinate(latitude: 11.5620, longitude: 104.9140),
      destination,
    ];
  }
}
