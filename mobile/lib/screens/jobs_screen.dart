import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/job.dart';
import '../state/auth_controller.dart';
import '../state/jobs_controller.dart';
import '../widgets/status_chip.dart';
import 'job_detail_screen.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JobsController>().load();
    });
  }

  Future<void> _refresh() => context.read<JobsController>().load(showSpinner: false);

  Future<void> _confirmSignOut() async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will need to sign in again to see your jobs.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (shouldSignOut != true || !mounted) return;
    context.read<JobsController>().reset();
    await context.read<AuthController>().signOut();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final jobs = context.watch<JobsController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My jobs'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Signed in as ${auth.helper?.fullName ?? ''}',
                style: const TextStyle(fontSize: 13, color: Colors.white70),
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: _confirmSignOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _buildBody(jobs),
      ),
    );
  }

  Widget _buildBody(JobsController jobs) {
    if (jobs.state == JobsViewState.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (jobs.state == JobsViewState.error) {
      // Still scrollable, so pull-to-refresh works from the error state too.
      return ListView(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: MessageView(
              icon: Icons.cloud_off,
              title: 'Could not load your jobs',
              message: jobs.errorMessage,
              onRetry: () => jobs.load(),
            ),
          ),
        ],
      );
    }

    if (jobs.isEmpty) {
      return ListView(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: MessageView(
              icon: Icons.event_available,
              title: 'No jobs assigned yet',
              message: 'Pull down to refresh once your coordinator assigns a job.',
              onRetry: () => jobs.load(),
              retryLabel: 'Refresh',
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      itemCount: jobs.jobs.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _JobCard(job: jobs.jobs[index]),
    );
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({required this.job});

  final Job job;

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('d MMM, h:mm a').format(job.scheduledFor);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => JobDetailScreen(jobId: job.id)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      job.title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusChip(status: job.status),
                ],
              ),
              const SizedBox(height: 10),
              _IconLine(icon: Icons.person_outline, text: job.customerName),
              const SizedBox(height: 4),
              _IconLine(icon: Icons.schedule, text: time),
              const SizedBox(height: 4),
              _IconLine(icon: Icons.place_outlined, text: job.address, maxLines: 1),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconLine extends StatelessWidget {
  const _IconLine({required this.icon, required this.text, this.maxLines = 2});

  final IconData icon;
  final String text;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
