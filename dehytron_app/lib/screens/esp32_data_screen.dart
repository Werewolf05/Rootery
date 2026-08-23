import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../theme/rootery_theme.dart';

class ESP32DataScreen extends StatefulWidget {
  const ESP32DataScreen({super.key});

  @override
  State<ESP32DataScreen> createState() => _ESP32DataScreenState();
}

class _ESP32DataScreenState extends State<ESP32DataScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _sensorData = [];
  Map<String, dynamic>? _latestReading;
  Timer? _refreshTimer;
  bool _isLoading = true;
  String? _errorMessage;
  int _dataCount = 0;

  @override
  void initState() {
    super.initState();
    _loadSensorData();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _loadSensorData();
    });
  }

  Future<void> _loadSensorData() async {
    try {
      final response = await _supabase
          .from('telemetry')
          .select()
          .eq('device_id', 'ROOTERY_01')
          .order('created_at', ascending: false)
          .limit(10);

      if (mounted) {
        setState(() {
          _sensorData = List<Map<String, dynamic>>.from(response);
          _latestReading = _sensorData.isNotEmpty ? _sensorData.first : null;
          _dataCount = _sensorData.length;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RooteryTheme.background,
      appBar: AppBar(
        backgroundColor: RooteryTheme.card,
        title: const Text('ESP32 Live Sensor Data'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSensorData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorView()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildConnectionStatus(),
                  const SizedBox(height: 20),
                  if (_latestReading != null) ...[
                    _buildLatestReadingCard(),
                    const SizedBox(height: 20),
                    _buildActuatorStatusCard(),
                    const SizedBox(height: 20),
                  ],
                  _buildDataCountCard(),
                  const SizedBox(height: 20),
                  _buildHistorySection(),
                ],
              ),
            ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Failed to Load Data',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error',
              style: const TextStyle(color: RooteryTheme.subText),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            const Text(
              'âš ï¸ Make sure:\nâ€¢ telemetry table exists in Supabase\nâ€¢ ESP32 has sent data\nâ€¢ Device ID is ROOTERY_01\nâ€¢ Internet connection is active',
              style: TextStyle(color: RooteryTheme.subText, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadSensorData,
              style: ElevatedButton.styleFrom(
                backgroundColor: RooteryTheme.accentGreen,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStatus() {
    final isConnected = _latestReading != null;
    final lastUpdate = _latestReading != null
        ? DateTime.parse(_latestReading!['created_at'])
        : null;
    final isRecent =
        lastUpdate != null &&
        DateTime.now().difference(lastUpdate).inSeconds < 30;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RooteryTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isConnected && isRecent
              ? Colors.green
              : isConnected
              ? Colors.orange
              : Colors.red,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isConnected && isRecent
                  ? Colors.green
                  : isConnected
                  ? Colors.orange
                  : Colors.red,
              boxShadow: [
                BoxShadow(
                  color:
                      (isConnected && isRecent
                              ? Colors.green
                              : isConnected
                              ? Colors.orange
                              : Colors.red)
                          .withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isConnected && isRecent
                      ? 'ESP32 Connected'
                      : isConnected
                      ? 'ESP32 Last Seen'
                      : 'ESP32 Disconnected',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (lastUpdate != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _formatTimestamp(lastUpdate),
                    style: const TextStyle(
                      color: RooteryTheme.subText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.sensors, color: RooteryTheme.accentGreen),
        ],
      ),
    );
  }

  Widget _buildLatestReadingCard() {
    final temp = _latestReading!['temperature'] as num?;
    final humidity = _latestReading!['humidity'] as num?;
    final currentCrop = _latestReading!['current_crop'] as String? ?? 'None';
    final targetTemp = _latestReading!['target_temp'] as num? ?? 50;
    final cycleRunning = _latestReading!['cycle_running'] as bool? ?? false;
    final heaterOn = _latestReading!['heater_on'] as bool? ?? false;
    final fanOn = _latestReading!['fan_on'] as bool? ?? false;
    final lightOn = _latestReading!['light_on'] as bool? ?? false;
    final progress = _latestReading!['progress_percent'] as num? ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            RooteryTheme.accentGreen,
            RooteryTheme.accentGreen.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: RooteryTheme.accentGreen.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.thermostat, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Latest Reading',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Crop: $currentCrop',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (cycleRunning)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$progress%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildSensorValue(
                  'Temperature',
                  temp != null ? '${temp.toStringAsFixed(1)}Â°C' : 'N/A',
                  Icons.thermostat_outlined,
                  temp != null && temp > 30 ? Colors.red : Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSensorValue(
                  'Humidity',
                  humidity != null ? '${humidity.toStringAsFixed(1)}%' : 'N/A',
                  Icons.water_drop_outlined,
                  humidity != null && humidity > 70
                      ? Colors.blue
                      : Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSensorValue(
                  'Target',
                  '${targetTemp}Â°C',
                  Icons.track_changes,
                  Colors.white70,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSensorValue(
                  'Status',
                  cycleRunning ? 'Running' : 'Idle',
                  cycleRunning ? Icons.play_circle : Icons.pause_circle,
                  cycleRunning ? Colors.orange : Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildHardwareIndicator('Heater', heaterOn, Icons.whatshot),
                _buildHardwareIndicator('Fan', fanOn, Icons.air),
                _buildHardwareIndicator('Light', lightOn, Icons.lightbulb),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorValue(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color.withOpacity(0.8), size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(color: color.withOpacity(0.9), fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildHardwareIndicator(String label, bool isOn, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: isOn ? Colors.orange : Colors.white30, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isOn ? Colors.white : Colors.white60,
            fontSize: 10,
            fontWeight: isOn ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildActuatorStatusCard() {
    final pumpOn = _latestReading!['pump_on'] == true;
    final sprinklerOn = _latestReading!['sprinkler_on'] == true;
    final autoState = (_latestReading!['auto_state'] as num?)?.toInt() ?? 0;
    final autoLabel = switch (autoState) {
      1 => 'RUNNING',
      2 => 'WAITING',
      _ => 'IDLE',
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RooteryTheme.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Actuator Status',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatusPill(
                  'Pump',
                  pumpOn ? 'ON' : 'OFF',
                  pumpOn ? Colors.green : Colors.grey,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatusPill(
                  'Sprinkler',
                  sprinklerOn ? 'ON' : 'OFF',
                  sprinklerOn ? Colors.blue : Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildStatusPill('Auto Mode', autoLabel, Colors.orange),
        ],
      ),
    );
  }

  Widget _buildStatusPill(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.45)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataCountCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RooteryTheme.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: RooteryTheme.accentGreen.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.storage,
              color: RooteryTheme.accentGreen,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Data Points',
                  style: TextStyle(color: RooteryTheme.subText, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  '$_dataCount readings',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Live',
              style: TextStyle(
                color: Colors.green,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.history, color: RooteryTheme.accentGreen, size: 20),
            SizedBox(width: 8),
            Text(
              'Recent History',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_sensorData.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: RooteryTheme.card,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Column(
                children: [
                  Icon(Icons.inbox, color: RooteryTheme.subText, size: 48),
                  SizedBox(height: 8),
                  Text(
                    'No data yet',
                    style: TextStyle(color: RooteryTheme.subText),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Waiting for ESP32 to send data...',
                    style: TextStyle(color: RooteryTheme.subText, fontSize: 12),
                  ),
                ],
              ),
            ),
          )
        else
          ..._sensorData.map((reading) => _buildHistoryItem(reading)),
      ],
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> reading) {
    final temp = reading['temperature'] as num?;
    final humidity = reading['humidity'] as num?;
    final currentCrop = reading['current_crop'] as String? ?? 'None';
    final cycleRunning = reading['cycle_running'] as bool? ?? false;
    final timestamp = DateTime.parse(reading['created_at']);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RooteryTheme.card,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cycleRunning
                  ? Colors.orange.withOpacity(0.2)
                  : RooteryTheme.accentGreen.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              cycleRunning ? Icons.play_circle : Icons.sensors,
              color: cycleRunning ? Colors.orange : RooteryTheme.accentGreen,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.thermostat, color: Colors.red, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      temp != null ? '${temp.toStringAsFixed(1)}Â°C' : 'N/A',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.water_drop, color: Colors.blue, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      humidity != null
                          ? '${humidity.toStringAsFixed(1)}%'
                          : 'N/A',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      currentCrop,
                      style: const TextStyle(
                        color: RooteryTheme.subText,
                        fontSize: 11,
                      ),
                    ),
                    const Text(
                      ' â€¢ ',
                      style: TextStyle(
                        color: RooteryTheme.subText,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      _formatTimestamp(timestamp),
                      style: const TextStyle(
                        color: RooteryTheme.subText,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}
