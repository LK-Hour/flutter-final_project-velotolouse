import 'package:final_project_velotolouse/domain/model/stations/station.dart';
import 'package:final_project_velotolouse/ui/screens/station_map/widgets/station_search_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('return mode marks full docks and blocks selecting them', (
    WidgetTester tester,
  ) async {
    String? selectedStationId;
    const List<Station> stations = <Station>[
      Station(
        id: 'full',
        name: 'Full Station',
        address: 'Address F',
        availableBikes: 6,
        totalCapacity: 6,
        latitude: 43.6061,
        longitude: 1.4492,
      ),
      Station(
        id: 'open',
        name: 'Open Station',
        address: 'Address O',
        availableBikes: 3,
        totalCapacity: 5,
        latitude: 43.6059,
        longitude: 1.4486,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StationSearchSheet(
            onSearch: (_) => stations,
            onSelectStation: (String stationId) {
              selectedStationId = stationId;
            },
            isReturnMode: true,
            availabilityLabelForStation: (Station station) =>
                '${station.freeDocks} Docks',
            canSelectStation: (Station station) => station.freeDocks > 0,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Full / 0 Docks'), findsOneWidget);
    expect(find.text('No docks available'), findsOneWidget);
    expect(find.text('2 Docks'), findsOneWidget);

    await tester.tap(find.byKey(const Key('search-result-full')));
    await tester.pumpAndSettle();
    expect(selectedStationId, isNull);

    await tester.tap(find.byKey(const Key('search-result-open')));
    await tester.pumpAndSettle();
    expect(selectedStationId, 'open');
  });

  testWidgets('return mode empty state mentions free docks', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StationSearchSheet(
            onSearch: (_) => const <Station>[],
            onSelectStation: (_) {},
            isReturnMode: true,
            availabilityLabelForStation: (Station station) =>
                '${station.freeDocks} Docks',
            canSelectStation: (Station station) => station.freeDocks > 0,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('No station with free docks found'), findsOneWidget);
  });

  testWidgets('renting mode marks empty stations and blocks selecting them', (
    WidgetTester tester,
  ) async {
    String? selectedStationId;
    const List<Station> stations = <Station>[
      Station(
        id: 'empty',
        name: 'Empty Station',
        address: 'Address E',
        availableBikes: 0,
        totalCapacity: 6,
        latitude: 43.6061,
        longitude: 1.4492,
      ),
      Station(
        id: 'ready',
        name: 'Ready Station',
        address: 'Address R',
        availableBikes: 2,
        totalCapacity: 6,
        latitude: 43.6059,
        longitude: 1.4486,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StationSearchSheet(
            onSearch: (_) => stations,
            onSelectStation: (String stationId) {
              selectedStationId = stationId;
            },
            isReturnMode: false,
            availabilityLabelForStation: (Station station) =>
                '${station.availableBikes} Bikes',
            canSelectStation: (Station station) => station.availableBikes > 0,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Empty / 0 Bikes'), findsOneWidget);
    expect(find.text('No bikes available'), findsOneWidget);
    expect(find.text('2 Bikes'), findsOneWidget);

    await tester.tap(find.byKey(const Key('search-result-empty')));
    await tester.pumpAndSettle();
    expect(selectedStationId, isNull);

    await tester.tap(find.byKey(const Key('search-result-ready')));
    await tester.pumpAndSettle();
    expect(selectedStationId, 'ready');
  });
}
