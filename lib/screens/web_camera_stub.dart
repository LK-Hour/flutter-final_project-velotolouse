// Non-web stub for web camera functionality
import 'package:flutter/material.dart';

class WebCameraView extends StatelessWidget {
  const WebCameraView({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}

void initWebCamera({void Function(String)? onQrDetected}) {}
void disposeWebCamera() {}
