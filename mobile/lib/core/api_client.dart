import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/job.dart';

/// Any failure the UI is expected to show to the helper in plain language.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}

class LoginResult {
  const LoginResult({required this.token, required this.helper});

  final String token;
  final Helper helper;
}

class ApiClient {
  ApiClient({required String baseUrl, http.Client? httpClient})
      : _baseUrl = normalizeBaseUrl(baseUrl),
        _httpClient = httpClient ?? http.Client();

  // Generous because the free-tier host sleeps when idle and takes ~30-60s to wake.
  static const Duration _timeout = Duration(seconds: 60);

  final http.Client _httpClient;
  String _baseUrl;
  String? _token;

  String get baseUrl => _baseUrl;

  set baseUrl(String value) => _baseUrl = normalizeBaseUrl(value);

  void setToken(String? token) => _token = token;

  /// Accepts "10.0.2.2:8000", "http://host/", etc. and returns a clean origin.
  static String normalizeBaseUrl(String raw) {
    var value = raw.trim();
    if (value.isEmpty) return value;
    if (!value.startsWith('http://') && !value.startsWith('https://')) {
      value = 'http://$value';
    }
    while (value.endsWith('/')) {
      value = value.substring(0, value.length - 1);
    }
    return value;
  }

  Map<String, String> _headers({bool withAuth = true}) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (withAuth && _token != null) 'Authorization': 'Token $_token',
      };

  Future<LoginResult> login({
    required String username,
    required String password,
  }) async {
    final response = await _send(
      () => _httpClient.post(
        Uri.parse('$_baseUrl/api/auth/login/'),
        headers: _headers(withAuth: false),
        body: jsonEncode({'username': username, 'password': password}),
      ),
    );

    final data = _decode(response) as Map<String, dynamic>;
    return LoginResult(
      token: data['token'] as String,
      helper: Helper.fromJson(data['user'] as Map<String, dynamic>),
    );
  }

  Future<List<Job>> fetchJobs() async {
    final response = await _send(
      () => _httpClient.get(
        Uri.parse('$_baseUrl/api/jobs/'),
        headers: _headers(),
      ),
    );

    final data = _decode(response);
    // The endpoint is paginated, but stay tolerant of a bare list too.
    final results = data is Map<String, dynamic> ? data['results'] as List<dynamic> : data as List<dynamic>;
    return results
        .map((item) => Job.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Job> fetchJob(int id) async {
    final response = await _send(
      () => _httpClient.get(
        Uri.parse('$_baseUrl/api/jobs/$id/'),
        headers: _headers(),
      ),
    );

    return Job.fromJson(_decode(response) as Map<String, dynamic>);
  }

  Future<Job> updateJobStatus(int id, JobStatus status) async {
    final response = await _send(
      () => _httpClient.patch(
        Uri.parse('$_baseUrl/api/jobs/$id/status/'),
        headers: _headers(),
        body: jsonEncode({'status': status.wireValue}),
      ),
    );

    return Job.fromJson(_decode(response) as Map<String, dynamic>);
  }

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request().timeout(_timeout);
    } on SocketException {
      throw ApiException(
        'Cannot reach the server at $_baseUrl.\n'
        'Check that the backend is running and that the address is correct.',
      );
    } on TimeoutException {
      throw ApiException('The server took too long to respond. Please try again.');
    } on http.ClientException catch (error) {
      throw ApiException('Network error: ${error.message}');
    }
  }

  dynamic _decode(http.Response response) {
    final isSuccess = response.statusCode >= 200 && response.statusCode < 300;
    if (isSuccess) {
      if (response.bodyBytes.isEmpty) return null;
      return jsonDecode(utf8.decode(response.bodyBytes));
    }
    throw ApiException(_errorMessage(response), statusCode: response.statusCode);
  }

  /// Turns a DRF error body into one readable sentence.
  String _errorMessage(http.Response response) {
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is Map<String, dynamic>) {
        if (body['detail'] is String) return body['detail'] as String;
        final firstValue = body.values.first;
        if (firstValue is List && firstValue.isNotEmpty) {
          return firstValue.first.toString();
        }
        if (firstValue is String) return firstValue;
      }
    } catch (_) {
      // Fall through to the generic message below.
    }

    switch (response.statusCode) {
      case 401:
        return 'Your session has expired. Please sign in again.';
      case 403:
        return 'You are not allowed to do that.';
      case 404:
        return 'That job is not assigned to you.';
      default:
        return 'Something went wrong (HTTP ${response.statusCode}).';
    }
  }
}
