import 'package:final_project_velotolouse/ui/screens/active_ride/active_ride_screen.dart';
import 'package:final_project_velotolouse/ui/screens/bike_connecting/bike_connecting_screen.dart';
import 'package:flutter/material.dart';

/// Central routing table for the VeloToulouse app.
///
/// Navigation flow:
///   [AppRoutes.bikeConnecting]   ← 2-second animated loading screen
///     ↓ (auto after 2 s)
///   [AppRoutes.activeRide]       ← Active Ride Dashboard (live timer, actions)
///     ↓ (End Ride / Start Riding)
///   [MainShell]  (popUntil first route)
///
/// Usage – push connecting screen with args:
/// ```dart
/// Navigator.pushReplacementNamed(
///   context,
///   AppRoutes.bikeConnecting,
///   arguments: BikeConnectionArgs(bikeCode: 'CO-04', stationName: 'Capitole Square'),
/// );
/// ```
abstract final class AppRoutes {
  // ── Route name constants ──────────────────────────────────────────────────

  /// 2-second animated "Connecting to bike…" screen.
  /// Expects [BikeConnectionArgs] as route arguments.
  static const String bikeConnecting = '/bike-connecting';

  /// Active Ride Dashboard — live stopwatch, quick actions, end ride.
  /// Expects [ActiveRideArgs] as route arguments.
  static const String activeRide = '/active-ride';

  // ── Route factory ─────────────────────────────────────────────────────────

  /// Plug this into [MaterialApp.onGenerateRoute].
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.bikeConnecting:
        final args = settings.arguments;
        if (args is! BikeConnectionArgs) return null;
        return _slide(
          BikeConnectingScreen(
            bikeCode: args.bikeCode,
            stationName: args.stationName,
          ),
          settings,
        );

      case AppRoutes.activeRide:
        final args = settings.arguments;
        if (args is! ActiveRideArgs) return null;
        return _slide(ActiveRideScreen.fromArgs(args), settings);

      default:
        return null; // Fall through to MaterialApp.home
    }
  }

  // ── Transition helper ─────────────────────────────────────────────────────

  /// Horizontal slide-in transition — consistent across all bike-flow screens.
  static PageRouteBuilder<T> _slide<T>(Widget page, RouteSettings settings) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
          child: child,
        );
      },
    );
  }
}

/// Typed argument object for [AppRoutes.bikeConnecting].
class BikeConnectionArgs {
  const BikeConnectionArgs({
    required this.bikeCode,
    required this.stationName,
  });

  final String bikeCode;
  final String stationName;
}
