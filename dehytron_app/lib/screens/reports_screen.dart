import 'package:flutter/material.dart';
import '../theme/rootery_theme.dart';
import '../services/data_service.dart';
import '../models/app_models.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final DataService _dataService = DataService();
  List<DryingBatch> _batches = [];

  @override
  void initState() {
    super.initState();
    _loadBatches();
  }

  void _loadBatches() {
    setState(() {
      _batches = _dataService.batches;
    });
  }

  double get _totalWeight =>
      _batches.fold(0, (sum, batch) => sum + batch.weight);

  Duration get _avgDuration {
    if (_batches.isEmpty) return Duration.zero;
    final totalMinutes = _batches.fold(
      0,
      (sum, batch) => sum + batch.duration.inMinutes,
    );
    return Duration(minutes: (totalMinutes / _batches.length).round());
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RooteryTheme.background,
      appBar: AppBar(
        backgroundColor: RooteryTheme.card,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Drying History',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Exporting all reports...'),
                  backgroundColor: RooteryTheme.accentGreen,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCards(),
            const SizedBox(height: 24),
            const Text(
              'Recent Batches',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ..._batches.map((batch) => _buildHistoryCard(batch)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Total Batches',
            _batches.length.toString(),
            Icons.inventory,
            Colors.blue.shade400,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Total Weight',
            '${_totalWeight.toStringAsFixed(0)}kg',
            Icons.scale,
            Colors.purple.shade400,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Avg Duration',
            _formatDuration(_avgDuration),
            Icons.schedule,
            Colors.orange.shade400,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      color: RooteryTheme.card,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: RooteryTheme.subText,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: RooteryTheme.accentGreen.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    batch.status,
                    style: const TextStyle(
                      color: RooteryTheme.accentGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoItem(Icons.calendar_today, batch.formattedDate),
                _buildInfoItem(Icons.schedule, batch.formattedDuration),
                _buildInfoItem(
                  Icons.scale,
                  '${batch.weight.toStringAsFixed(0)}kg',
                ),
                _buildInfoItem(
                  Icons.thermostat,
                  '${batch.avgTemp.toStringAsFixed(0)}Â°C',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: RooteryTheme.subText, size: 14),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(color: RooteryTheme.subText, fontSize: 12),
        ),
      ],
    );
  }
}

