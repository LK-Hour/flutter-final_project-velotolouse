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
    expect(find.byIcon(Icons.layers_outlined), findsOneWidget);
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
}
