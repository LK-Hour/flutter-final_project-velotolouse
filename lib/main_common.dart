import 'package:final_project_velotolouse/app.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

void mainCommon(List<SingleChildWidget> providers) {
  runApp(MultiProvider(providers: providers, child: const VeloToulouseApp()));
}
