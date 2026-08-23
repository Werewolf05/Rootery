import 'package:flutter/material.dart';
import '../theme/rootery_theme.dart';

class ControlSwitchTile extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final bool busy;
  final ValueChanged<bool> onChanged;
  final DateTime? lastActivatedAt;

  const ControlSwitchTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.busy,
    required this.onChanged,
    this.lastActivatedAt,
  });

  @override
  State<ControlSwitchTile> createState() => _ControlSwitchTileState();
}

class _ControlSwitchTileState extends State<ControlSwitchTile> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    final last = widget.lastActivatedAt == null
        ? 'Never'
        : '${widget.lastActivatedAt!.hour.toString().padLeft(2, '0')}:${widget.lastActivatedAt!.minute.toString().padLeft(2, '0')}';

    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.97),
      onTapCancel: () => setState(() => _scale = 1),
      onTapUp: (_) => setState(() => _scale = 1),
      onTap: widget.busy ? null : () => widget.onChanged(!widget.value),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.only(bottom: RooteryTheme.cardGap),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: widget.value ? RooteryTheme.green50 : RooteryTheme.bgSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.value
                  ? RooteryTheme.green400
                  : RooteryTheme.borderLight,
            ),
            boxShadow: const [RooteryTheme.cardShadow],
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 58,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: widget.value
                      ? RooteryTheme.green400
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: RooteryTheme.bgSubtle,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.icon, color: RooteryTheme.textMid, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: RooteryTheme.ui(14, weight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.subtitle} | Last: $last',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: RooteryTheme.ui(11, color: RooteryTheme.textLow),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (widget.busy)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                _ElasticToggle(value: widget.value),
            ],
          ),
        ),
      ),
    );
  }
}

class _ElasticToggle extends StatelessWidget {
  const _ElasticToggle({required this.value});

  final bool value;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      width: 52,
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: value ? RooteryTheme.green400 : RooteryTheme.borderLight,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 300),
            curve: Curves.elasticOut,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

