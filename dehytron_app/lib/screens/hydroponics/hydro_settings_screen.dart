import 'package:flutter/material.dart';
import '../../theme/rootery_theme.dart';
import '../../widgets/app_footer.dart';

class HydroSettingsScreen extends StatefulWidget {
  const HydroSettingsScreen({super.key});

  @override
  State<HydroSettingsScreen> createState() => _HydroSettingsScreenState();
}

class _HydroSettingsScreenState extends State<HydroSettingsScreen>
    with SingleTickerProviderStateMixin {
  bool notifyPh = true;
  bool notifyTds = true;
  bool notifyReservoir = true;
  bool notifyOffline = true;

  late final AnimationController _enterCtrl;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOutCubic));
    _fadeAnim = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut);
    _enterCtrl.forward();
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    super.dispose();
  }

  Widget _sectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: RooteryTheme.green50,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        title.toUpperCase(),
        style: RooteryTheme.ui(
          13,
          weight: FontWeight.w500,
          color: RooteryTheme.green900,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RooteryTheme.bgScaffold,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: RooteryTheme.bgSurface,
        title: Text(
          'Settings',
          style: RooteryTheme.ui(22, weight: FontWeight.w600),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _sectionHeader('Alert Notifications'),
              const SizedBox(height: 8),
              _switchTile(
                'pH out of range',
                notifyPh,
                (v) => setState(() => notifyPh = v),
              ),
              _switchTile(
                'TDS too high',
                notifyTds,
                (v) => setState(() => notifyTds = v),
              ),
              _switchTile(
                'Low reservoir level',
                notifyReservoir,
                (v) => setState(() => notifyReservoir = v),
              ),
              _switchTile(
                'Device offline',
                notifyOffline,
                (v) => setState(() => notifyOffline = v),
              ),
              const SizedBox(height: 20),
              _sectionHeader('System'),
              const SizedBox(height: 8),
              _switchTile(
                'High contrast mode',
                RooteryTheme.highContrastMode.value,
                (v) {
                  RooteryTheme.highContrastMode.value = v;
                  setState(() {});
                },
              ),
              Container(
                decoration: RooteryTheme.cardDecoration(radius: 20),
                child: ListTile(
                  leading: const Icon(
                    Icons.restart_alt,
                    color: RooteryTheme.textMid,
                  ),
                  title: Text(
                    'Restart app session',
                    style: RooteryTheme.ui(14, weight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    'Reload telemetry subscriptions',
                    style: RooteryTheme.ui(11, color: RooteryTheme.textMid),
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Session reload queued.')),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: RooteryTheme.cardDecoration(radius: 20),
                child: ListTile(
                  leading: const Icon(
                    Icons.logout,
                    color: RooteryTheme.redAlert,
                  ),
                  title: Text(
                    'Logout',
                    style: RooteryTheme.ui(
                      14,
                      color: RooteryTheme.redAlert,
                      weight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    'End current session',
                    style: RooteryTheme.ui(11, color: RooteryTheme.textMid),
                  ),
                  onTap: () {},
                ),
              ),
              const AppFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _switchTile(String title, bool value, ValueChanged<bool> onChanged) {
    return Semantics(
      label: '$title setting',
      toggled: value,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: RooteryTheme.cardDecoration(radius: 20),
        child: SwitchListTile(
          title: Text(title, style: RooteryTheme.ui(14)),
          subtitle: Text(
            value ? 'Enabled' : 'Disabled',
            style: RooteryTheme.ui(11, color: RooteryTheme.textLow),
          ),
          value: value,
          activeColor: RooteryTheme.green400,
          activeTrackColor: RooteryTheme.green100,
          inactiveTrackColor: RooteryTheme.borderLight,
          inactiveThumbColor: RooteryTheme.textLow,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
