import 'package:final_project_velotolouse/ui/routing/app_router.dart';
import 'package:final_project_velotolouse/ui/screens/station_map/station_map_screen.dart';
import 'package:final_project_velotolouse/ui/theme/app_theme.dart';
import 'package:final_project_velotolouse/screens/profile_screen.dart';
import 'package:final_project_velotolouse/widgets/custom_bottom_nav_bar.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';

class VeloToulouseApp extends StatelessWidget {
  const VeloToulouseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      title: 'VeloToulouse',
      theme: appTheme,
      home: const MainShell(),
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    StationMapScreen(), // Ride tab — LK-Hour's map
    ProfileScreen(),    // Profile tab
  ];

  void _onQrTap() {
    Navigator.pushNamed(context, AppRoutes.qrScanner);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        onQrTap: _onQrTap,
      ),
    );
  }
}
