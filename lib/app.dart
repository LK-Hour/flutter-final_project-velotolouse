import 'package:final_project_velotolouse/ui/screens/station_map/station_map_screen.dart';
import 'package:final_project_velotolouse/ui/routing/app_router.dart';
import 'package:final_project_velotolouse/ui/theme/app_theme.dart';
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
      onGenerateRoute: AppRoutes.onGenerateRoute,
      home: const StationMapScreen(),
    );
  }
}
