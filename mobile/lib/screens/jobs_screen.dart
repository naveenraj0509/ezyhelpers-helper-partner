import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../models/job.dart';
import '../state/auth_controller.dart';
import '../state/jobs_controller.dart';
import '../widgets/glass.dart';
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
    final shouldSignOut = await showGlassConfirm(
      context,
      title: 'Sign out?',
      message: 'You will need to sign in again to see your jobs.',
      confirmLabel: 'Sign out',
      confirmColor: AppColors.danger,
    );

    if (shouldSignOut != true || !mounted) return;
    context.read<JobsController>().reset();
    await context.read<AuthController>().signOut();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final jobs = context.watch<JobsController>();

    return GlassScaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 16, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, ${_firstName(auth.helper?.fullName)}',
                          style: const TextStyle(color: AppColors.inkSoft, fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'My jobs',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GlassIconButton(icon: Icons.refresh_rounded, tooltip: 'Refresh', onPressed: _refresh),
                  const SizedBox(width: 10),
                  GlassIconButton(
                    icon: Icons.logout_rounded,
                    tooltip: 'Sign out',
                    iconColor: AppColors.ink,
                    onPressed: _confirmSignOut,
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                backgroundColor: Colors.white,
                child: _buildBody(jobs),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _firstName(String? fullName) {
    final name = (fullName ?? '').trim();
    return name.isEmpty ? 'there' : name.split(' ').first;
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: jobs.jobs.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
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

    return GlassTappable(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => JobDetailScreen(jobId: job.id)),
      ),
      child: GlassContainer(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    job.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                StatusChip(status: job.status),
              ],
            ),
            const SizedBox(height: 14),
            _IconLine(icon: Icons.person_outline_rounded, text: job.customerName),
            const SizedBox(height: 8),
            _IconLine(icon: Icons.schedule_rounded, text: time),
            const SizedBox(height: 8),
            _IconLine(icon: Icons.place_outlined, text: job.address, maxLines: 1),
          ],
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 17, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.inkSoft, fontSize: 14),
          ),
        ),
      ],
    );
  }
}
