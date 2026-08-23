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
      child: InkWell(
        onTap: () => _showBatchDetails(batch),
        borderRadius: BorderRadius.circular(12),
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
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMoistureIndicator(
                      'Initial',
                      batch.initialMoisture,
                      Colors.orange.shade400,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward,
                    color: RooteryTheme.subText,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMoistureIndicator(
                      'Final',
                      batch.finalMoisture,
                      RooteryTheme.accentGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => _showBatchDetails(batch),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: RooteryTheme.accentGreen),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'View Full Details',
                      style: TextStyle(color: RooteryTheme.accentGreen),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward,
                      color: RooteryTheme.accentGreen,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ],
          ),
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

  Widget _buildMoistureIndicator(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: RooteryTheme.subText, fontSize: 11),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.water_drop, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              '${value.toStringAsFixed(0)}%',
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showBatchDetails(DryingBatch batch) {
    showModalBottomSheet(
      context: context,
      backgroundColor: RooteryTheme.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: RooteryTheme.subText,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Batch #${batch.batchId}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          batch.crop,
                          style: const TextStyle(
                            color: RooteryTheme.subText,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: RooteryTheme.accentGreen.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        batch.status,
                        style: const TextStyle(
                          color: RooteryTheme.accentGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildDetailRow(
                  'Date',
                  batch.formattedDate,
                  Icons.calendar_today,
                ),
                _buildDetailRow(
                  'Duration',
                  batch.formattedDuration,
                  Icons.schedule,
                ),
                _buildDetailRow(
                  'Weight',
                  '${batch.weight.toStringAsFixed(1)} kg',
                  Icons.scale,
                ),
                _buildDetailRow(
                  'Avg Temperature',
                  '${batch.avgTemp.toStringAsFixed(1)}Â°C',
                  Icons.thermostat,
                ),
                _buildDetailRow(
                  'Avg Humidity',
                  '${batch.avgHumidity.toStringAsFixed(1)}%',
                  Icons.water_drop,
                ),
                _buildDetailRow(
                  'Avg Airflow',
                  '${batch.avgAirflow.toStringAsFixed(0)} CFM',
                  Icons.air,
                ),
                _buildDetailRow(
                  'Initial Moisture',
                  '${batch.initialMoisture.toStringAsFixed(1)}%',
                  Icons.water,
                ),
                _buildDetailRow(
                  'Final Moisture',
                  '${batch.finalMoisture.toStringAsFixed(1)}%',
                  Icons.check_circle,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Repeating batch settings...'),
                              backgroundColor: RooteryTheme.accentGreen,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: RooteryTheme.accentGreen,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.replay, color: Colors.white),
                        label: const Text(
                          'Repeat Batch',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Exporting batch report...'),
                              backgroundColor: RooteryTheme.accentGreen,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: RooteryTheme.accentGreen,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(
                          Icons.file_download,
                          color: RooteryTheme.accentGreen,
                        ),
                        label: const Text(
                          'Export',
                          style: TextStyle(
                            color: RooteryTheme.accentGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
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

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: RooteryTheme.accentGreen.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: RooteryTheme.accentGreen, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: RooteryTheme.subText,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

