import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../models/app_models.dart';
import '../../services/analytics_service.dart';
import '../../services/data_service.dart';
import '../../services/telemetry_service.dart';
import '../../theme/rootery_theme.dart';
import '../../widgets/analytics_chart.dart';
import '../../widgets/app_footer.dart';
import '../../widgets/loading_skeleton.dart';

class HydroSensorsScreen extends StatefulWidget {
  const HydroSensorsScreen({super.key});

  @override
  State<HydroSensorsScreen> createState() => _HydroSensorsScreenState();
}

class _HydroSensorsScreenState extends State<HydroSensorsScreen>
    with SingleTickerProviderStateMixin {
  final AnalyticsService _analyticsService = AnalyticsService();
  final DataService _dataService = DataService();

  AnalyticsPeriod _period = AnalyticsPeriod.day;
  List<SensorData> _series = [];
  List<SystemAlert> _alerts = [];
  bool _loading = true;
  TelemetryConnectionInfo _telemetryStatus = const TelemetryConnectionInfo(
    state: TelemetryConnectionState.connecting,
    message: 'Connecting telemetry...',
  );
  StreamSubscription<List<SystemAlert>>? _alertsSub;
  StreamSubscription<SensorData>? _sensorSub;
  StreamSubscription<TelemetryConnectionInfo>? _telemetryStatusSub;

  late final AnimationController _enterCtrl;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOutCubic));
    _fadeAnim = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut);
    _enterCtrl.forward();

    _alerts = _dataService.currentAlerts;
    _alertsSub = _dataService.alertsStream.listen((a) {
      if (!mounted) return;
      setState(() => _alerts = a);
    });
    _sensorSub = _dataService.sensorDataStream.listen((sensor) {
      if (!mounted) return;
      final window = _period == AnalyticsPeriod.day
          ? const Duration(days: 1)
          : _period == AnalyticsPeriod.week
          ? const Duration(days: 7)
          : const Duration(days: 30);
      final cutoff = DateTime.now().subtract(window);
      setState(() {
        final merged = [
          ..._series,
          sensor,
        ].where((s) => s.lastUpdate.isAfter(cutoff)).toList();
        final deduped = <String, SensorData>{};
        for (final item in merged) {
          final key =
              '${item.deviceId}_${item.lastUpdate.toIso8601String()}_${item.phLevel.toStringAsFixed(2)}_${item.tdsLevel.toStringAsFixed(0)}';
          final existing = deduped[key];
          if (existing == null ||
              item.lastUpdate.isAfter(existing.lastUpdate)) {
            deduped[key] = item;
          }
        }
        _series = deduped.values.toList()
          ..sort((a, b) => a.lastUpdate.compareTo(b.lastUpdate));
      });
    });
    _telemetryStatus = _dataService.currentTelemetryStatus;
    _telemetryStatusSub = _dataService.telemetryStatusStream.listen((status) {
      if (!mounted) return;
      setState(() => _telemetryStatus = status);
    });
    _loadSeries();
  }

  @override
  void dispose() {
    _alertsSub?.cancel();
    _sensorSub?.cancel();
    _telemetryStatusSub?.cancel();
    _enterCtrl.dispose();
    super.dispose();
  }

  Color _statusColor() {
    switch (_telemetryStatus.state) {
      case TelemetryConnectionState.connected:
        return RooteryTheme.green600;
      case TelemetryConnectionState.reconnecting:
        return RooteryTheme.amberWarn;
      case TelemetryConnectionState.offline:
      case TelemetryConnectionState.error:
        return RooteryTheme.redAlert;
      case TelemetryConnectionState.connecting:
        return RooteryTheme.blueInfo;
    }
  }

  Widget _connectionStatusBanner() {
    final retry = _telemetryStatus.retryInSeconds;
    final suffix = retry == null ? '' : ' Retry in ${retry}s';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: RooteryTheme.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: RooteryTheme.borderLight),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_tethering, size: 18, color: _statusColor()),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${_telemetryStatus.message}$suffix',
              style: RooteryTheme.ui(13, color: RooteryTheme.textMid),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadSeries() async {
    setState(() => _loading = true);
    final rows = await _analyticsService.getSeries(_period);
    if (!mounted) return;
    setState(() {
      _series = rows;
      _loading = false;
    });
  }

  Widget _sectionHeader(String title, {String? trailing}) {
    return Row(
      children: [
        Text(
          title.toUpperCase(),
          style: RooteryTheme.ui(
            13,
            weight: FontWeight.w500,
            color: RooteryTheme.textMid,
            letterSpacing: 0.3,
          ),
        ),
        const Spacer(),
        if (trailing != null)
          Text(
            trailing,
            style: RooteryTheme.mono(
              11,
              color: RooteryTheme.textLow,
              letterSpacing: 0.8,
            ),
          ),
      ],
    );
  }

  Widget _buildSummaryCard(String label, MetricSummary s, String unit) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: RooteryTheme.cardDecoration(radius: 20),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: RooteryTheme.ui(
              11,
              weight: FontWeight.w400,
              color: RooteryTheme.textMid,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${s.average.toStringAsFixed(1)}$unit',
            style: RooteryTheme.mono(22, weight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            'Max ${s.max.toStringAsFixed(1)}$unit',
            style: RooteryTheme.ui(13, color: RooteryTheme.textMid),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            'Min ${s.min.toStringAsFixed(1)}$unit',
            style: RooteryTheme.ui(13, color: RooteryTheme.textMid),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        LoadingSkeleton.text(width: 140, height: 14),
        SizedBox(height: 8),
        LoadingSkeleton.card(height: 56),
        SizedBox(height: 12),
        LoadingSkeleton.card(height: 220),
        SizedBox(height: 12),
        LoadingSkeleton.card(height: 220),
        SizedBox(height: 12),
        LoadingSkeleton.card(height: 220),
        SizedBox(height: 12),
        LoadingSkeleton.card(height: 220),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final ph = _analyticsService.summarize(
      _series.map((e) => e.phLevel).toList(),
    );
    final tds = _analyticsService.summarize(
      _series.map((e) => e.tdsLevel).toList(),
    );
    final temp = _analyticsService.summarize(
      _series.map((e) => e.airTemperature).toList(),
    );
    final humidity = _analyticsService.summarize(
      _series.map((e) => e.airHumidity).toList(),
    );

    return Scaffold(
      backgroundColor: RooteryTheme.bgScaffold,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: RooteryTheme.bgSurface,
        title: Text(
          'Sensors & Insights',
          style: RooteryTheme.ui(22, weight: FontWeight.w600),
        ),
      ),
      body: _loading
          ? _buildLoadingState()
          : FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: RefreshIndicator(
                  color: RooteryTheme.green400,
                  onRefresh: _loadSeries,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _connectionStatusBanner(),
                      _sectionHeader('Time Window'),
                      const SizedBox(height: 8),
                      SegmentedButton<AnalyticsPeriod>(
                        style: ButtonStyle(
                          side: const MaterialStatePropertyAll(
                            BorderSide(color: RooteryTheme.borderLight),
                          ),
                          backgroundColor: MaterialStateProperty.resolveWith((
                            states,
                          ) {
                            if (states.contains(MaterialState.selected)) {
                              return RooteryTheme.green400;
                            }
                            return RooteryTheme.bgSurface;
                          }),
                          foregroundColor: MaterialStateProperty.resolveWith((
                            states,
                          ) {
                            if (states.contains(MaterialState.selected)) {
                              return RooteryTheme.bgSurface;
                            }
                            return RooteryTheme.textMid;
                          }),
                          textStyle: MaterialStatePropertyAll(
                            RooteryTheme.ui(14, weight: FontWeight.w500),
                          ),
                        ),
                        segments: const [
                          ButtonSegment(
                            value: AnalyticsPeriod.day,
                            label: Text('Day'),
                          ),
                          ButtonSegment(
                            value: AnalyticsPeriod.week,
                            label: Text('Week'),
                          ),
                          ButtonSegment(
                            value: AnalyticsPeriod.month,
                            label: Text('Month'),
                          ),
                        ],
                        selected: {_period},
                        onSelectionChanged: (value) {
                          setState(() => _period = value.first);
                          _loadSeries();
                        },
                      ),
                      const SizedBox(height: 14),
                      _sectionHeader('Trends', trailing: 'Live telemetry'),
                      const SizedBox(height: 10),
                      AnalyticsChart(
                        title: 'pH Level Trend',
                        points: _analyticsService.phTrend(_series),
                        lineColor: RooteryTheme.green400,
                        unit: '',
                        period: _period,
                      ),
                      const SizedBox(height: 12),
                      AnalyticsChart(
                        title: 'TDS Trend',
                        points: _analyticsService.tdsTrend(_series),
                        lineColor: RooteryTheme.green400,
                        unit: 'ppm',
                        period: _period,
                      ),
                      const SizedBox(height: 12),
                      AnalyticsChart(
                        title: 'Temperature Trend',
                        points: _analyticsService.tempTrend(_series),
                        lineColor: RooteryTheme.green400,
                        unit: 'C',
                        period: _period,
                      ),
                      const SizedBox(height: 12),
                      AnalyticsChart(
                        title: 'Humidity Trend',
                        points: _analyticsService.humidityTrend(_series),
                        lineColor: RooteryTheme.green400,
                        unit: '%',
                        period: _period,
                      ),
                      const SizedBox(height: 12),
                      _sectionHeader('Summary'),
                      const SizedBox(height: 8),
                      AnimationLimiter(
                        child: GridView.count(
                          crossAxisCount:
                              MediaQuery.of(context).size.width > 900 ? 4 : 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.25,
                          children: [
                            _buildSummaryCard('pH', ph, ''),
                            _buildSummaryCard('TDS', tds, ' ppm'),
                            _buildSummaryCard('Temp', temp, ' C'),
                            _buildSummaryCard('Humidity', humidity, '%'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _sectionHeader('Sensor Insights'),
                      const SizedBox(height: 8),
                      if (_alerts.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: RooteryTheme.cardDecoration(radius: 20),
                          child: Text(
                            'No active alerts. System readings are within expected ranges.',
                            style: RooteryTheme.ui(
                              14,
                              color: RooteryTheme.textMid,
                            ),
                          ),
                        ),
                      ..._alerts.asMap().entries.map((entry) {
                        final index = entry.key;
                        final alert = entry.value;
                        final color = alert.severity == AlertSeverity.critical
                            ? RooteryTheme.redAlert
                            : (alert.severity == AlertSeverity.warning
                                  ? RooteryTheme.amberWarn
                                  : RooteryTheme.blueInfo);
                        final bg = alert.severity == AlertSeverity.critical
                            ? RooteryTheme.red50
                            : (alert.severity == AlertSeverity.warning
                                  ? RooteryTheme.amber50
                                  : RooteryTheme.green50);
                        return AnimationConfiguration.staggeredList(
                          position: index,
                          delay: const Duration(milliseconds: 60),
                          child: SlideAnimation(
                            verticalOffset: 16,
                            child: FadeInAnimation(
                              child: Container(
                                margin: const EdgeInsets.only(top: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: bg,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: RooteryTheme.borderLight,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 52,
                                      margin: const EdgeInsets.only(right: 10),
                                      decoration: BoxDecoration(
                                        color: color,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            alert.title,
                                            style: RooteryTheme.ui(
                                              14,
                                              color: color,
                                              weight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            alert.message,
                                            style: RooteryTheme.ui(14),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            alert.suggestion,
                                            style: RooteryTheme.ui(
                                              11,
                                              color: RooteryTheme.textMid,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                      const AppFooter(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
