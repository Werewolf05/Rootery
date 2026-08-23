import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../services/analytics_service.dart';
import '../theme/rootery_theme.dart';

class AnalyticsChart extends StatelessWidget {
  final String title;
  final List<TrendPoint> points;
  final Color lineColor;
  final String unit;
  final AnalyticsPeriod period;

  const AnalyticsChart({
    super.key,
    required this.title,
    required this.points,
    required this.lineColor,
    required this.unit,
    required this.period,
  });

  String _formatLabel(DateTime t) {
    switch (period) {
      case AnalyticsPeriod.day:
        return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
      case AnalyticsPeriod.week:
      case AnalyticsPeriod.month:
        return '${t.month}/${t.day}';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: RooteryTheme.cardDecoration(radius: RooteryTheme.radiusXL),
        child: Text(
          'No telemetry points available yet.',
          style: RooteryTheme.ui(14, color: RooteryTheme.textMid),
        ),
      );
    }

    final spots = <FlSpot>[];
    for (var i = 0; i < points.length; i++) {
      spots.add(FlSpot(i.toDouble(), points[i].value));
    }

    final minY = points.map((p) => p.value).reduce((a, b) => a < b ? a : b);
    final maxY = points.map((p) => p.value).reduce((a, b) => a > b ? a : b);
    final pad = ((maxY - minY) * 0.15).clamp(0.1, 1000);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: RooteryTheme.cardDecoration(radius: RooteryTheme.radiusXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: RooteryTheme.ui(
              13,
              weight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (spots.length - 1).toDouble(),
                minY: minY - pad,
                maxY: maxY + pad,
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: ((maxY - minY) / 4).clamp(0.5, 500),
                  getDrawingHorizontalLine: (value) => const FlLine(
                    color: RooteryTheme.borderLight,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: (spots.length / 4).clamp(1, 20).toDouble(),
                      reservedSize: 24,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= points.length) {
                          return const SizedBox.shrink();
                        }
                        final t = points[idx].timestamp;
                        final label = _formatLabel(t);
                        return Text(
                          label,
                          style: RooteryTheme.mono(
                            10,
                            color: RooteryTheme.textLow,
                            letterSpacing: 0.8,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      interval: ((maxY - minY) / 4).clamp(0.5, 500),
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toStringAsFixed(1)}$unit',
                          style: RooteryTheme.mono(
                            10,
                            color: RooteryTheme.textLow,
                            letterSpacing: 0.8,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: lineColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: RooteryTheme.green50,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
