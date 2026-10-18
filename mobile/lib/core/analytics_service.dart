import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Thin wrapper over Firebase Analytics.
///
/// Every call is a no-op when Firebase is not configured on the device, so the
/// app still runs end to end if the google-services.json is missing.
class AnalyticsService {
  FirebaseAnalytics? _analytics;

  bool get isEnabled => _analytics != null;

  Future<void> init() async {
    try {
      await Firebase.initializeApp();
      _analytics = FirebaseAnalytics.instance;
      await _analytics!.setAnalyticsCollectionEnabled(true);
      debugPrint('[analytics] Firebase ready');
    } catch (error) {
      debugPrint('[analytics] disabled, Firebase not configured: $error');
    }
  }

  Future<void> logLoginSuccess({required String username}) {
    return _log('login_success', {'username': username});
  }

  Future<void> logJobViewed({required int jobId, required String status}) {
    return _log('job_viewed', {'job_id': jobId, 'status': status});
  }

  Future<void> logJobStatusUpdated({
    required int jobId,
    required String fromStatus,
    required String toStatus,
  }) {
    return _log('job_status_updated', {
      'job_id': jobId,
      'from_status': fromStatus,
      'to_status': toStatus,
    });
  }

  Future<void> _log(String name, Map<String, Object> parameters) async {
    // Logged either way, so the flow is still verifiable from the console.
    debugPrint('[analytics] $name $parameters');
    final analytics = _analytics;
    if (analytics == null) return;
    try {
      await analytics.logEvent(name: name, parameters: parameters);
    } catch (error) {
      debugPrint('[analytics] failed to log $name: $error');
    }
  }
}
