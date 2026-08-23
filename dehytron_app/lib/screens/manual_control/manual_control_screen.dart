import 'package:flutter/material.dart';
import '../../services/command_service.dart';
import '../../theme/rootery_theme.dart';

class ManualControlScreen extends StatefulWidget {
  const ManualControlScreen({super.key});

  @override
  State<ManualControlScreen> createState() => _ManualControlScreenState();
}

class _ManualControlScreenState extends State<ManualControlScreen> {
  final CommandService _commandService = CommandService();

  double _temperatureSetpoint = 25.0;
  double _airflowSetpoint = 2.0;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 2, minute: 0);
  bool _isProcessing = false;

  Future<void> _sendCommand(
    Future<void> Function() command,
    String commandName,
  ) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      await command();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('âœ… $commandName sent successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('âŒ Failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RooteryTheme.background,
      appBar: AppBar(
        title: const Text('Manual Control'),
        backgroundColor: RooteryTheme.card,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Temperature Control
            _buildControlCard(
              title: 'Temperature Setpoint',
              icon: Icons.thermostat,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_temperatureSetpoint.round()}Â°C',
                        style: const TextStyle(
                          color: RooteryTheme.accentGreen,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => _sendCommand(
                          () => _commandService.setTemperature(
                            _temperatureSetpoint.round(),
                          ),
                          'SET_TEMP',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: RooteryTheme.accentGreen,
                        ),
                        child: const Text('Apply'),
                      ),
                    ],
                  ),
                  Slider(
                    value: _temperatureSetpoint,
                    min: 20,
                    max: 70,
                    divisions: 50,
                    activeColor: RooteryTheme.accentGreen,
                    onChanged: (value) =>
                        setState(() => _temperatureSetpoint = value),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Airflow Control
            _buildControlCard(
              title: 'Airflow Setpoint',
              icon: Icons.air,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_airflowSetpoint.toStringAsFixed(1)} m/s',
                        style: const TextStyle(
                          color: Colors.cyan,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => _sendCommand(
                          () => _commandService.setAirflow(_airflowSetpoint),
                          'SET_AIRFLOW',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyan,
                        ),
                        child: const Text('Apply'),
                      ),
                    ],
                  ),
                  Slider(
                    value: _airflowSetpoint,
                    min: 0.5,
                    max: 5.0,
                    divisions: 45,
                    activeColor: Colors.cyan,
                    onChanged: (value) =>
                        setState(() => _airflowSetpoint = value),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Time Duration Control
            _buildControlCard(
              title: 'Drying Duration',
              icon: Icons.schedule,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}:00',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: _selectedTime,
                              );
                              if (time != null) {
                                setState(() => _selectedTime = time);
                              }
                            },
                            icon: const Icon(Icons.edit, color: Colors.orange),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              final timeString =
                                  '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}:00';
                              _sendCommand(
                                () => _commandService.setTime(timeString),
                                'SET_TIME',
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                            ),
                            child: const Text('Apply'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Cycle Control Buttons
            const Text(
              'Cycle Control',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'START',
                    Icons.play_arrow,
                    Colors.green,
                    () =>
                        _sendCommand(_commandService.startCycle, 'START_CYCLE'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'PAUSE',
                    Icons.pause,
                    Colors.orange,
                    () =>
                        _sendCommand(_commandService.pauseCycle, 'PAUSE_CYCLE'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'RESUME',
                    Icons.play_circle,
                    Colors.blue,
                    () => _sendCommand(
                      _commandService.resumeCycle,
                      'RESUME_CYCLE',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'STOP',
                    Icons.stop,
                    Colors.red,
                    () => _sendCommand(_commandService.stopCycle, 'STOP_CYCLE'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Hardware Control
            const Text(
              'Hardware Control',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'HEATER ON',
                    Icons.whatshot,
                    Colors.deepOrange,
                    () => _sendCommand(_commandService.heaterOn, 'HEATER_ON'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'HEATER OFF',
                    Icons.whatshot_outlined,
                    Colors.grey,
                    () => _sendCommand(_commandService.heaterOff, 'HEATER_OFF'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'FAN ON',
                    Icons.wind_power,
                    Colors.purple,
                    () => _sendCommand(_commandService.fanOn, 'FAN_ON'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'FAN OFF',
                    Icons.wind_power_outlined,
                    Colors.grey,
                    () => _sendCommand(_commandService.fanOff, 'FAN_OFF'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // System Control
            _buildActionButton(
              'REBOOT DEVICE',
              Icons.restart_alt,
              Colors.red.shade700,
              () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Confirm Reboot'),
                    content: const Text(
                      'Are you sure you want to reboot the ESP32?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Reboot'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  _sendCommand(_commandService.reboot, 'REBOOT');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      color: RooteryTheme.card,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: RooteryTheme.accentGreen),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: _isProcessing ? null : onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

