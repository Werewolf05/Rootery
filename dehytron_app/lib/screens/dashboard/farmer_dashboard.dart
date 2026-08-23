import 'package:flutter/material.dart';
import 'dart:async';
import '../../theme/rootery_theme.dart';
import '../../services/data_service.dart';
import '../../services/telemetry_service.dart';
import '../../models/app_models.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_skeleton.dart';
import '../../widgets/stat_card.dart';

class FarmerDashboard extends StatefulWidget {
  const FarmerDashboard({super.key});

  @override
  State<FarmerDashboard> createState() => _FarmerDashboardState();
}

class _FarmerDashboardState extends State<FarmerDashboard> {
  int _selectedNavIndex = 0;
  final DataService _dataService = DataService();
  final TelemetryService _telemetryService = TelemetryService();

  SensorData? _currentSensorData;
  DryingProgress? _currentProgress;
  List<DryingBatch> _recentBatches = [];
  Map<String, dynamic>? _latestTelemetry;
  Timer? _telemetryTimer;
  Timer? _progressUpdateTimer;

  StreamSubscription<SensorData>? _sensorSubscription;
  StreamSubscription<DryingProgress>? _progressSubscription;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _subscribeToStreams();
    _loadTelemetry();
    _subscribeTelemetryRealtime();

