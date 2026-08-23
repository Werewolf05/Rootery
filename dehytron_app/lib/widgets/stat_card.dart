import 'package:flutter/material.dart';
import '../theme/rootery_theme.dart';

class StatCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? unit;
  final String? trend;
  final Color color;
  final bool isTrendPositive;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.unit,
    this.trend,
    required this.color,
    this.isTrendPositive = true,
    this.onTap,
  });

  @override
  State<StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<StatCard> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    final number = double.tryParse(widget.value.replaceAll(RegExp(r'[^0-9.]'), ''));

    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.97),
      onTapCancel: () => setState(() => _scale = 1),
      onTapUp: (_) => setState(() => _scale = 1),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
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
                  Icon(widget.icon, size: 16, color: widget.color),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.label.toUpperCase(),
                      style: RooteryTheme.ui(
                        13,
                        weight: FontWeight.w500,
                        color: RooteryTheme.textMid,
                        letterSpacing: 0.3,
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
                  Expanded(
                    child: number == null
                        ? Text(
                            widget.value,
                            style: RooteryTheme.ui(22, weight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        : TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0, end: number),
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.easeOutExpo,
                            builder: (context, anim, child) {
                              final text = widget.value.contains('%')
                                  ? '${anim.toStringAsFixed(1)}%'
                                  : anim.toStringAsFixed(number >= 100 ? 0 : 1);
                              return Text(
                                text,
                                style: RooteryTheme.ui(22, weight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              );
                            },
                          ),
                  ),
                  if (widget.unit != null)
                    Text(
                      widget.unit!,
                      style: RooteryTheme.mono(
                        11,
                        color: RooteryTheme.textLow,
                        letterSpacing: 0.8,
                      ),
                    ),
                ],
              ),
              if (widget.trend != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      widget.isTrendPositive ? '^' : 'v',
                      style: RooteryTheme.ui(
                        11,
                        weight: FontWeight.w500,
                        color: widget.isTrendPositive
                            ? RooteryTheme.green400
                            : RooteryTheme.redAlert,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.trend!,
                      style: RooteryTheme.ui(
                        11,
                        weight: FontWeight.w500,
                        color: widget.isTrendPositive
                            ? RooteryTheme.green400
                            : RooteryTheme.redAlert,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

