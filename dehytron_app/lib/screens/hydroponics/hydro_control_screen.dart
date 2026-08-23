import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../services/command_service.dart';
import '../../theme/rootery_theme.dart';
import '../../widgets/app_footer.dart';
import '../../widgets/control_switch_tile.dart';

class HydroControlScreen extends StatefulWidget {
  const HydroControlScreen({super.key});

  @override
  State<HydroControlScreen> createState() => _HydroControlScreenState();
}

class _HydroControlScreenState extends State<HydroControlScreen>
    with SingleTickerProviderStateMixin {
  final CommandService _commandService = CommandService();

  final Map<String, bool> _states = {
    'autoCycle': false,
    'pump': false,
    'aeration': false,
    'nutrientA': false,
    'nutrientB': false,
    'sprinkler': false,
    'lights': false,
  };

  final Map<String, DateTime?> _lastActivation = {
    'pump': null,
    'aeration': null,
    'nutrientA': null,
    'nutrientB': null,
    'sprinkler': null,
    'lights': null,
  };

  bool _busy = false;

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

  Future<void> _run(
    String key,
    Future<void> Function() action,
    bool state,
  ) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      setState(() {
        _states[key] = state;
        _lastActivation[key] = DateTime.now();
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _sectionHeader(String title, {String? trailing}) {
    return Row(
      children: [
        Text(
          title.toUpperCase(),
          style: RooteryTheme.ui(
            13,
            weight: FontWeight.w500,
            color: RooteryTheme.textMid,
            letterSpacing: 0.3,
          ),
        ),
        const Spacer(),
        if (trailing != null)
          Text(
            trailing,
            style: RooteryTheme.mono(
              11,
              color: RooteryTheme.textLow,
              letterSpacing: 0.8,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      ControlSwitchTile(
        title: 'Automatic Pump + Sprinkler',
        subtitle: 'Start both actuators together',
        icon: Icons.auto_mode,
        value: _states['autoCycle']!,
        busy: _busy,
        lastActivatedAt: _lastActivation['autoCycle'],
        onChanged: (v) => _run('autoCycle', () async {
          await _commandService.setMode(v ? 'AUTO' : 'MANUAL');
          await _commandService.setPump(v);
          await _commandService.setSprinkler(v);
        }, v),
      ),
      ControlSwitchTile(
        title: 'Water Circulation Pump',
        subtitle: 'Main nutrient flow loop',
        icon: Icons.water,
        value: _states['pump']!,
        busy: _busy,
        lastActivatedAt: _lastActivation['pump'],
        onChanged: (v) => _run('pump', () => _commandService.setPump(v), v),
      ),
      ControlSwitchTile(
        title: 'Aeration Pump',
        subtitle: 'Dissolved oxygen control',
        icon: Icons.air,
        value: _states['aeration']!,
        busy: _busy,
        lastActivatedAt: _lastActivation['aeration'],
        onChanged: (v) =>
            _run('aeration', () => _commandService.setAeration(v), v),
      ),
      ControlSwitchTile(
        title: 'Nutrient Dosing A',
        subtitle: 'Dose macro nutrient A',
        icon: Icons.biotech,
        value: _states['nutrientA']!,
        busy: _busy,
        lastActivatedAt: _lastActivation['nutrientA'],
        onChanged: (v) => _run(
          'nutrientA',
          () => v ? _commandService.doseNutrientA() : Future.value(),
          v,
        ),
      ),
      ControlSwitchTile(
        title: 'Nutrient Dosing B',
        subtitle: 'Dose macro nutrient B',
        icon: Icons.biotech_outlined,
        value: _states['nutrientB']!,
        busy: _busy,
        lastActivatedAt: _lastActivation['nutrientB'],
        onChanged: (v) => _run(
          'nutrientB',
          () => v ? _commandService.doseNutrientB() : Future.value(),
          v,
        ),
      ),
      ControlSwitchTile(
        title: 'Sprinkler System',
        subtitle: 'Foliar and misting cycle',
        icon: Icons.shower,
        value: _states['sprinkler']!,
        busy: _busy,
        lastActivatedAt: _lastActivation['sprinkler'],
        onChanged: (v) =>
            _run('sprinkler', () => _commandService.setSprinkler(v), v),
      ),
      ControlSwitchTile(
        title: 'Grow Lights',
        subtitle: 'Primary photosynthetic lighting',
        icon: Icons.light_mode,
        value: _states['lights']!,
        busy: _busy,
        lastActivatedAt: _lastActivation['lights'],
        onChanged: (v) => _run('lights', () => _commandService.setLights(v), v),
      ),
    ];

    return Scaffold(
      backgroundColor: RooteryTheme.bgScaffold,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: RooteryTheme.bgSurface,
        title: Text(
          'Manual Control',
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
              _sectionHeader('Safety', trailing: 'Operator mode'),
              const SizedBox(height: 8),
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: RooteryTheme.amberWarn.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: RooteryTheme.amberWarn.withOpacity(0.45),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: RooteryTheme.amberWarn,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Warning: Manual mode overrides automation rules.',
                        style: RooteryTheme.ui(
                          14,
                          color: RooteryTheme.textHigh,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _sectionHeader('Automation'),
              const SizedBox(height: 8),
              AnimationLimiter(
                child: Column(
                  children: [
                    AnimationConfiguration.staggeredList(
                      position: 0,
                      delay: const Duration(milliseconds: 60),
                      child: SlideAnimation(
                        verticalOffset: 16,
                        child: FadeInAnimation(child: items.first),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _sectionHeader('Actuators'),
              const SizedBox(height: 8),
              AnimationLimiter(
                child: Column(
                  children: List.generate(items.length - 1, (index) {
                    return AnimationConfiguration.staggeredList(
                      position: index + 1,
                      delay: const Duration(milliseconds: 60),
                      child: SlideAnimation(
                        verticalOffset: 16,
                        child: FadeInAnimation(child: items[index + 1]),
                      ),
                    );
                  }),
                ),
              ),
              const AppFooter(),
            ],
          ),
        ),
      ),
    );
  }
}
