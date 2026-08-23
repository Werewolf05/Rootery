import 'package:flutter/material.dart';
import 'dart:async';
import '../../theme/rootery_theme.dart';
import '../../services/command_service.dart';

class CommandHistoryScreen extends StatefulWidget {
  const CommandHistoryScreen({super.key});

  @override
  State<CommandHistoryScreen> createState() => _CommandHistoryScreenState();
}

class _CommandHistoryScreenState extends State<CommandHistoryScreen> {
  final CommandService _commandService = CommandService();
  List<Map<String, dynamic>> _commands = [];
  Map<String, dynamic> _statistics = {};
  bool _isLoading = true;
  String _selectedFilter = 'all';
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadData();

    // Auto-refresh every 5 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    final commands = await _commandService.getRecentCommands(limit: 50);

    if (mounted) {
      setState(() {
        _commands = commands;
        _statistics = {}; // Stats not available in new API
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredCommands {
    if (_selectedFilter == 'all') return _commands;
    return _commands.where((cmd) => cmd['status'] == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RooteryTheme.background,
      appBar: AppBar(
        backgroundColor: RooteryTheme.card,
        elevation: 0,
        title: const Text(
          'Command History',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadData();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: RooteryTheme.accentGreen,
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              color: RooteryTheme.accentGreen,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatisticsCard(),
                    const SizedBox(height: 20),
                    _buildFilterChips(),
                    const SizedBox(height: 16),
                    _buildCommandList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatisticsCard() {
    final total = _statistics['total'] ?? 0;
    final completed = _statistics['completed'] ?? 0;
    final pending = _statistics['pending'] ?? 0;
    final processing = _statistics['processing'] ?? 0;
    final failed = _statistics['failed'] ?? 0;
    final successRate = _statistics['success_rate'] ?? 0.0;

    return Card(
      color: RooteryTheme.card,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: RooteryTheme.accentGreen.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.analytics,
                    color: RooteryTheme.accentGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Command Statistics',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total',
                    total.toString(),
                    Icons.list,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Success Rate',
                    '${successRate.toStringAsFixed(1)}%',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Completed',
                    completed.toString(),
                    Icons.done,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Pending',
                    pending.toString(),
                    Icons.schedule,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Processing',
                    processing.toString(),
                    Icons.sync,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Failed',
                    failed.toString(),
                    Icons.error,
                    Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Wrap(
      spacing: 8,
      children: [
        _buildFilterChip('all', 'All', Icons.list),
        _buildFilterChip('pending', 'Pending', Icons.schedule),
        _buildFilterChip('processing', 'Processing', Icons.sync),
        _buildFilterChip('completed', 'Completed', Icons.check_circle),
        _buildFilterChip('failed', 'Failed', Icons.error),
      ],
    );
  }

  Widget _buildFilterChip(String value, String label, IconData icon) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? Colors.white : Colors.white70,
          ),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      backgroundColor: RooteryTheme.card,
      selectedColor: RooteryTheme.accentGreen,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.white70,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
    );
  }

  Widget _buildCommandList() {
    if (_filteredCommands.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(Icons.inbox, size: 64, color: Colors.white30),
              const SizedBox(height: 16),
              Text(
                'No commands found',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_filteredCommands.length} command${_filteredCommands.length != 1 ? 's' : ''}',
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 12),
        ..._filteredCommands.map((command) => _buildCommandCard(command)),
      ],
    );
  }

  Widget _buildCommandCard(Map<String, dynamic> command) {
    final commandType = command['cmd'] ?? command['command_type'] ?? 'UNKNOWN';
    final executed = command['executed'] as bool? ?? false;
    final status = executed ? 'completed' : 'pending';
    final createdAt = DateTime.parse(command['created_at']);
    final executedAt = command['executed_at'] != null
        ? DateTime.parse(command['executed_at'])
        : null;
    final parameters = command['value'] != null
        ? {'value': command['value']}
        : (command['parameters'] as Map<String, dynamic>?);
    final errorMessage = command['error_message'] as String?;

    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
      case 'processing':
        statusColor = Colors.blue;
        statusIcon = Icons.sync;
        break;
      case 'failed':
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
      case 'expired':
        statusColor = Colors.grey;
        statusIcon = Icons.timer_off;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
    }

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
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getCommandColor(commandType).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getCommandIcon(commandType),
                    color: _getCommandColor(commandType),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatCommandType(commandType),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _formatDateTime(createdAt),
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (parameters != null && parameters.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Parameters:',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...parameters.entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '${entry.key}: ${entry.value}',
                          style: const TextStyle(
                            color: RooteryTheme.accentGreen,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (executedAt != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 14,
                    color: Colors.white60,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Executed: ${_formatDateTime(executedAt)}',
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Duration: ${executedAt.difference(createdAt).inSeconds}s',
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ],

            if (errorMessage != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, size: 16, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        errorMessage,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatCommandType(String type) {
    return type
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    }
  }

  Color _getCommandColor(String commandType) {
    switch (commandType) {
      case 'start_drying':
        return Colors.green;
      case 'stop_drying':
        return Colors.red;
      case 'set_temperature':
        return Colors.orange;
      case 'set_fan_speed':
        return Colors.blue;
      case 'toggle_heater':
        return Colors.deepOrange;
      case 'emergency_stop':
        return Colors.red[900]!;
      default:
        return Colors.grey;
    }
  }

  IconData _getCommandIcon(String commandType) {
    switch (commandType) {
      case 'start_drying':
        return Icons.play_arrow;
      case 'stop_drying':
        return Icons.stop;
      case 'set_temperature':
        return Icons.thermostat;
      case 'set_fan_speed':
        return Icons.air;
      case 'toggle_heater':
        return Icons.local_fire_department;
      case 'emergency_stop':
        return Icons.emergency;
      default:
        return Icons.settings;
    }
  }
}

