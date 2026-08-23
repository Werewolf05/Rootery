import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/rootery_theme.dart';

class LoadingSkeleton extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const LoadingSkeleton({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius,
  });

  const LoadingSkeleton.card({
    super.key,
    this.width = double.infinity,
    this.height = 120,
  }) : borderRadius = const BorderRadius.all(
         Radius.circular(RooteryTheme.radiusLG),
       );

  const LoadingSkeleton.text({super.key, this.width = 100, this.height = 14})
    : borderRadius = const BorderRadius.all(Radius.circular(4));

  const LoadingSkeleton.circle({super.key, required double size})
    : width = size,
      height = size,
      borderRadius = null;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: RooteryTheme.card,
      highlightColor: RooteryTheme.cardHover,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: RooteryTheme.card,
          shape: borderRadius == null && width == height
              ? BoxShape.circle
              : BoxShape.rectangle,
          borderRadius: borderRadius == null && width == height
              ? null
              : (borderRadius ?? BorderRadius.circular(RooteryTheme.radiusSM)),
        ),
      ),
    );
  }
}

class SensorCardSkeleton extends StatelessWidget {
  const SensorCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: RooteryTheme.card,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RooteryTheme.radiusMD),
      ),
      child: Padding(
        padding: EdgeInsets.all(RooteryTheme.spaceLG),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LoadingSkeleton.circle(size: 32),
            SizedBox(height: RooteryTheme.spaceMD),
            LoadingSkeleton.text(width: 60, height: 12),
            SizedBox(height: RooteryTheme.spaceXS),
            LoadingSkeleton.text(width: 40, height: 24),
          ],
        ),
      ),
    );
  }
}

class ProgressCardSkeleton extends StatelessWidget {
  const ProgressCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: RooteryTheme.card,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RooteryTheme.radiusLG),
      ),
      child: Padding(
        padding: EdgeInsets.all(RooteryTheme.spaceXL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                LoadingSkeleton.text(width: 120, height: 18),
                LoadingSkeleton.text(width: 60, height: 32),
              ],
            ),
            SizedBox(height: RooteryTheme.spaceLG),
            LoadingSkeleton(
              width: double.infinity,
              height: 10,
              borderRadius: BorderRadius.circular(RooteryTheme.radiusSM),
            ),
            SizedBox(height: RooteryTheme.spaceLG),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                LoadingSkeleton.text(width: 80),
                LoadingSkeleton.text(width: 60),
                LoadingSkeleton.text(width: 70),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

