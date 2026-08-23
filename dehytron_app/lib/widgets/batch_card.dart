import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../theme/rootery_theme.dart';
import 'status_badge.dart';

class BatchCard extends StatefulWidget {
  final HydroBatch batch;
  final VoidCallback? onDelete;

  const BatchCard({super.key, required this.batch, this.onDelete});

  @override
  State<BatchCard> createState() => _BatchCardState();
}

class _BatchCardState extends State<BatchCard> {
  double _scale = 1;

  BadgeStatus _badgeStatus(BatchStatus status) {
    switch (status) {
      case BatchStatus.active:
        return BadgeStatus.online;
      case BatchStatus.upcoming:
        return BadgeStatus.warning;
      case BatchStatus.completed:
        return BadgeStatus.offline;
    }
  }

  String _statusLabel(BatchStatus status) {
    switch (status) {
      case BatchStatus.active:
        return 'GROWING';
      case BatchStatus.upcoming:
        return 'SEEDING';
      case BatchStatus.completed:
        return 'READY';
    }
  }

  Color _statusColor(BatchStatus status) {
    switch (status) {
      case BatchStatus.active:
        return RooteryTheme.green400;
      case BatchStatus.upcoming:
        return RooteryTheme.textLow;
      case BatchStatus.completed:
        return RooteryTheme.blueInfo;
    }
  }

  @override
  Widget build(BuildContext context) {
    final batch = widget.batch;
    final now = DateTime.now();
    final daysRemaining = batch.expectedHarvestDate.difference(now).inDays;
    final elapsed = batch.growthDurationDays - daysRemaining;
    final elapsedClamped = elapsed.clamp(0, batch.growthDurationDays).toDouble();
    final progressTarget =
        batch.growthDurationDays == 0 ? 0.0 : elapsedClamped / batch.growthDurationDays;

    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.97),
      onTapCancel: () => setState(() => _scale = 1),
      onTapUp: (_) => setState(() => _scale = 1),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Opacity(
          opacity: batch.status == BatchStatus.completed ? 0.6 : 1,
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: RooteryTheme.bgSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: RooteryTheme.borderLight),
              boxShadow: const [RooteryTheme.cardShadow],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        batch.batchName,
                        style: RooteryTheme.ui(16, weight: FontWeight.w600),
                      ),
                    ),
                    if (widget.onDelete != null)
                      IconButton(
                        tooltip: 'Remove batch',
                        onPressed: widget.onDelete,
                        icon: const Icon(
                          Icons.delete_outline,
                          color: RooteryTheme.redAlert,
                        ),
                      ),
                    StatusBadge(
                      status: _badgeStatus(batch.status),
                      label: _statusLabel(batch.status),
                      showDot: false,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Crop: ${batch.cropType.name.toUpperCase()}',
                  style: RooteryTheme.ui(12, color: RooteryTheme.textMid),
                ),
                const SizedBox(height: 2),
                Text(
                  'Row: A${batch.id.hashCode.abs() % 12 + 1}',
                  style: RooteryTheme.ui(11, color: RooteryTheme.textLow),
                ),
                const SizedBox(height: 12),
                Text(
                  'CYCLE PROGRESS',
                  style: RooteryTheme.mono(
                    11,
                    color: RooteryTheme.textLow,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: progressTarget),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutExpo,
                  builder: (context, anim, child) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        minHeight: 6,
                        value: anim,
                        backgroundColor: RooteryTheme.green50,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          RooteryTheme.green400,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '${elapsedClamped.toInt()} / ${batch.growthDurationDays} days',
                      style: RooteryTheme.mono(12, color: RooteryTheme.textMid),
                    ),
                    const Spacer(),
                    Text(
                      daysRemaining <= 0 ? 'Harvest ready' : 'Harvest in ${daysRemaining}d',
                      style: RooteryTheme.mono(
                        12,
                        color: daysRemaining <= 2
                            ? RooteryTheme.amberWarn
                            : RooteryTheme.textMid,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Status progress: ${widget.batch.progressPercentage.toStringAsFixed(0)}%',
                  style: RooteryTheme.ui(
                    11,
                    color: _statusColor(widget.batch.status),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

