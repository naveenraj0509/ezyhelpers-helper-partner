import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/job.dart';
import 'glass.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final JobStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      JobStatus.assigned => AppColors.sky,
      JobStatus.inProgress => AppColors.warning,
      JobStatus.completed => AppColors.success,
    };

    return GlassContainer(
      radius: 20,
      blur: 10,
      shadow: false,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 5)],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: const TextStyle(
              color: AppColors.ink,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
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
        padding: const EdgeInsets.all(28),
        child: GlassContainer(
          radius: 32,
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.9),
                      Colors.white.withValues(alpha: 0.35),
                    ],
                  ),
                  border: Border.all(color: Colors.white),
                ),
                child: Icon(icon, size: 38, color: AppColors.ink),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              if (message != null) ...[
                const SizedBox(height: 8),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.inkSoft, height: 1.4),
                ),
              ],
              if (onRetry != null) ...[
                const SizedBox(height: 22),
                GlassTextButton(label: retryLabel, icon: Icons.refresh, onPressed: onRetry),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
