import 'package:flutter/material.dart';
import '../theme/rootery_theme.dart';

enum BadgeStatus { online, offline, success, warning, error, active }

class StatusBadge extends StatelessWidget {
  final BadgeStatus status;
  final String? label;
  final bool showDot;
  final bool pulsing;

  const StatusBadge({
    super.key,
    required this.status,
    this.label,
    this.showDot = true,
    this.pulsing = false,
  });

  ({Color bg, Color border, Color text}) _tone() {
    switch (status) {
      case BadgeStatus.online:
      case BadgeStatus.success:
      case BadgeStatus.active:
        return (
          bg: RooteryTheme.green50,
          border: RooteryTheme.green100,
          text: RooteryTheme.green600,
        );
      case BadgeStatus.warning:
        return (
          bg: RooteryTheme.amber50,
          border: RooteryTheme.amber100,
          text: RooteryTheme.amberWarn,
        );
      case BadgeStatus.offline:
      case BadgeStatus.error:
        return (
          bg: RooteryTheme.red50,
          border: RooteryTheme.red100,
          text: RooteryTheme.redAlert,
        );
    }
  }

  String _getLabel() {
    if (label != null) return label!;
    switch (status) {
      case BadgeStatus.online:
      case BadgeStatus.success:
      case BadgeStatus.active:
        return 'ONLINE';
      case BadgeStatus.warning:
        return 'WARNING';
      case BadgeStatus.offline:
      case BadgeStatus.error:
        return 'OFFLINE';
    }
  }

  @override
  Widget build(BuildContext context) {
    final tone = _tone();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: tone.bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tone.border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            _buildDot(tone.text),
            const SizedBox(width: 6),
          ],
          Text(
            _getLabel(),
            style: RooteryTheme.ui(
              11,
              weight: FontWeight.w500,
              color: tone.text,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(Color color) {
    if (!pulsing) {
      return Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.7, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

