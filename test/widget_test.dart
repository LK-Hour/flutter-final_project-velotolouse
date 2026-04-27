import 'package:final_project_velotolouse/app.dart';
import 'package:final_project_velotolouse/main_dev.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('app boots to US2 station map screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(providers: devProviders, child: const VeloToulouseApp()),
    );
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(find.text('Find a station or destination...'), findsOneWidget);
    expect(find.text('Ride'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });
}
