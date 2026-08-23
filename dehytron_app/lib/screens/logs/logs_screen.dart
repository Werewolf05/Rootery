import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/telemetry_service.dart';
import '../../theme/rootery_theme.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  final TelemetryService _telemetryService = TelemetryService();
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;
  final DateFormat _dateFormat = DateFormat('MMM dd, HH:mm:ss');

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    final logs = await _telemetryService.getRecentTelemetry(limit: 100);
    setState(() {
      _logs = logs;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RooteryTheme.background,
      appBar: AppBar(
        title: const Text('Live Logs'),
        backgroundColor: RooteryTheme.card,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadLogs),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
          ? const Center(
              child: Text(
                'No telemetry data available',
                style: TextStyle(color: RooteryTheme.subText),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final log = _logs[index];
                return _buildLogCard(log);
              },
            ),
    );
  }

  Widget _buildLogCard(Map<String, dynamic> log) {
    final createdAt = log['created_at'] != null
        ? DateTime.parse(log['created_at'])
        : DateTime.now();

    return Card(
      color: RooteryTheme.card,
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Row(
          children: [
            Icon(
              log['cycle_running'] == true
                  ? Icons.play_circle
                  : Icons.pause_circle,
              color: log['cycle_running'] == true ? Colors.green : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              _dateFormat.format(createdAt),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            'Temp: ${log['temperature']?.toStringAsFixed(1) ?? '--'}Â°C | '
            'Humidity: ${log['humidity']?.toStringAsFixed(1) ?? '--'}%',
            style: const TextStyle(color: RooteryTheme.subText, fontSize: 12),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLogRow(
                  'Device ID',
                  log['device_id']?.toString() ?? 'N/A',
                ),
                _buildLogRow('Temperature', '${log['temperature'] ?? '--'} Â°C'),
                _buildLogRow('Humidity', '${log['humidity'] ?? '--'} %'),
                _buildLogRow('Airflow', '${log['airflow_m_s'] ?? '--'} m/s'),
                _buildLogRow(
                  'Set Temp',
                  '${log['set_temperature'] ?? '--'} Â°C',
                ),
                _buildLogRow(
                  'Set Airflow',
                  '${log['set_airflow'] ?? '--'} m/s',
                ),
                _buildLogRow(
                  'Mode',
                  (log['current_mode'] ?? 'N/A').toString().toUpperCase(),
                ),
                _buildLogRow(
                  'Heater',
                  log['heater_state'] == true ? 'ON' : 'OFF',
                ),
                _buildLogRow('Fan', log['fan_state'] == true ? 'ON' : 'OFF'),
                _buildLogRow(
                  'Light',
                  log['light_state'] == true ? 'ON' : 'OFF',
                ),
                _buildLogRow(
                  'Cycle Running',
                  log['cycle_running'] == true ? 'YES' : 'NO',
                ),
                _buildLogRow('Light Raw', log['light_raw']?.toString() ?? '--'),
                _buildLogRow('Pot Value', log['pot_value']?.toString() ?? '--'),
                _buildLogRow('WiFi RSSI', '${log['wifi_rssi'] ?? '--'} dBm'),
                if (log['firmware_version'] != null)
                  _buildLogRow('Firmware', log['firmware_version']),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: RooteryTheme.subText, fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

