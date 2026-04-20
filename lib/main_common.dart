import 'package:final_project_velotolouse/app.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

void mainCommon(List<SingleChildWidget> providers) {
  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (_) =>
          MultiProvider(providers: providers, child: const VeloToulouseApp()),
    ),
  );
}
