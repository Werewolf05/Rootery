import 'package:flutter/material.dart';
import '../../services/command_service.dart';
import '../../theme/rootery_theme.dart';

class DeviceSettingsScreen extends StatefulWidget {
  const DeviceSettingsScreen({super.key});

  @override
  State<DeviceSettingsScreen> createState() => _DeviceSettingsScreenState();
}

class _DeviceSettingsScreenState extends State<DeviceSettingsScreen> {
  final CommandService _commandService = CommandService();

  String _selectedMode = 'AUTO';
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
        title: const Text('Device Settings'),
        backgroundColor: RooteryTheme.card,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Mode Control
          Card(
            color: RooteryTheme.card,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.settings, color: RooteryTheme.accentGreen),
                      SizedBox(width: 8),
                      Text(
                        'Operation Mode',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'AUTO',
                        label: Text('AUTO'),
                        icon: Icon(Icons.auto_mode),
                      ),
                      ButtonSegment(
                        value: 'MANUAL',
                        label: Text('MANUAL'),
                        icon: Icon(Icons.touch_app),
                      ),
                    ],
                    selected: {_selectedMode},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() => _selectedMode = newSelection.first);
                      _sendCommand(
                        () => _commandService.setMode(_selectedMode),
                        'SET_MODE',
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _selectedMode == 'AUTO'
                        ? 'ESP32 will follow crop presets and automatically control hardware'
                        : 'Manual control allows you to override all settings',
                    style: const TextStyle(
                      color: RooteryTheme.subText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Hardware Quick Controls
          Card(
            color: RooteryTheme.card,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.power, color: RooteryTheme.accentGreen),
                      SizedBox(width: 8),
                      Text(
                        'Hardware Control',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildToggleRow(
                    'Heater',
                    Icons.whatshot,
                    Colors.deepOrange,
                    () => _sendCommand(_commandService.heaterOn, 'HEATER_ON'),
                    () => _sendCommand(_commandService.heaterOff, 'HEATER_OFF'),
                  ),

                  const Divider(height: 24, color: Colors.grey),

                  _buildToggleRow(
                    'Fan',
                    Icons.wind_power,
                    Colors.purple,
                    () => _sendCommand(_commandService.fanOn, 'FAN_ON'),
                    () => _sendCommand(_commandService.fanOff, 'FAN_OFF'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Device Info
          Card(
            color: RooteryTheme.card,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: RooteryTheme.accentGreen,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Device Information',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Device ID', 'ROOTERY_01'),
                  _buildInfoRow(
                    'Supabase URL',
                    'kvcgvuverkusobluugip.supabase.co',
                  ),
                  _buildInfoRow('Poll Interval', '5 seconds'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow(
    String label,
    IconData icon,
    Color color,
    VoidCallback onEnable,
    VoidCallback onDisable,
  ) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
        ElevatedButton(
          onPressed: _isProcessing ? null : onEnable,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          ),
          child: const Text('ON'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _isProcessing ? null : onDisable,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          ),
          child: const Text('OFF'),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                color: RooteryTheme.subText,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

