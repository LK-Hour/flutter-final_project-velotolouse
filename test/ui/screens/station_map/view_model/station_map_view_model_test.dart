import 'package:final_project_velotolouse/domain/model/stations/station.dart';
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
