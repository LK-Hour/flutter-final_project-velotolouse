import 'package:final_project_velotolouse/data/repositories/location/user_location_repository_device.dart';
import 'package:final_project_velotolouse/data/repositories/navigation/navigation_launcher_repository_url.dart';
import 'package:final_project_velotolouse/data/repositories/subscription_plans/firestore_instant_payment_repository.dart';
import 'package:final_project_velotolouse/data/repositories/subscription_plans/mock_instant_payment_repository.dart';
import 'package:final_project_velotolouse/data/repositories/routes/station_route_repository_google.dart';
import 'package:final_project_velotolouse/data/repositories/stations/station_repository_mock.dart';
import 'package:final_project_velotolouse/domain/repositories/location/user_location_repository.dart';
import 'package:final_project_velotolouse/domain/repositories/navigation/navigation_launcher_repository.dart';
import 'package:final_project_velotolouse/domain/repositories/routes/station_route_repository.dart';
import 'package:final_project_velotolouse/domain/repositories/stations/station_repository.dart';
import 'package:final_project_velotolouse/domain/repositories/subscription_plans/instant_payment_repository.dart';
import 'package:final_project_velotolouse/firebase_options.dart';
import 'package:final_project_velotolouse/main_common.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:final_project_velotolouse/ui/screens/station_map/view_model/station_map_view_model.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

String get _googleDirectionsApiKey {
  if (!dotenv.isInitialized) {
    return '';
  }

  return dotenv.env['GOOGLE_DIRECTIONS_API_KEY'] ?? '';
}

List<SingleChildWidget> get devProviders {
  return <SingleChildWidget>[
    Provider<UserLocationRepository>(
      create: (_) => DeviceUserLocationRepository(),
    ),
    Provider<NavigationLauncherRepository>(
      create: (_) => UrlNavigationLauncherRepository(),
    ),
    Provider<StationRouteRepository>(
      create: (_) => GoogleStationRouteRepository(
        apiKey: _googleDirectionsApiKey,
      ),
    ),
    Provider<StationRepository>(create: (_) => MockStationRepository()),
    Provider<InstantPaymentRepository>(
      create: (_) {
        if (Firebase.apps.isNotEmpty) {
          return FirestoreInstantPaymentRepository();
        }
        return MockInstantPaymentRepository();
      },
    ),
    ChangeNotifierProvider<StationMapViewModel>(
      create: (context) => StationMapViewModel(
        repository: context.read<StationRepository>(),
        userLocationRepository: context.read<UserLocationRepository>(),
        navigationLauncherRepository: context
            .read<NavigationLauncherRepository>(),
        stationRouteRepository: context.read<StationRouteRepository>(),
      )..loadStations(),
    ),
  ];
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env', isOptional: true);
  await _initializeFirebase();
  mainCommon(devProviders);
}

Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {
    // Keep app usable with mock repositories until Firebase is configured.
  }
}
