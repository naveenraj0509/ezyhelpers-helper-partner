import 'package:flutter/material.dart';

import '../models/job.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final JobStatus status;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (status) {
      JobStatus.assigned => (const Color(0xFFE3F2FD), const Color(0xFF0D47A1)),
      JobStatus.inProgress => (const Color(0xFFFFF3E0), const Color(0xFFE65100)),
      JobStatus.completed => (const Color(0xFFE8F5E9), const Color(0xFF1B5E20)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(color: foreground, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}

/// Shared empty/error placeholder so every screen fails the same way.
class MessageView extends StatelessWidget {
  const MessageView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.onRetry,
    this.retryLabel = 'Try again',
  });

  final IconData icon;
  final String title;
  final String? message;
  final VoidCallback? onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              FilledButton.tonalIcon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(retryLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
