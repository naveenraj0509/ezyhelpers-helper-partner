import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../models/job.dart';
import '../state/jobs_controller.dart';
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
          backgroundColor: const Color(0xFFB71C1C),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Job details')),
      body: FutureBuilder<Job>(
        future: _jobFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final error = snapshot.error;
            return MessageView(
              icon: Icons.error_outline,
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
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      current.title,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  StatusChip(status: current.status),
                ],
              ),
              const SizedBox(height: 20),
              _DetailTile(
                icon: Icons.schedule,
                label: 'Scheduled for',
                value: DateFormat('EEEE, d MMMM yyyy • h:mm a').format(current.scheduledFor),
              ),
              _DetailTile(
                icon: Icons.person_outline,
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
                  icon: Icons.notes_outlined,
                  label: 'Notes',
                  value: current.description,
                ),
            ],
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
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
      return const SizedBox(
        width: double.infinity,
        child: Card(
          color: Color(0xFFE8F5E9),
          elevation: 0,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Color(0xFF1B5E20)),
                SizedBox(width: 8),
                Text(
                  'This job is complete',
                  style: TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final label = switch (nextStatus!) {
      JobStatus.inProgress => 'Start job',
      JobStatus.completed => 'Mark as completed',
      JobStatus.assigned => 'Update status',
    };

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: isUpdating ? null : onPressed,
        style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
        child: isUpdating
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Text(label),
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({required this.icon, required this.label, required this.value});

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
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
