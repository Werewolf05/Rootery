import 'package:flutter/material.dart';
import '../theme/rootery_theme.dart';
import 'hydroponics/hydro_dashboard_screen.dart';
import 'hydroponics/hydro_sensors_screen.dart';
import 'hydroponics/hydro_batches_screen.dart';
import 'hydroponics/hydro_settings_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HydroDashboardScreen(),
    HydroSensorsScreen(),
    HydroBatchesScreen(),
    HydroSettingsScreen(),
  ];

  final List<String> _labels = const [
    'Dashboard',
    'Analytics',
    'Schedule',
    'Settings',
  ];

  final List<IconData> _icons = const [
    Icons.dashboard_outlined,
    Icons.analytics_outlined,
    Icons.calendar_month_outlined,
    Icons.settings_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: KeyedSubtree(
          key: ValueKey<int>(_currentIndex),
          child: _screens[_currentIndex],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: RooteryTheme.bgSurface,
          border: const Border(
            top: BorderSide(color: RooteryTheme.borderLight),
          ),
          boxShadow: const [RooteryTheme.cardShadow],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 72,
            child: Row(
              children: List.generate(_labels.length, (index) {
                final active = _currentIndex == index;
                return Expanded(
                  child: Semantics(
                    button: true,
                    selected: active,
                    label: '${_labels[index]} tab',
                    child: InkWell(
                      onTap: () => setState(() => _currentIndex = index),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _icons[index],
                            color: active
                                ? RooteryTheme.green400
                                : RooteryTheme.textLow,
                            size: 22,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _labels[index],
                            style: RooteryTheme.ui(
                              11,
                              weight: FontWeight.w500,
                              color: active
                                  ? RooteryTheme.green600
                                  : RooteryTheme.textLow,
                            ),
                          ),
                          const SizedBox(height: 5),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOutCubic,
                            width: active ? 32 : 0,
                            height: 3,
                            decoration: BoxDecoration(
                              color: RooteryTheme.green400,
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
