import 'package:final_project_velotolouse/ui/widgets/ride_completion_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows ride completion details and dismisses on done', (
    WidgetTester tester,
  ) async {
    bool doneTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: RideCompletionModal(
              bikeCode: 'CO-04',
              stationName: 'Wat Phnom',
              rideDuration: '00:12:34',
              onDone: () {
                doneTapped = true;
              },
            ),
          ),
        ),
      ),
    );

    expect(find.text('Ride complete'), findsOneWidget);
    expect(
      find.text('Thank you for riding with VeloToulouse.'),
      findsOneWidget,
    );
    expect(find.text('Bike code'), findsOneWidget);
    expect(find.text('CO-04'), findsOneWidget);
    expect(find.text('Station'), findsOneWidget);
    expect(find.text('Wat Phnom'), findsOneWidget);
    expect(find.text('Ride duration'), findsOneWidget);
    expect(find.text('00:12:34'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(doneTapped, isTrue);
  });
}
