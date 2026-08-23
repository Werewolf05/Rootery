import 'package:flutter/material.dart';
import '../theme/rootery_theme.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(RooteryTheme.space2XL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: RooteryTheme.card,
                shape: BoxShape.circle,
                border: Border.all(
                  color: RooteryTheme.accentGreen.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                icon,
                size: 56,
                color: RooteryTheme.accentGreen.withOpacity(0.5),
              ),
            ),
            SizedBox(height: RooteryTheme.spaceXL),
            Text(
              title,
              style: RooteryTheme.heading3,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: RooteryTheme.spaceMD),
            Text(
              message,
              style: RooteryTheme.bodyMedium.copyWith(
                color: RooteryTheme.subText,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: RooteryTheme.spaceXL),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(actionLabel!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: RooteryTheme.accentGreen,
                  padding: EdgeInsets.symmetric(
                    horizontal: RooteryTheme.spaceXL,
                    vertical: RooteryTheme.spaceLG,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

