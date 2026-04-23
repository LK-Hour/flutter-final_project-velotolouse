// Web-only camera implementation using dart:html + HtmlElementView + jsQR
// ignore: avoid_web_libraries_in_flutter
import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

html.MediaStream? _stream;
html.VideoElement? _videoEl;
html.CanvasElement? _canvas;
html.CanvasRenderingContext2D? _canvasCtx;
Timer? _scanTimer;
bool _registered = false;
const _viewType = 'qr-scanner-camera-view';

class WebCameraView extends StatelessWidget {
  const WebCameraView({super.key});

  @override
  Widget build(BuildContext context) {
    return const HtmlElementView(viewType: _viewType);
  }
}

void initWebCamera({void Function(String)? onQrDetected}) {
  _videoEl = html.VideoElement()
    ..autoplay = true
    ..muted = true
    ..setAttribute('playsinline', 'true')
    ..style.width = '100%'
    ..style.height = '100%'
    ..style.objectFit = 'cover';

  _canvas = html.CanvasElement();

  if (!_registered) {
    _registered = true;
    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int id) => _videoEl ?? html.DivElement(),
    );
  }

  html.window.navigator.mediaDevices
      ?.getUserMedia({'video': {'facingMode': 'user'}}).then((stream) {
    _stream = stream;
    _videoEl?.srcObject = stream;
    _videoEl?.play();

    if (onQrDetected != null) {
      _startScanning(onQrDetected);
    }
  }).catchError((dynamic e) {
    // ignore: avoid_print
    print('Camera error: $e');
  });
}

void _startScanning(void Function(String) onQrDetected) {
  _scanTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
    try {
      final video = _videoEl;
      final canvas = _canvas;
      if (video == null || canvas == null) return;
      if (video.videoWidth == 0 || video.videoHeight == 0) return;

      canvas.width = video.videoWidth;
      canvas.height = video.videoHeight;
      _canvasCtx ??= canvas.getContext('2d') as html.CanvasRenderingContext2D?;
      final ctx = _canvasCtx;
      if (ctx == null) return;

      ctx.drawImage(video, 0, 0);
      final imageData = ctx.getImageData(0, 0, canvas.width!, canvas.height!);

      // Call jsQR with the raw pixel data
      final result = js.context.callMethod('jsQR', [
        imageData.data,
        canvas.width,
        canvas.height,
      ]);

      if (result != null) {
        final data = js.JsObject.fromBrowserObject(result)['data'];
        if (data != null && data is String && data.isNotEmpty) {
          _scanTimer?.cancel();
          _scanTimer = null;
          onQrDetected(data);
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('QR scan error: $e');
    }
  });
}

void disposeWebCamera() {
  _scanTimer?.cancel();
  _scanTimer = null;
  _stream?.getTracks().forEach((t) => t.stop());
  _stream = null;
  _canvas = null;
  _canvasCtx = null;
}
