import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../core/theme.dart';
import '../models/job.dart';
import '../state/jobs_controller.dart';
import '../widgets/glass.dart';
import '../widgets/status_chip.dart';

class JobDetailScreen extends StatefulWidget {
  const JobDetailScreen({super.key, required this.jobId});

  final int jobId;

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  late Future<Job> _jobFuture;

  @override
  void initState() {
    super.initState();
    _jobFuture = _loadJob();
  }

  /// Always re-fetches the detail: it logs job_viewed and keeps status fresh.
  Future<Job> _loadJob() => context.read<JobsController>().viewJob(widget.jobId);

  void _reload() {
    setState(() {
      _jobFuture = _loadJob();
    });
  }

  Future<void> _changeStatus(Job job, JobStatus newStatus) async {
    final message = await context.read<JobsController>().updateStatus(job, newStatus);
    if (!mounted) return;

    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Job marked as ${newStatus.label.toLowerCase()}')),
    );
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  GlassIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    tooltip: 'Back',
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'Job details',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.4),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<Job>(
                future: _jobFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    final error = snapshot.error;
                    return MessageView(
                      icon: Icons.error_outline_rounded,
                      title: 'Could not load this job',
                      message: error is ApiException ? error.message : error.toString(),
                      onRetry: _reload,
                    );
                  }

                  return _JobDetailBody(
                    job: snapshot.data!,
                    onChangeStatus: _changeStatus,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JobDetailBody extends StatelessWidget {
  const _JobDetailBody({required this.job, required this.onChangeStatus});

  final Job job;
  final void Function(Job job, JobStatus newStatus) onChangeStatus;

  @override
  Widget build(BuildContext context) {
    // The live copy carries the status after an update; the future's copy may not.
    final current = context.watch<JobsController>().jobById(job.id) ?? job;
    final isUpdating = context.watch<JobsController>().updatingJobId == current.id;
    final nextStatus = current.nextStatus;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            children: [
              GlassContainer(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        current.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    StatusChip(status: current.status),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              GlassContainer(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 2),
                child: Column(
                  children: [
                    _DetailTile(
                      icon: Icons.schedule_rounded,
                      label: 'Scheduled for',
                      value: DateFormat('EEEE, d MMMM yyyy • h:mm a').format(current.scheduledFor),
                    ),
                    _DetailTile(
                      icon: Icons.person_outline_rounded,
                      label: 'Customer',
                      value: current.customerName,
                                    ),
                    if (current.customerPhone.isNotEmpty)
                      _DetailTile(
                        icon: Icons.phone_outlined,
                        label: 'Phone',
                        value: current.customerPhone,
                      ),
                    _DetailTile(
                      icon: Icons.place_outlined,
                      label: 'Address',
                      value: current.address,
                    ),
                    if (current.description.isNotEmpty)
                      _DetailTile(
                        icon: Icons.notes_rounded,
                        label: 'Notes',
                        value: current.description,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: _ActionButton(
              nextStatus: nextStatus,
              isUpdating: isUpdating,
              onPressed: nextStatus == null ? null : () => onChangeStatus(current, nextStatus),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.nextStatus,
    required this.isUpdating,
    required this.onPressed,
  });

  final JobStatus? nextStatus;
  final bool isUpdating;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    if (nextStatus == null) {
      return const GlassContainer(
        radius: 29,
        padding: EdgeInsets.symmetric(vertical: 18),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.success),
            SizedBox(width: 8),
            Text(
              'This job is complete',
              style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ],
        ),
      );
    }

    final (label, icon, color) = switch (nextStatus!) {
      JobStatus.inProgress => ('Start job', Icons.play_arrow_rounded, AppColors.primary),
      JobStatus.completed => ('Mark as completed', Icons.check_rounded, AppColors.primary),
      JobStatus.assigned => ('Update status', Icons.sync_rounded, AppColors.primary),
    };

    return GlassButton(
      label: label,
      icon: icon,
      color: color,
      loading: isUpdating,
      onPressed: isUpdating ? null : onPressed,
    );
  }
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassIconBadge(icon: icon),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.inkSoft,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(value, style: const TextStyle(fontSize: 15.5, height: 1.3)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
