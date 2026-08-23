import 'package:flutter/material.dart';

import '../theme/rootery_theme.dart';

class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < 560;
    final text = isCompact
        ? '@DST, Govt. of India. All rights reserved.'
        : '@Department of Science and Technology, Govt. of India. All rights reserved.';

    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 12),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: RooteryTheme.ui(
          isCompact ? 11 : 12,
          color: RooteryTheme.textMid,
          weight: FontWeight.w500,
        ),
      ),
    );
  }
}
