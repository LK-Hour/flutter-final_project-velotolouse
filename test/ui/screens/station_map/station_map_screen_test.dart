import 'package:final_project_velotolouse/domain/model/location/geo_coordinate.dart';
import 'package:final_project_velotolouse/domain/model/location/user_location_result.dart';
import 'package:final_project_velotolouse/domain/model/stations/station.dart';
import 'package:final_project_velotolouse/domain/repositories/location/user_location_repository.dart';
import 'package:final_project_velotolouse/domain/repositories/stations/station_repository.dart';
import 'package:final_project_velotolouse/domain/repositories/routes/station_route_repository.dart';
import 'package:final_project_velotolouse/data/repositories/stations/station_repository_mock.dart';
import 'package:final_project_velotolouse/ui/screens/station_map/station_map_screen.dart';
import 'package:final_project_velotolouse/ui/screens/station_map/view_model/station_map_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('renders search bar and station markers', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<StationMapViewModel>(
          create: (_) =>
              StationMapViewModel(repository: MockStationRepository())
                ..loadStations(),
          child: const StationMapScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Find a station or destination...'), findsOneWidget);
    expect(find.text('3 Bikes'), findsOneWidget);
    expect(find.text('5 Bikes'), findsOneWidget);
    expect(find.text('8 Bikes'), findsOneWidget);
    expect(find.text('Ready to ride?'), findsOneWidget);
    expect(find.byKey(const Key('scan-button')), findsOneWidget);
    expect(find.byIcon(Icons.gps_fixed_rounded), findsOneWidget);
    expect(find.byIcon(Icons.layers_outlined), findsNothing);
  });

  testWidgets('shows station info popup when marker is tapped', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<StationMapViewModel>(
          create: (_) =>
              StationMapViewModel(repository: MockStationRepository())
                ..loadStations(),
          child: const StationMapScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('station-marker-wat-phnom')));
    await tester.pumpAndSettle();

    expect(find.text('Wat Phnom'), findsWidgets);
    expect(find.text('Street 94, Daun Penh, Phnom Penh'), findsOneWidget);
    expect(find.text('Available Bikes'), findsOneWidget);
    expect(find.text('Empty Slots'), findsOneWidget);
    expect(find.text('Navigate Here'), findsOneWidget);
  });

  testWidgets('navigate here draws route from user to selected station', (
    WidgetTester tester,
  ) async {
    final _FakeStationRouteRepository routeRepository =
        _FakeStationRouteRepository();
    final StationMapViewModel viewModel = StationMapViewModel(
      repository: MockStationRepository(),
      userLocationRepository: _LocatedUserLocationRepository(),
      stationRouteRepository: routeRepository,
    )..loadStations();

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<StationMapViewModel>.value(
          value: viewModel,
          child: const StationMapScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('station-marker-wat-phnom')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Navigate Here'));
    await tester.pumpAndSettle();

    expect(viewModel.activeRoutePath.length, 3);
    expect(viewModel.activeRoutePath.first.latitude, 11.5625);
    expect(viewModel.activeRoutePath.first.longitude, 104.9160);
    expect(viewModel.activeRoutePath[1].latitude, 11.5620);
    expect(viewModel.activeRoutePath[1].longitude, 104.9140);
    expect(viewModel.activeRoutePath.last.latitude, 11.559729);
    expect(viewModel.activeRoutePath.last.longitude, 104.910392);
    expect(routeRepository.calls, 1);
  });

  testWidgets('search sheet filters and selects a station', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<StationMapViewModel>(
          create: (_) =>
              StationMapViewModel(repository: MockStationRepository())
                ..loadStations(),
          child: const StationMapScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Find a station or destination...'));
    await tester.pumpAndSettle();

    expect(find.text('Search station'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('station-search-input')),
      'market',
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('search-result-central-market')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('search-result-wat-phnom')), findsNothing);

    await tester.tap(find.byKey(const Key('search-result-central-market')));
    await tester.pumpAndSettle();

    expect(find.text('Central Market'), findsWidgets);
    expect(
      find.text('Phnom, Samdach Sang Neayok Srey St. (67), Penh 12209'),
      findsOneWidget,
    );
  });

  testWidgets('switches map mode for testing when mode button is tapped', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<StationMapViewModel>(
          create: (_) =>
              StationMapViewModel(repository: MockStationRepository())
                ..loadStations(),
          child: const StationMapScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('mode-toggle-button')));
    await tester.pumpAndSettle();

    expect(find.text('P | 9 Free'), findsOneWidget);
    expect(find.text('P | Full'), findsOneWidget);
    expect(find.text('P | 8 Free'), findsOneWidget);
  });

  testWidgets('scan button starts ride and enables return mode', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<StationMapViewModel>(
          create: (_) =>
              StationMapViewModel(repository: MockStationRepository())
                ..loadStations(),
          child: const StationMapScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('scan-button')));
    await tester.pumpAndSettle();

    expect(find.text('Bike unlocked. Return mode activated.'), findsOneWidget);
    expect(find.text('Returning Mode ON'), findsOneWidget);
    expect(find.text('Free Docks nearby'), findsOneWidget);
    expect(find.text('Return in progress'), findsOneWidget);
    expect(find.text('Find a station or destination...'), findsNothing);
    expect(find.text('Returning mode ON'), findsNothing);
    expect(find.text('P | 9 Free'), findsOneWidget);
  });

  testWidgets('return bike action exits return mode from free dock popup', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<StationMapViewModel>(
          create: (_) =>
              StationMapViewModel(repository: MockStationRepository())
                ..loadStations(),
          child: const StationMapScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('scan-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('station-marker-wat-phnom')));
    await tester.pumpAndSettle();

    expect(find.text('Return Bike Here'), findsOneWidget);
    await tester.tap(find.text('Return Bike Here'));
    await tester.pumpAndSettle();

    expect(find.text('Find a station or destination...'), findsOneWidget);
    expect(find.text('Ready to ride?'), findsOneWidget);
    expect(find.text('4 Bikes'), findsOneWidget);
    expect(find.text('3 Bikes'), findsNothing);
    expect(find.text('P | 9 Free'), findsNothing);
  });

  testWidgets('banner close dismisses banner but keeps return mode active', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<StationMapViewModel>(
          create: (_) =>
              StationMapViewModel(repository: MockStationRepository())
                ..loadStations(),
          child: const StationMapScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('scan-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('return-mode-banner-close')));
    await tester.pumpAndSettle();

    expect(find.text('Returning Mode ON'), findsNothing);
    expect(find.text('Free Docks nearby'), findsNothing);
    expect(find.text('Find a station with free docks...'), findsOneWidget);
    expect(find.text('Ready to ride?'), findsNothing);
    expect(find.text('Return in progress'), findsOneWidget);
    expect(find.text('P | 9 Free'), findsOneWidget);
    expect(find.byKey(const Key('mode-toggle-button')), findsNothing);
  });

  testWidgets('return mode search keeps full station unselectable', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<StationMapViewModel>(
          create: (_) =>
              StationMapViewModel(repository: MockStationRepository())
                ..loadStations(),
          child: const StationMapScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('scan-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('return-mode-banner-close')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Find a station with free docks...'));
    await tester.pumpAndSettle();

    expect(find.text('Search station'), findsOneWidget);
    expect(find.text('Full / 0 Docks'), findsOneWidget);

    await tester.tap(find.byKey(const Key('search-result-central-market')));
    await tester.pumpAndSettle();

    expect(find.text('Search station'), findsOneWidget);
    expect(find.text('Destination Full'), findsNothing);
  });

  testWidgets('return mode search lists stations with free docks first', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<StationMapViewModel>(
          create: (_) =>
              StationMapViewModel(repository: MockStationRepository())
                ..loadStations(),
          child: const StationMapScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('scan-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('return-mode-banner-close')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Find a station with free docks...'));
    await tester.pumpAndSettle();

    final double carmesTop = tester
        .getTopLeft(
          find.byKey(const Key('search-result-independence-monument')),
        )
        .dy;
    final double jeanJauresTop = tester
        .getTopLeft(find.byKey(const Key('search-result-central-market')))
        .dy;

    expect(carmesTop, lessThan(jeanJauresTop));
  });

  testWidgets('shows eta chip for selected dock in return mode', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<StationMapViewModel>(
          create: (_) =>
              StationMapViewModel(repository: MockStationRepository())
                ..loadStations(),
          child: const StationMapScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('mode-toggle-button')));
    await tester.pumpAndSettle();

    expect(find.text('2 min away'), findsNothing);

    await tester.tap(
      find.byKey(const Key('station-marker-independence-monument')),
    );
    await tester.pumpAndSettle();

    expect(find.text('2 min away'), findsOneWidget);
  });

  testWidgets('shows reroute alert for full dock station in return mode', (
    WidgetTester tester,
  ) async {
    final StationMapViewModel viewModel = StationMapViewModel(
      repository: MockStationRepository(),
    )..loadStations();

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<StationMapViewModel>.value(
          value: viewModel,
          child: const StationMapScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('mode-toggle-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('station-marker-central-market')));
    await tester.pumpAndSettle();

    expect(find.text('Destination Full'), findsOneWidget);
    expect(find.text('SUGGESTED ALTERNATIVE'), findsOneWidget);
    expect(find.text('Reroute to Free Dock'), findsOneWidget);

    await tester.tap(find.text('Reroute to Free Dock'));
    await tester.pumpAndSettle();

    expect(find.text('Destination Full'), findsNothing);
    expect(viewModel.selectedStation, isNotNull);
    expect(viewModel.selectedStation!.freeDocks, greaterThan(0));
  });

  testWidgets('shows reroute alert for empty-bike station in renting mode', (
    WidgetTester tester,
  ) async {
    final StationMapViewModel viewModel = StationMapViewModel(
      repository: _EmptyBikeStationRepository(),
    )..loadStations();

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<StationMapViewModel>.value(
          value: viewModel,
          child: const StationMapScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('station-marker-central-market')));
    await tester.pumpAndSettle();

    expect(find.text('No Bikes Available'), findsOneWidget);
    expect(find.text('Reroute to Available Bike'), findsOneWidget);

    await tester.tap(find.text('Reroute to Available Bike'));
    await tester.pumpAndSettle();

    expect(find.text('No Bikes Available'), findsNothing);
    expect(viewModel.selectedStation, isNotNull);
    expect(viewModel.selectedStation!.availableBikes, greaterThan(0));
  });

  testWidgets('keeps bottom nav buttons aligned around scan button', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<StationMapViewModel>(
          create: (_) =>
              StationMapViewModel(repository: MockStationRepository())
                ..loadStations(),
          child: const StationMapScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final Finder rideLabel = find.text('Ride');
    final Finder profileLabel = find.text('Profile');
    final Finder scanButton = find.byKey(const Key('scan-button'));

    final Offset rideCenter = tester.getCenter(rideLabel);
    final Offset profileCenter = tester.getCenter(profileLabel);
    final Offset scanCenter = tester.getCenter(scanButton);

    expect(rideCenter.dy, moreOrLessEquals(profileCenter.dy, epsilon: 1));
    expect(
      (scanCenter.dx - rideCenter.dx).abs(),
      moreOrLessEquals((profileCenter.dx - scanCenter.dx).abs(), epsilon: 6),
    );
  });

  testWidgets('locate quick action shows unavailable location feedback', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<StationMapViewModel>(
          create: (_) =>
              StationMapViewModel(repository: MockStationRepository())
                ..loadStations(),
          child: const StationMapScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('quick-action-locate')));
    await tester.pumpAndSettle();

    expect(find.text('Unable to find your current location.'), findsOneWidget);
  });

  testWidgets('locate quick action recenters map to user location', (
    WidgetTester tester,
  ) async {
    final _LocatedUserLocationRepository locationRepository =
        _LocatedUserLocationRepository();
    final StationMapViewModel viewModel = StationMapViewModel(
      repository: MockStationRepository(),
      userLocationRepository: locationRepository,
    )..loadStations();

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<StationMapViewModel>.value(
          value: viewModel,
          child: const StationMapScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('quick-action-locate')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('quick-action-locate')));
    await tester.pumpAndSettle();

    expect(find.text('Centered on your current location.'), findsOneWidget);
    expect(
      find.byKey(const Key('current-location-fallback-marker')),
      findsOneWidget,
    );
    expect(locationRepository.calls, 2);
    expect(viewModel.locateRequestVersion, 2);
    expect(viewModel.mapCenter.latitude, 11.5625);
    expect(viewModel.mapCenter.longitude, 104.9160);
  });

  testWidgets('locate quick action is placed at bottom-right area', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<StationMapViewModel>(
          create: (_) =>
              StationMapViewModel(repository: MockStationRepository())
                ..loadStations(),
          child: const StationMapScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final Offset locateCenter = tester.getCenter(
      find.byKey(const Key('quick-action-locate')),
    );
    final Size screenSize = tester.getSize(find.byType(Scaffold));

    expect(locateCenter.dx, greaterThan(screenSize.width * 0.75));
    expect(locateCenter.dy, greaterThan(screenSize.height * 0.65));
  });
}

class _LocatedUserLocationRepository implements UserLocationRepository {
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

class _EmptyBikeStationRepository implements StationRepository {
  @override
  Future<List<Station>> fetchStations() async {
    return const <Station>[
      Station(
        id: 'wat-phnom',
        name: 'Wat Phnom',
        address: 'Street 94, Daun Penh, Phnom Penh',
        availableBikes: 3,
        totalCapacity: 12,
        latitude: 11.559729,
        longitude: 104.910392,
      ),
      Station(
        id: 'central-market',
        name: 'Central Market',
        address: 'Phnom, Samdach Sang Neayok Srey St. (67), Penh 12209',
        availableBikes: 0,
        totalCapacity: 5,
        latitude: 11.5715,
        longitude: 104.9176,
      ),
      Station(
        id: 'independence-monument',
        name: 'Independence Monument',
        address: 'Preah Sihanouk Blvd, Chamkar Mon, Phnom Penh',
        availableBikes: 8,
        totalCapacity: 16,
        latitude: 11.5564,
        longitude: 104.9282,
      ),
    ];
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