    // Fallback polling every 2 seconds for faster updates
    _telemetryTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _loadTelemetry();
    });

    // Update progress card every second for smooth countdown
    _progressUpdateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          // Force rebuild to update remaining time display
        });
      }
    });
  }

  void _loadInitialData() {
    setState(() {
      _currentSensorData = _dataService.currentSensorData;
      _currentProgress = _dataService.currentProgress;
      _recentBatches = _dataService.batches.take(3).toList();
    });
  }

  void _subscribeToStreams() {
    _sensorSubscription = _dataService.sensorDataStream.listen((data) {
      if (mounted) {
        setState(() {
          _currentSensorData = data;
        });
      }
    });

    _progressSubscription = _dataService.progressStream.listen((progress) {
      if (mounted) {
        setState(() {
          _currentProgress = progress;
        });
      }
    });
  }

  @override
  void dispose() {
    _sensorSubscription?.cancel();
    _progressSubscription?.cancel();
    _telemetryTimer?.cancel();
    _progressUpdateTimer?.cancel();
    _telemetryService.unsubscribe();
    super.dispose();
  }

  Future<void> _loadTelemetry() async {
    final telemetry = await _telemetryService.getLatestTelemetry();
    print(
      'ðŸ“Š Telemetry loaded: ${telemetry != null ? "Found ${telemetry.length} fields" : "NULL - No data"}',
    );
    if (telemetry != null) {
      print(
        '   Data: temp=${telemetry['temperature']}, humidity=${telemetry['humidity']}, cycle=${telemetry['cycle_running']}',
      );
    }
    if (mounted && telemetry != null) {
      setState(() {
        _latestTelemetry = telemetry;
      });
    }
  }

  void _subscribeTelemetryRealtime() {
    _telemetryService.subscribeToTelemetry((newData) {
      if (mounted) {
        setState(() {
          _latestTelemetry = newData;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RooteryTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadTelemetry,
                color: RooteryTheme.accentGreen,
                backgroundColor: RooteryTheme.card,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProgressCard(),
                      const SizedBox(height: 20),
                      _buildSensorGrid(),
                      const SizedBox(height: 20),
                      _buildControlButtons(),
                      const SizedBox(height: 24),
                      _buildHistorySection(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF6DD5A0),
            const Color(0xFF9ACD32),
            const Color(0xFF808000),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6DD5A0).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ROOTERY',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      StatusBadge(
                        status: _latestTelemetry == null
                            ? BadgeStatus.offline
                            : (_latestTelemetry!['cycle_running'] == true
                                  ? BadgeStatus.online
                                  : BadgeStatus.warning),
                        pulsing: _latestTelemetry != null,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateTime.now().toString().split('.')[0].substring(11),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/analytics');
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.analytics_outlined,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/profile');
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.person_outline,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.notifications_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    final progress = _currentProgress;
    final telemetry = _latestTelemetry;

    // Get batch info from telemetry if available
    final cycleRunning = telemetry?['cycle_running'] == true;
    final progressPercent = (telemetry?['progress_percent'] ?? 0).toDouble();
    final remainingTimeSec = telemetry?['remaining_seconds']?.toInt() ?? 0;
    final elapsedTimeSec = telemetry?['elapsed_seconds']?.toInt() ?? 0;
    final errorMessage = telemetry?['error_message']?.toString();
    final currentCrop = telemetry?['current_crop']?.toString() ?? 'None';
    final mode = cycleRunning ? 'DRYING' : 'IDLE';

    // Show empty state only if no telemetry at all
    if (telemetry == null) {
      return EmptyState(
        icon: Icons.agriculture_outlined,
        title: 'No Active Cycle',
        message: 'Start a drying cycle from Quick Controls or Advanced Setup',
        actionLabel: 'Start Now',
        onAction: () => Navigator.pushNamed(context, '/manual-control'),
      );
    }

    final dynamic temperatureRaw = telemetry['temperature'];
    final String temperatureDisplay = temperatureRaw is num
        ? temperatureRaw.toStringAsFixed(1)
        : '--';

    // Calculate remaining time display
    String remainingTimeDisplay = '--';
    if (remainingTimeSec != null && remainingTimeSec > 0) {
      final hours = remainingTimeSec ~/ 3600;
      final minutes = (remainingTimeSec % 3600) ~/ 60;
      remainingTimeDisplay = '${hours}h ${minutes}m';
    } else if (progress != null) {
      remainingTimeDisplay = progress.formattedTimeRemaining;
    }

    return Card(
      color: RooteryTheme.card,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Error/Warning banner if exists
            if (errorMessage != null && errorMessage.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        errorMessage,
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: cycleRunning
                                ? RooteryTheme.accentGreen
                                : Colors.orange,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          cycleRunning ? 'Drying Active' : 'Idle',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: cycleRunning
                                ? Colors.green.withOpacity(0.2)
                                : Colors.grey.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            mode.toUpperCase(),
                            style: TextStyle(
                              color: cycleRunning ? Colors.green : Colors.grey,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Crop: $currentCrop',
                      style: const TextStyle(
                        color: RooteryTheme.subText,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${progressPercent.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: RooteryTheme.accentGreen,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progressPercent / 100,
                minHeight: 10,
                backgroundColor: Colors.grey.shade800,
                valueColor: AlwaysStoppedAnimation<Color>(
                  RooteryTheme.accentGreen,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildProgressInfo(
                  Icons.schedule,
                  'Remaining',
                  remainingTimeDisplay,
                ),
                _buildProgressInfo(
                  Icons.timer_outlined,
                  'Elapsed',
                  elapsedTimeSec > 0
                      ? '${(elapsedTimeSec / 60).floor()}m'
                      : '--',
                ),
                _buildProgressInfo(
                  Icons.thermostat,
                  'Temp',
                  '$temperatureDisplayÂ°C',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressInfo(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: RooteryTheme.accentGreen, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: RooteryTheme.subText, fontSize: 11),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSensorGrid() {
    // Use live telemetry from ESP32 if available, otherwise fallback to mock data
    final telemetry = _latestTelemetry;
    final sensor = _currentSensorData;

    // If no data at all, show loading skeletons
    if (telemetry == null && sensor == null) {
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.4,
        children: List.generate(8, (_) => const SensorCardSkeleton()),
      );
    }

    // Extract telemetry values with fallbacks
    // CATEGORY 1: Real-time sensor values
    final temp =
        telemetry?['temperature']?.toString() ??
        sensor?.temperature.toStringAsFixed(1) ??
        '--';
    final humidity =
        telemetry?['humidity']?.toString() ??
        sensor?.humidity.toStringAsFixed(1) ??
        '--';
    // Prefer an explicit current airflow field if provided, fall back to measured
    final airflow =
        telemetry?['current_airflow']?.toString() ??
        telemetry?['airflow_m_s']?.toString() ??
        telemetry?['target_airflow']?.toString() ??
        (sensor != null ? sensor.airflow.toStringAsFixed(1) : '--');
    final solarIntensity =
        telemetry?['light_raw']?.toString() ??
        sensor?.solarIntensity.toStringAsFixed(0) ??
        '--';

    // CATEGORY 2: Relay states
    final heaterOn =
        telemetry?['heater_on'] == true || (sensor?.heaterStatus ?? false);
    final fanOn = telemetry?['fan_on'] == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Live Sensor Data',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            if (telemetry != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green, width: 1),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.wifi, color: Colors.green, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'ESP32 Live',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.35,
          children: [
            StatCard(
              icon: Icons.thermostat,
              label: 'Temperature',
              value: temp == '--'
                  ? '--'
                  : (double.tryParse(temp)?.toStringAsFixed(1) ?? temp),
              unit: temp == '--' ? null : 'Â°C',
              color: RooteryTheme.success,
            ),
            StatCard(
              icon: Icons.water_drop,
              label: 'Humidity',
              value: humidity == '--'
                  ? '--'
                  : (double.tryParse(humidity)?.toStringAsFixed(1) ?? humidity),
              unit: humidity == '--' ? null : '%',
              color: RooteryTheme.accentSecondary,
            ),
            StatCard(
              icon: Icons.air,
              label: 'Current Airflow',
              value: airflow == '--'
                  ? '--'
                  : (double.tryParse(airflow)?.toStringAsFixed(1) ?? airflow),
              unit: airflow == '--' ? null : 'm/s',
              color: RooteryTheme.accentSecondary,
            ),
            StatCard(
              icon: Icons.wb_sunny,
              label: 'Solar',
              value: solarIntensity == '--'
                  ? '--'
                  : (double.tryParse(solarIntensity)?.toStringAsFixed(0) ??
                        solarIntensity),
              unit: solarIntensity == '--' ? null : 'W/mÂ²',
              color: RooteryTheme.warning,
            ),
            StatCard(
              icon: Icons.whatshot,
              label: 'Heater',
              value: heaterOn ? 'ON' : 'OFF',
              color: heaterOn ? RooteryTheme.warning : RooteryTheme.offline,
            ),
            StatCard(
              icon: Icons.wind_power,
              label: 'Fan',
              value: fanOn ? 'ON' : 'OFF',
              color: fanOn ? RooteryTheme.info : RooteryTheme.offline,
            ),
            // Light and Mode cards removed (user requested)
          ],
        ),
      ],
    );
  }

  Widget _buildControlButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Modern Section Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: RooteryTheme.accentGreen.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.touch_app,
                color: RooteryTheme.accentGreen,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    color: RooteryTheme.textWhite,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Fast access to common tasks',
                  style: TextStyle(color: RooteryTheme.subText, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Horizontal Scrollable Action Cards (Mobile-Friendly)
        SizedBox(
          height: 110,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildActionCard(
                icon: Icons.touch_app_rounded,
                title: 'Manual',
                subtitle: 'Control',
                color: RooteryTheme.info,
                onTap: () => Navigator.pushNamed(context, '/manual-control'),
              ),
              _buildActionCard(
                icon: Icons.eco_outlined,
                title: 'Presets',
                subtitle: 'Auto',
                color: RooteryTheme.success,
                onTap: () => Navigator.pushNamed(context, '/auto-mode'),
              ),
              _buildActionCard(
                icon: Icons.history_rounded,
                title: 'Logs',
                subtitle: 'Activity',
                color: RooteryTheme.warning,
                onTap: () => Navigator.pushNamed(context, '/command-history'),
              ),
              _buildActionCard(
                icon: Icons.settings_outlined,
                title: 'Config',
                subtitle: 'ESP32',
                color: RooteryTheme.accentSecondary,
                onTap: () => Navigator.pushNamed(context, '/device-settings'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        color: RooteryTheme.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RooteryTheme.radiusMD),
          side: BorderSide(color: color.withOpacity(0.3), width: 1.5),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(RooteryTheme.radiusMD),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon Container
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                // Title & Subtitle
                Column(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: RooteryTheme.textWhite,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: RooteryTheme.subText,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent History',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/reports'),
              child: const Text(
                'View All',
                style: TextStyle(color: RooteryTheme.accentGreen),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._recentBatches.map((batch) => _buildHistoryCard(batch)),
      ],
    );
  }

  Widget _buildHistoryCard(DryingBatch batch) {
    return Card(
      color: RooteryTheme.card,
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: RooteryTheme.accentGreen.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: RooteryTheme.accentGreen,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Batch #${batch.batchId}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          batch.crop,
                          style: const TextStyle(
                            color: RooteryTheme.subText,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Text(
                  batch.formattedDate,
                  style: const TextStyle(
                    color: RooteryTheme.subText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildBatchStat('Duration', batch.formattedDuration),
                _buildBatchStat(
                  'Weight',
                  '${batch.weight.toStringAsFixed(0)}kg',
                ),
                _buildBatchStat(
                  'Moisture',
                  '${batch.initialMoisture.toStringAsFixed(0)}% â†’ ${batch.finalMoisture.toStringAsFixed(0)}%',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBatchStat(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: RooteryTheme.subText, fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: RooteryTheme.card,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedNavIndex,
        onTap: (index) {
          setState(() => _selectedNavIndex = index);
          if (index == 0) return;
          if (index == 1) Navigator.pushNamed(context, '/marketplace');
          if (index == 2) Navigator.pushNamed(context, '/reports');
          if (index == 3) Navigator.pushNamed(context, '/app-settings');
        },
        backgroundColor: RooteryTheme.card,
        selectedItemColor: RooteryTheme.accentGreen,
        unselectedItemColor: RooteryTheme.subText,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 13,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded, size: 26),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag_outlined, size: 26),
            label: 'Market',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined, size: 26),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined, size: 26),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

