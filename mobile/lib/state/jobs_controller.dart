import 'package:flutter/foundation.dart';

import '../core/analytics_service.dart';
import '../core/api_client.dart';
import '../models/job.dart';

enum JobsViewState { loading, ready, error }

class JobsController extends ChangeNotifier {
  JobsController({required this.apiClient, required this.analytics});

  final ApiClient apiClient;
  final AnalyticsService analytics;

  JobsViewState _state = JobsViewState.loading;
  List<Job> _jobs = const [];
  String? _errorMessage;
  bool _sessionExpired = false;
  int? _updatingJobId;

  JobsViewState get state => _state;
  List<Job> get jobs => _jobs;
  String? get errorMessage => _errorMessage;
  bool get isEmpty => _jobs.isEmpty;
  bool get sessionExpired => _sessionExpired;
  int? get updatingJobId => _updatingJobId;

  Future<void> load({bool showSpinner = true}) async {
    if (showSpinner) {
      _state = JobsViewState.loading;
      notifyListeners();
    }

    try {
      _jobs = await apiClient.fetchJobs();
      _errorMessage = null;
      _state = JobsViewState.ready;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      _sessionExpired = error.isUnauthorized;
      _state = JobsViewState.error;
    } finally {
      notifyListeners();
    }
  }

  Job? jobById(int id) {
    for (final job in _jobs) {
      if (job.id == id) return job;
    }
    return null;
  }

  Future<Job> viewJob(int id) async {
    final job = await apiClient.fetchJob(id);
    _replace(job);
    await analytics.logJobViewed(jobId: job.id, status: job.status.wireValue);
    return job;
  }

  /// Returns null on success, or a message to show the helper on failure.
  Future<String?> updateStatus(Job job, JobStatus newStatus) async {
    _updatingJobId = job.id;
    notifyListeners();

    try {
      final updated = await apiClient.updateJobStatus(job.id, newStatus);
      _replace(updated);
      await analytics.logJobStatusUpdated(
        jobId: job.id,
        fromStatus: job.status.wireValue,
        toStatus: updated.status.wireValue,
      );
      return null;
    } on ApiException catch (error) {
      _sessionExpired = error.isUnauthorized;
      return error.message;
    } finally {
      _updatingJobId = null;
      notifyListeners();
    }
  }

  void _replace(Job job) {
    final index = _jobs.indexWhere((candidate) => candidate.id == job.id);
    if (index == -1) {
      _jobs = [..._jobs, job];
    } else {
      final next = [..._jobs];
      next[index] = job;
      _jobs = next;
    }
  }

  void reset() {
    _jobs = const [];
    _state = JobsViewState.loading;
    _errorMessage = null;
    _sessionExpired = false;
    notifyListeners();
  }
}
