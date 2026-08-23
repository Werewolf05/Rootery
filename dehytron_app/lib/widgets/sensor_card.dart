import 'package:flutter/material.dart';
import '../theme/rootery_theme.dart';

enum SensorStatus { optimal, warning, alert }

class SensorCard extends StatefulWidget {
  final String label;
  final double value;
  final String unit;
  final SensorStatus status;
  final double minVal;
  final double maxVal;
  final IconData? icon;

  const SensorCard({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.status,
    required this.minVal,
    required this.maxVal,
    this.icon,
  });

  @override
  State<SensorCard> createState() => _SensorCardState();
}

class _SensorCardState extends State<SensorCard> {
  double _scale = 1;

  Color _statusColor() {
    switch (widget.status) {
      case SensorStatus.optimal:
        return RooteryTheme.green400;
      case SensorStatus.warning:
        return RooteryTheme.amberWarn;
      case SensorStatus.alert:
        return RooteryTheme.redAlert;
    }
  }

  Color _statusBg() {
    switch (widget.status) {
      case SensorStatus.optimal:
        return RooteryTheme.bgSurface;
      case SensorStatus.warning:
        return RooteryTheme.amber50;
      case SensorStatus.alert:
        return RooteryTheme.red50;
    }
  }

  String _statusText() {
    switch (widget.status) {
      case SensorStatus.optimal:
        return 'Optimal range';
      case SensorStatus.warning:
        return 'Needs attention';
      case SensorStatus.alert:
        return 'Action required';
    }
  }

  double _progress() {
    final span = (widget.maxVal - widget.minVal).abs() < 0.0001
        ? 1
        : (widget.maxVal - widget.minVal);
    final normalized = (widget.value - widget.minVal) / span;
    if (normalized < 0) return 0;
    if (normalized > 1) return 1;
    return normalized;
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor();
    final display = widget.value.toStringAsFixed(widget.unit == 'ppm' ? 0 : 1);

    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.97),
      onTapCancel: () => setState(() => _scale = 1),
      onTapUp: (_) => setState(() => _scale = 1),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _statusBg(),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: RooteryTheme.borderLight),
            boxShadow: const [RooteryTheme.cardShadow],
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: double.infinity,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (widget.icon != null)
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: RooteryTheme.bgSubtle,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              widget.icon,
                              size: 16,
                              color: RooteryTheme.textMid,
                            ),
                          ),
                        if (widget.icon != null) const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.label,
                            style: RooteryTheme.ui(
                              13,
                              weight: FontWeight.w500,
                              color: RooteryTheme.textMid,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, anim) => FadeTransition(
                            opacity: anim,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, -0.3),
                                end: Offset.zero,
                              ).animate(anim),
                              child: child,
                            ),
                          ),
                          child: Text(
                            display,
                            key: ValueKey(display),
                            style: RooteryTheme.mono(
                              28,
                              weight: FontWeight.w700,
                              color: widget.status == SensorStatus.optimal
                                  ? RooteryTheme.green600
                                  : color,
                            ),
                          ),
                        ),
                        if (widget.unit.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Text(
                              widget.unit,
                              style: RooteryTheme.mono(
                                11,
                                color: RooteryTheme.textLow,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _statusText(),
                      style: RooteryTheme.ui(
                        11,
                        weight: FontWeight.w400,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _AnimatedProgressBar(value: _progress()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedProgressBar extends StatelessWidget {
  const _AnimatedProgressBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutExpo,
      tween: Tween<double>(begin: 0, end: value),
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
    );
  }
}

