import 'package:final_project_velotolouse/domain/model/location/geo_coordinate.dart';
import 'package:final_project_velotolouse/domain/model/location/user_location_result.dart';
import 'package:final_project_velotolouse/domain/repositories/location/user_location_repository.dart';
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

    await tester.tap(find.byKey(const Key('station-marker-capitole-square')));
    await tester.pumpAndSettle();

    expect(find.text('Capitole Square'), findsWidgets);
    expect(find.text('Place du Capitole, 31000 Toulouse'), findsOneWidget);
    expect(find.text('Available Bikes'), findsOneWidget);
    expect(find.text('Empty Slots'), findsOneWidget);
    expect(find.text('Navigate Here'), findsOneWidget);
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
      'jean',
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('search-result-jean-jaures')), findsOneWidget);
    expect(
      find.byKey(const Key('search-result-capitole-square')),
      findsNothing,
    );

    await tester.tap(find.byKey(const Key('search-result-jean-jaures')));
    await tester.pumpAndSettle();

    expect(find.text('Jean Jaures'), findsWidgets);
    expect(find.text('Jean Jaures, 31000 Toulouse'), findsOneWidget);
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

    expect(find.text('9 Docks'), findsOneWidget);
    expect(find.text('0 Docks'), findsOneWidget);
    expect(find.text('8 Docks'), findsOneWidget);
  });

  testWidgets('shows reroute alert for full dock station in return mode', (
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
    await tester.tap(find.byKey(const Key('station-marker-jean-jaures')));
    await tester.pumpAndSettle();

    expect(find.text('Destination Full'), findsOneWidget);
    expect(find.text('SUGGESTED ALTERNATIVE'), findsOneWidget);
    expect(find.text('Reroute to Free Dock'), findsOneWidget);

    await tester.tap(find.text('Reroute to Free Dock'));
    await tester.pumpAndSettle();

    expect(find.text('Destination Full'), findsNothing);
    expect(find.text('Capitole Square'), findsWidgets);
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
    expect(viewModel.mapCenter.latitude, 43.6113);
    expect(viewModel.mapCenter.longitude, 1.4535);
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
      coordinate: GeoCoordinate(latitude: 43.6113, longitude: 1.4535),
    );
  }
}
