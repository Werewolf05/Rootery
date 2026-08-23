import '../models/app_models.dart';
import 'telemetry_service.dart';

enum AnalyticsPeriod { day, week, month }

class TrendPoint {
  final DateTime timestamp;
  final double value;

  const TrendPoint({required this.timestamp, required this.value});
}

class MetricSummary {
  final double average;
  final double min;
  final double max;

  const MetricSummary({
    required this.average,
    required this.min,
    required this.max,
  });
}

class AnalyticsService {
  final TelemetryService _telemetryService = TelemetryService();

  Duration _periodToDuration(AnalyticsPeriod period) {
    switch (period) {
      case AnalyticsPeriod.day:
        return const Duration(days: 1);
      case AnalyticsPeriod.week:
        return const Duration(days: 7);
      case AnalyticsPeriod.month:
        return const Duration(days: 30);
    }
  }

  Future<List<SensorData>> getSeries(AnalyticsPeriod period) {
    return _telemetryService.getSensorSeries(period: _periodToDuration(period));
  }

  List<TrendPoint> phTrend(List<SensorData> series) {
    return series
        .map((s) => TrendPoint(timestamp: s.lastUpdate, value: s.phLevel))
        .toList();
  }

  List<TrendPoint> tdsTrend(List<SensorData> series) {
    return series
        .map((s) => TrendPoint(timestamp: s.lastUpdate, value: s.tdsLevel))
        .toList();
  }

  List<TrendPoint> tempTrend(List<SensorData> series) {
    return series
        .map(
          (s) => TrendPoint(timestamp: s.lastUpdate, value: s.airTemperature),
        )
        .toList();
  }

  List<TrendPoint> humidityTrend(List<SensorData> series) {
    return series
        .map((s) => TrendPoint(timestamp: s.lastUpdate, value: s.airHumidity))
        .toList();
  }

  MetricSummary summarize(List<double> values) {
    if (values.isEmpty) {
      return const MetricSummary(average: 0, min: 0, max: 0);
    }

    final sum = values.fold<double>(0, (prev, current) => prev + current);
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);

    return MetricSummary(average: sum / values.length, min: min, max: max);
  }
}
