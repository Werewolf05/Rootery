import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/rootery_theme.dart';
import 'dart:math' as math;

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String selectedPeriod = 'Week';
  final List<String> periods = ['Day', 'Week', 'Month', 'Year'];

  // Mock data for charts
  List<FlSpot> get temperatureData {
    return List.generate(24, (index) {
      return FlSpot(
        index.toDouble(),
        55 + math.Random().nextDouble() * 15,
      );
    });
  }

  List<FlSpot> get humidityData {
    return List.generate(24, (index) {
      return FlSpot(
        index.toDouble(),
        30 + math.Random().nextDouble() * 30,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RooteryTheme.background,
      appBar: AppBar(
        backgroundColor: RooteryTheme.card,
        title: const Text('Analytics & Reports'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period selector
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: periods.map((period) {
                  final isSelected = selectedPeriod == period;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(period),
                      selected: isSelected,
                      onSelected: (_) => setState(() => selectedPeriod = period),
                      backgroundColor: RooteryTheme.card,
                      selectedColor: RooteryTheme.accentGreen,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : RooteryTheme.subText,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // Statistics Cards
            Row(
              children: [
                Expanded(child: _buildStatCard('Total Batches', '47', Icons.inventory, Colors.blue)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('Success Rate', '94%', Icons.check_circle, Colors.green)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildStatCard('Avg Duration', '8.5h', Icons.timer, Colors.orange)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('Energy Used', '342kWh', Icons.bolt, Colors.purple)),
              ],
            ),
            const SizedBox(height: 24),

            // Temperature Chart
            _buildChartCard(
              'Temperature Trends',
              _buildTemperatureChart(),
              Icons.thermostat,
              Colors.red,
            ),
            const SizedBox(height: 24),

            // Humidity Chart
            _buildChartCard(
              'Humidity Levels',
              _buildHumidityChart(),
              Icons.water_drop,
              Colors.blue,
            ),
            const SizedBox(height: 24),

            // Batch Performance
            _buildBatchPerformanceCard(),
            const SizedBox(height: 24),

            // Crop Statistics
            _buildCropStatsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RooteryTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '+12%',
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: RooteryTheme.subText,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(String title, Widget chart, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RooteryTheme.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
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
          const SizedBox(height: 20),
          SizedBox(height: 200, child: chart),
        ],
      ),
    );
  }

  Widget _buildTemperatureChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 10,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.shade800,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 6,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}h',
                  style: const TextStyle(
                    color: RooteryTheme.subText,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 10,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}Â°C',
                  style: const TextStyle(
                    color: RooteryTheme.subText,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 23,
        minY: 50,
        maxY: 75,
        lineBarsData: [
          LineChartBarData(
            spots: temperatureData,
            isCurved: true,
            color: Colors.red,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.red.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHumidityChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 10,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.shade800,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 6,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}h',
                  style: const TextStyle(
                    color: RooteryTheme.subText,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 10,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}%',
                  style: const TextStyle(
                    color: RooteryTheme.subText,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 23,
        minY: 25,
        maxY: 65,
        lineBarsData: [
          LineChartBarData(
            spots: humidityData,
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatchPerformanceCard() {
    final batches = [
      {'crop': 'Mangoes', 'time': '9.5h', 'success': true, 'quality': 'A+'},
      {'crop': 'Tomatoes', 'time': '8.2h', 'success': true, 'quality': 'A'},
      {'crop': 'Bananas', 'time': '10.1h', 'success': true, 'quality': 'A+'},
      {'crop': 'Apples', 'time': '11.3h', 'success': false, 'quality': 'B'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RooteryTheme.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.assessment, color: RooteryTheme.accentGreen, size: 20),
              SizedBox(width: 8),
              Text(
                'Recent Batch Performance',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...batches.map((batch) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: (batch['success'] as bool)
                        ? Colors.green.withOpacity(0.2)
                        : Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    (batch['success'] as bool) ? Icons.check : Icons.warning,
                    color: (batch['success'] as bool) ? Colors.green : Colors.orange,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        batch['crop'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        batch['time'] as String,
                        style: const TextStyle(
                          color: RooteryTheme.subText,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: RooteryTheme.accentGreen.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Quality: ${batch['quality']}',
                    style: const TextStyle(
                      color: RooteryTheme.accentGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildCropStatsCard() {
    final crops = [
      {'name': 'Mangoes', 'batches': 15, 'percentage': 32},
      {'name': 'Tomatoes', 'batches': 12, 'percentage': 26},
      {'name': 'Bananas', 'batches': 10, 'percentage': 21},
      {'name': 'Others', 'batches': 10, 'percentage': 21},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RooteryTheme.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.pie_chart, color: RooteryTheme.accentGreen, size: 20),
              SizedBox(width: 8),
              Text(
                'Crop Distribution',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...crops.map((crop) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      crop['name'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${crop['batches']} batches (${crop['percentage']}%)',
                      style: const TextStyle(
                        color: RooteryTheme.subText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (crop['percentage'] as int) / 100,
                  backgroundColor: Colors.grey.shade800,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getColorForIndex(crops.indexOf(crop)),
                  ),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Color _getColorForIndex(int index) {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.orange,
      Colors.purple,
    ];
    return colors[index % colors.length];
  }
}

