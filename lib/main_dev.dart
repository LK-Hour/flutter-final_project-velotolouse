import 'package:final_project_velotolouse/data/repositories/location/user_location_repository_device.dart';
import 'package:final_project_velotolouse/data/repositories/bikes/firebase_bike_repository.dart';
import 'package:final_project_velotolouse/data/repositories/bikes/firebase_station_bike_inventory_repository.dart';
import 'package:final_project_velotolouse/data/repositories/navigation/navigation_launcher_repository_url.dart';
import 'package:final_project_velotolouse/data/repositories/rides/firebase_ride_repository.dart';
import 'package:final_project_velotolouse/data/repositories/subscription_plans/firestore_instant_payment_repository.dart';
import 'package:final_project_velotolouse/data/repositories/routes/station_route_repository_google.dart';
import 'package:final_project_velotolouse/data/repositories/stations/firebase_station_repository.dart';
import 'package:final_project_velotolouse/domain/repositories/bikes/station_bike_inventory_repository.dart';
import 'package:final_project_velotolouse/domain/repositories/bikes/bike_repository.dart';
import 'package:final_project_velotolouse/domain/repositories/location/user_location_repository.dart';
import 'package:final_project_velotolouse/domain/repositories/navigation/navigation_launcher_repository.dart';
import 'package:final_project_velotolouse/domain/repositories/rides/ride_repository.dart';
import 'package:final_project_velotolouse/domain/repositories/routes/station_route_repository.dart';
import 'package:final_project_velotolouse/domain/repositories/stations/station_repository.dart';
import 'package:final_project_velotolouse/domain/repositories/subscription_plans/instant_payment_repository.dart';
import 'package:final_project_velotolouse/firebase_options.dart';
import 'package:final_project_velotolouse/main_common.dart';
import 'package:final_project_velotolouse/services/ride_service.dart';
import 'package:final_project_velotolouse/services/station_service.dart';
import 'package:final_project_velotolouse/ui/screens/subscription_plans/state/subscription_refresh_notifier.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

String get _googleDirectionsApiKey {
  if (!dotenv.isInitialized) return '';
  return dotenv.env['GOOGLE_DIRECTIONS_API_KEY'] ?? '';
}

/// Layer 1 (repositories) + Layer 2 (services) providers.
///
/// Layer 3 (global states) and Layer 4 (view models) are wired in
/// [VeloToulouseAppWrapper] inside main_common.dart, where they can read
/// the repositories via context.
List<SingleChildWidget> get devProviders {
  return <SingleChildWidget>[
    ChangeNotifierProvider<SubscriptionRefreshNotifier>(
      create: (_) => SubscriptionRefreshNotifier(),
    ),

    // ── Layer 1: Repositories ────────────────────────────────────────────
    Provider<UserLocationRepository>(
      create: (_) => DeviceUserLocationRepository(),
    ),
    Provider<NavigationLauncherRepository>(
      create: (_) => UrlNavigationLauncherRepository(),
    ),
    Provider<StationRouteRepository>(
      create: (_) =>
          GoogleStationRouteRepository(apiKey: _googleDirectionsApiKey),
    ),
    Provider<StationBikeInventoryRepository>(
      create: (_) => FirebaseStationBikeInventoryRepository(),
    ),
    Provider<StationRepository>(create: (_) => FirebaseStationRepository()),
    Provider<BikeRepository>(create: (_) => FirebaseBikeRepository()),
    Provider<RideRepository>(create: (_) => FirebaseRideRepository()),
    Provider<InstantPaymentRepository>(
      create: (context) {
        final notifier = context.read<SubscriptionRefreshNotifier>();
        return FirestoreInstantPaymentRepository(refreshNotifier: notifier);
      },
    ),

    // ── Layer 2: Services ────────────────────────────────────────────────
    Provider<StationService>(create: (_) => StationService()),
    Provider<RideService>(create: (_) => RideService()),
  ];
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    await dotenv.load(fileName: '.env', isOptional: true);
  }
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
