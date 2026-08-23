import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../theme/rootery_theme.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  int _selectedNavIndex = 0;
  bool _pumpOn = true;
  bool _lightsOn = true;

  late final AnimationController _enterCtrl;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;

  final List<Map<String, dynamic>> _sensors = [
    {'title': 'Potential Hydrogen', 'value': '6.2', 'unit': '', 'trend': '+'},
    {'title': 'TDS Level', 'value': '850', 'unit': 'ppm', 'trend': '+'},
    {'title': 'Water Temp', 'value': '22.4', 'unit': 'C', 'trend': '+'},
    {'title': 'Air Temp', 'value': '24.1', 'unit': 'C', 'trend': '+'},
    {'title': 'Air Humidity', 'value': '65', 'unit': '%', 'trend': '-'},
    {'title': 'Reservoir Level', 'value': '95', 'unit': '%', 'trend': '+'},
  ];

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOutCubic));
    _fadeAnim = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut);
    _enterCtrl.forward();
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RooteryTheme.bgScaffold,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: IndexedStack(
            index: _selectedNavIndex,
            children: [
              _buildDashboardTab(),
              _buildSimpleTab('Analytics'),
              _buildSimpleTab('Schedule'),
              _buildSimpleTab('Settings'),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: RooteryTheme.bgSurface,
        selectedItemColor: RooteryTheme.green400,
        unselectedItemColor: RooteryTheme.textLow,
        currentIndex: _selectedNavIndex,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: RooteryTheme.ui(11, weight: FontWeight.w500),
        unselectedLabelStyle: RooteryTheme.ui(11, weight: FontWeight.w500),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.assessment_outlined), label: 'Analytics'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), label: 'Schedule'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
        onTap: (index) => setState(() => _selectedNavIndex = index),
      ),
    );
  }

  Widget _buildDashboardTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Rootery Admin', style: RooteryTheme.ui(22, weight: FontWeight.w600)),
        const SizedBox(height: 12),
        AnimationLimiter(
          child: SizedBox(
            height: 138,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _summaryCard('Active Farms', 12),
                const SizedBox(width: 10),
                _summaryCard('Alerts', 2),
                const SizedBox(width: 10),
                _summaryCard('Yield Index', 98),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Live Sensors',
          style: RooteryTheme.ui(13, weight: FontWeight.w500, color: RooteryTheme.textMid, letterSpacing: 0.3),
        ),
        const SizedBox(height: 8),
        AnimationLimiter(
          child: GridView.builder(
            itemCount: _sensors.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.05,
            ),
            itemBuilder: (context, index) {
              final sensor = _sensors[index];
              return AnimationConfiguration.staggeredGrid(
                position: index,
                columnCount: 2,
                delay: const Duration(milliseconds: 60),
                child: SlideAnimation(
                  verticalOffset: 16,
                  child: FadeInAnimation(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: RooteryTheme.cardDecoration(radius: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(sensor['title'], style: RooteryTheme.ui(11, color: RooteryTheme.textMid)),
                          const Spacer(),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              TweenAnimationBuilder<double>(
                                tween: Tween<double>(begin: 0, end: double.parse(sensor['value'])),
                                duration: const Duration(milliseconds: 800),
                                curve: Curves.easeOutExpo,
                                builder: (context, anim, child) {
                                  return Text(
                                    anim.toStringAsFixed(sensor['unit'] == 'ppm' ? 0 : 1),
                                    style: RooteryTheme.mono(26, weight: FontWeight.w700, color: RooteryTheme.green600),
                                  );
                                },
                              ),
                              const SizedBox(width: 4),
                              Text(sensor['unit'], style: RooteryTheme.mono(11, color: RooteryTheme.textLow, letterSpacing: 0.8)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        _controlCard('Water Pump', _pumpOn, (v) => setState(() => _pumpOn = v)),
        const SizedBox(height: 10),
        _controlCard('Grow Lights', _lightsOn, (v) => setState(() => _lightsOn = v)),
      ],
    );
  }

  Widget _summaryCard(String label, int target) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(18),
      decoration: RooteryTheme.cardDecoration(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: RooteryTheme.ui(11, color: RooteryTheme.textMid, letterSpacing: 0.3)),
          const Spacer(),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: target.toDouble()),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutExpo,
            builder: (context, anim, child) {
              return Text(anim.toStringAsFixed(0), style: RooteryTheme.mono(30, weight: FontWeight.w700, color: RooteryTheme.green600));
            },
          ),
        ],
      ),
    );
  }

  Widget _controlCard(String title, bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: RooteryTheme.cardDecoration(radius: 20),
      child: Row(
        children: [
          Expanded(child: Text(title, style: RooteryTheme.ui(14, weight: FontWeight.w500))),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: RooteryTheme.green400,
            activeTrackColor: RooteryTheme.green100,
            inactiveThumbColor: RooteryTheme.textLow,
            inactiveTrackColor: RooteryTheme.borderLight,
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleTab(String title) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(20),
        decoration: RooteryTheme.cardDecoration(radius: 20),
        child: Text('$title panel layout ready', style: RooteryTheme.ui(18, weight: FontWeight.w600)),
      ),
    );
  }
}

