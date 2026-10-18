/// The three states a job can be in, mirroring the backend's Job.Status.
enum JobStatus {
  assigned('ASSIGNED', 'Assigned'),
  inProgress('IN_PROGRESS', 'In progress'),
  completed('COMPLETED', 'Completed');

  const JobStatus(this.wireValue, this.label);

  final String wireValue;
  final String label;

  static JobStatus fromWire(String value) {
    return JobStatus.values.firstWhere(
      (status) => status.wireValue == value,
      orElse: () => JobStatus.assigned,
    );
  }
}

class Job {
  const Job({
    required this.id,
    required this.title,
    required this.description,
    required this.customerName,
    required this.customerPhone,
    required this.address,
    required this.scheduledFor,
    required this.status,
    required this.nextStatuses,
  });

  final int id;
  final String title;
  final String description;
  final String customerName;
  final String customerPhone;
  final String address;
  final DateTime scheduledFor;
  final JobStatus status;

  /// Supplied by the backend so the app never has to re-implement the rules.
  final List<JobStatus> nextStatuses;

  JobStatus? get nextStatus => nextStatuses.isEmpty ? null : nextStatuses.first;

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      customerName: json['customer_name'] as String? ?? '',
      customerPhone: json['customer_phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
      scheduledFor:
          DateTime.tryParse(json['scheduled_for'] as String? ?? '')?.toLocal() ??
              DateTime.now(),
      status: JobStatus.fromWire(json['status'] as String? ?? 'ASSIGNED'),
      nextStatuses: (json['next_statuses'] as List<dynamic>? ?? [])
          .map((value) => JobStatus.fromWire(value as String))
          .toList(),
    );
  }
}

class Helper {
  const Helper({required this.id, required this.username, required this.fullName});

  final int id;
  final String username;
  final String fullName;

  factory Helper.fromJson(Map<String, dynamic> json) {
    return Helper(
      id: json['id'] as int,
      username: json['username'] as String,
      fullName: json['full_name'] as String? ?? json['username'] as String,
    );
  }
}
