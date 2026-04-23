import 'dart:convert';

import 'package:http/http.dart' as http;

class FirebaseRtdbClient {
  FirebaseRtdbClient({this.baseUrl = defaultBaseUrl, http.Client? client})
    : _client = client ?? http.Client();

  static const String defaultBaseUrl =
      'https://flutter-project-velotolouse-default-rtdb.asia-southeast1.firebasedatabase.app';

  final String baseUrl;
  final http.Client _client;

  Uri _uri(String path) {
    final String normalizedBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final String normalizedPath = path.replaceFirst(RegExp(r'^/+'), '');
    return Uri.parse('$normalizedBaseUrl/$normalizedPath.json');
  }

  Future<Map<String, dynamic>?> getObject(String path) async {
    final http.Response response = await _client.get(_uri(path));
    _ensureSuccess(response);
    final Object? decoded = _decode(response.body);
    return decoded is Map<String, dynamic> ? decoded : null;
  }

  Future<void> putObject(String path, Object? value) async {
    final http.Response response = await _client.put(
      _uri(path),
      headers: _jsonHeaders,
      body: jsonEncode(value),
    );
    _ensureSuccess(response);
  }

  Future<void> patchObject(String path, Map<String, dynamic> value) async {
    final http.Response response = await _client.patch(
      _uri(path),
      headers: _jsonHeaders,
      body: jsonEncode(value),
    );
    _ensureSuccess(response);
  }

  Future<String> postObject(String path, Map<String, dynamic> value) async {
    final http.Response response = await _client.post(
      _uri(path),
      headers: _jsonHeaders,
      body: jsonEncode(value),
    );
    _ensureSuccess(response);

    final Object? decoded = _decode(response.body);
    final Map<String, dynamic> payload = decoded is Map<String, dynamic>
        ? decoded
        : <String, dynamic>{};
    final String? key = payload['name'] as String?;
    if (key == null || key.isEmpty) {
      throw StateError('Firebase RTDB did not return a generated key.');
    }
    return key;
  }

  Future<void> delete(String path) async {
    final http.Response response = await _client.delete(_uri(path));
    _ensureSuccess(response);
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    throw StateError(
      'Firebase RTDB request failed with status '
      '${response.statusCode}: ${response.body}',
    );
  }

  Object? _decode(String body) {
    if (body.trim().isEmpty || body.trim() == 'null') {
      return null;
    }
    return jsonDecode(body);
  }

  Map<String, String> get _jsonHeaders => const <String, String>{
    'Content-Type': 'application/json; charset=utf-8',
  };
}
