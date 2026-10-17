import 'package:flutter/foundation.dart';

import '../core/analytics_service.dart';
import '../core/api_client.dart';
import '../core/session_store.dart';
import '../models/job.dart';

enum AuthStatus { checking, signedOut, signedIn }

class AuthController extends ChangeNotifier {
  AuthController({
    required this.apiClient,
    required this.sessionStore,
    required this.analytics,
  });

  final ApiClient apiClient;
  final SessionStore sessionStore;
  final AnalyticsService analytics;

  AuthStatus _status = AuthStatus.checking;
  Helper? _helper;
  String? _errorMessage;
  bool _isSubmitting = false;
  String _baseUrl = SessionStore.defaultBaseUrl;

  AuthStatus get status => _status;
  Helper? get helper => _helper;
  String? get errorMessage => _errorMessage;
  bool get isSubmitting => _isSubmitting;
  String get baseUrl => _baseUrl;

  /// Restores a previous session so the helper is not asked to log in twice.
  Future<void> bootstrap() async {
    _baseUrl = await sessionStore.readBaseUrl();
    apiClient.baseUrl = _baseUrl;

    final token = await sessionStore.readToken();
    final helper = await sessionStore.readHelper();

    if (token != null && helper != null) {
      apiClient.setToken(token);
      _helper = helper;
      _status = AuthStatus.signedIn;
    } else {
      _status = AuthStatus.signedOut;
    }
    notifyListeners();
  }

  Future<bool> signIn({
    required String username,
    required String password,
    required String baseUrl,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    _baseUrl = ApiClient.normalizeBaseUrl(baseUrl);
    apiClient.baseUrl = _baseUrl;
    await sessionStore.writeBaseUrl(_baseUrl);

    try {
      final result = await apiClient.login(username: username, password: password);
      apiClient.setToken(result.token);
      await sessionStore.saveSession(token: result.token, helper: result.helper);

      _helper = result.helper;
      _status = AuthStatus.signedIn;
      await analytics.logLoginSuccess(username: result.helper.username);
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await sessionStore.clearSession();
    apiClient.setToken(null);
    _helper = null;
    _errorMessage = null;
    _status = AuthStatus.signedOut;
    notifyListeners();
  }
}
