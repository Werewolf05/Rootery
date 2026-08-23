import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../models/app_models.dart';
import '../../services/auth_service.dart';
import '../../services/command_service.dart';
import '../../services/data_service.dart';
import '../../theme/rootery_theme.dart';
import '../../widgets/app_footer.dart';
import '../../widgets/control_switch_tile.dart';
import '../../widgets/sensor_card.dart';
import '../../widgets/stat_card.dart';

class HydroDashboardScreen extends StatefulWidget {
  const HydroDashboardScreen({super.key});

  @override
  State<HydroDashboardScreen> createState() => _HydroDashboardScreenState();
}

class _HydroDashboardScreenState extends State<HydroDashboardScreen>
    with SingleTickerProviderStateMixin {
  static const bool _frontendOnlyDemo = false;

  final DataService _dataService = DataService();
  final CommandService _commandService = CommandService();

  SensorData? _sensor;
  bool _pumpOn = false;
  bool _lightsOn = false;
  bool _loadingPump = false;
  bool _loadingLights = false;
  String _displayName = 'Farmer';

  StreamSubscription<SensorData>? _sub;
  Timer? _mockTimer;
  Timer? _clockTicker;
  DateTime _now = DateTime.now();

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

    _clockTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
    });

    _loadDisplayName();
    _maybePromptForName();

    if (_frontendOnlyDemo) {
      _sensor = SensorData(
        deviceId: 'demo-device-01',
        phLevel: 6.2,
        tdsLevel: 850,
        waterTemperature: 22.4,
        airTemperature: 24.1,
        airHumidity: 65,
        reservoirLevel: 95,
        pumpOn: true,
        sprinklerOn: false,
        autoState: 0,
        isOnline: true,
        lastUpdate: DateTime.now(),
      );
      _pumpOn = true;
      _lightsOn = true;
      _mockTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (!mounted || _sensor == null) return;
        setState(() {
          final now = DateTime.now();
          _sensor = SensorData(
            deviceId: 'demo-device-01',
            phLevel: _sensor!.phLevel,
            tdsLevel: _sensor!.tdsLevel,
            waterTemperature: _sensor!.waterTemperature,
            airTemperature: _sensor!.airTemperature,
            airHumidity: _sensor!.airHumidity,
            reservoirLevel: _sensor!.reservoirLevel,
            pumpOn: _sensor!.pumpOn,
            sprinklerOn: _sensor!.sprinklerOn,
            autoState: _sensor!.autoState,
            isOnline: true,
            lastUpdate: now,
          );
        });
      });
      return;
    }

    _sensor = _dataService.currentSensorData;
    _sub = _dataService.sensorDataStream.listen((event) {
      if (!mounted) return;
      setState(() => _sensor = event);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _mockTimer?.cancel();
    _clockTicker?.cancel();
    _enterCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDisplayName() async {
    final name = await AuthService.getDisplayName();
    if (!mounted) return;
    setState(() => _displayName = name);
  }

  Future<void> _maybePromptForName() async {
    final hasName = await AuthService.hasSavedDisplayName();
    if (!mounted) return;
    if (hasName) return;

    // Defer showing dialog until after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showNamePrompt();
    });
  }

  Future<void> _showNamePrompt() async {
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Welcome'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please enter a name to display in the app'),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: const InputDecoration(labelText: 'Name'),
                textCapitalization: TextCapitalization.words,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final val = controller.text.trim();
                if (val.isEmpty) return;
                await AuthService.saveDisplayName(val);
                if (!mounted) return;
                setState(() => _displayName = val);
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _refreshUiOnly() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted || _sensor == null) return;
    setState(() {
      _sensor = SensorData(
        deviceId: _sensor!.deviceId,
        phLevel: _sensor!.phLevel,
        tdsLevel: _sensor!.tdsLevel,
        waterTemperature: _sensor!.waterTemperature,
        airTemperature: _sensor!.airTemperature,
        airHumidity: _sensor!.airHumidity,
        reservoirLevel: _sensor!.reservoirLevel,
        pumpOn: _sensor!.pumpOn,
        sprinklerOn: _sensor!.sprinklerOn,
        autoState: _sensor!.autoState,
        isOnline: true,
        lastUpdate: DateTime.now(),
      );
    });
  }

  SensorStatus _statusFor(String metric, double value) {
    switch (metric) {
      case 'ph':
        if (value < 5.5 || value > 6.8) return SensorStatus.alert;
        if (value >= 5.8 && value <= 6.4) return SensorStatus.optimal;
        return SensorStatus.warning;
      case 'tds':
        if (value > 900) return SensorStatus.alert;
        if (value >= 600 && value <= 850) return SensorStatus.optimal;
        return SensorStatus.warning;
      case 'reservoir':
        if (value < 25) return SensorStatus.alert;
        if (value >= 45 && value <= 90) return SensorStatus.optimal;
        return SensorStatus.warning;
      default:
        return SensorStatus.optimal;
    }
  }

  Future<void> _togglePump(bool enabled) async {
    if (_frontendOnlyDemo) {
      setState(() => _pumpOn = enabled);
      return;
    }

    setState(() => _loadingPump = true);
    try {
      await _commandService.setPump(enabled);
      if (!mounted) return;
      setState(() => _pumpOn = enabled);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to update water pump right now')),
      );
    } finally {
      if (mounted) setState(() => _loadingPump = false);
    }
  }

  Future<void> _toggleLights(bool enabled) async {
    if (_frontendOnlyDemo) {
      setState(() => _lightsOn = enabled);
      return;
    }

    setState(() => _loadingLights = true);
    try {
      await _commandService.setSprinkler(enabled);
      if (!mounted) return;
      setState(() => _lightsOn = enabled);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to update sprinkler right now')),
      );
    } finally {
      if (mounted) setState(() => _loadingLights = false);
    }
  }

  String _greeting() {
    final hour = _now.hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Widget _sectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: RooteryTheme.ui(
        13,
        weight: FontWeight.w500,
        color: RooteryTheme.textMid,
        letterSpacing: 0.3,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = _sensor;
    final clockLabel =
        '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}';

    final statCards = [
      StatCard(
        icon: Icons.forest,
        label: 'Farm Name',
        value: 'Rootery',
        color: RooteryTheme.green400,
      ),
      StatCard(
        icon: Icons.bolt,
        label: 'Uptime',
        value: '99.8%',
        color: RooteryTheme.blueInfo,
      ),
      StatCard(
        icon: Icons.timelapse,
        label: 'Cycle Day',
        value: '14',
        unit: 'd',
        color: RooteryTheme.green400,
        trend: '+1d',
      ),
      StatCard(
        icon: Icons.warning_amber_rounded,
        label: 'Active Alerts',
        value: '2',
        color: RooteryTheme.amberWarn,
        trend: '-1',
        isTrendPositive: true,
      ),
    ];

    final sensors = [
      SensorCard(
        label: 'pH',
        value: s?.phLevel ?? 6.2,
        unit: '',
        status: _statusFor('ph', s?.phLevel ?? 6.2),
        minVal: 5.5,
        maxVal: 6.8,
        icon: Icons.science_outlined,
      ),
      SensorCard(
        label: 'TDS Level',
        value: s?.tdsLevel ?? 850,
        unit: 'ppm',
        status: _statusFor('tds', s?.tdsLevel ?? 850),
        minVal: 600,
        maxVal: 1000,
        icon: Icons.opacity,
      ),
      SensorCard(
        label: 'Water Temp',
        value: s?.waterTemperature ?? 22.4,
        unit: 'C',
        status: SensorStatus.optimal,
        minVal: 18,
        maxVal: 28,
        icon: Icons.thermostat_outlined,
      ),
      SensorCard(
        label: 'Air Temp',
        value: s?.airTemperature ?? 24.1,
        unit: 'C',
        status: SensorStatus.optimal,
        minVal: 18,
        maxVal: 32,
        icon: Icons.air,
      ),
      SensorCard(
        label: 'Air Humidity',
        value: s?.airHumidity ?? 65,
        unit: '%',
        status: SensorStatus.warning,
        minVal: 40,
        maxVal: 85,
        icon: Icons.water_drop_outlined,
      ),
      SensorCard(
        label: 'Reservoir Level',
        value: s?.reservoirLevel ?? 95,
        unit: '%',
        status: _statusFor('reservoir', s?.reservoirLevel ?? 95),
        minVal: 20,
        maxVal: 100,
        icon: Icons.waves_outlined,
      ),
    ];

    return Scaffold(
      backgroundColor: RooteryTheme.bgScaffold,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: RooteryTheme.bgSurface,
        titleSpacing: 16,
        title: Text(
          '${_greeting()}, $_displayName',
          style: RooteryTheme.ui(18, weight: FontWeight.w600),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                _PulsingDot(isOnline: s?.isOnline ?? false),
                const SizedBox(width: 8),
                Text(
                  clockLabel,
                  style: RooteryTheme.mono(12, color: RooteryTheme.textMid),
                ),
              ],
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: RefreshIndicator(
            color: RooteryTheme.green400,
            onRefresh: _frontendOnlyDemo
                ? _refreshUiOnly
                : _dataService.refreshData,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _sectionHeader('Farm Stats'),
                const SizedBox(height: 10),
                SizedBox(
                  height: 150,
                  child: AnimationLimiter(
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: statCards.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        return AnimationConfiguration.staggeredList(
                          position: index,
                          delay: const Duration(milliseconds: 60),
                          child: SlideAnimation(
                            verticalOffset: 16,
                            child: FadeInAnimation(
                              child: SizedBox(
                                width: 180,
                                child: statCards[index],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _sectionHeader('Live Sensors'),
                const SizedBox(height: 10),
                AnimationLimiter(
                  child: GridView.builder(
                    itemCount: sensors.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.92,
                        ),
                    itemBuilder: (context, index) {
                      return AnimationConfiguration.staggeredGrid(
                        position: index,
                        columnCount: 2,
                        delay: const Duration(milliseconds: 60),
                        child: SlideAnimation(
                          verticalOffset: 16,
                          child: FadeInAnimation(child: sensors[index]),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                _sectionHeader('Quick Controls'),
                const SizedBox(height: 10),
                AnimationLimiter(
                  child: Column(
                    children: [
                      AnimationConfiguration.staggeredList(
                        position: 0,
                        delay: const Duration(milliseconds: 60),
                        child: SlideAnimation(
                          verticalOffset: 16,
                          child: FadeInAnimation(
                            child: ControlSwitchTile(
                              title: 'Water Pump',
                              subtitle: 'Nutrient flow loop',
                              icon: Icons.water_drop,
                              value: _pumpOn,
                              busy: _loadingPump,
                              onChanged: _togglePump,
                            ),
                          ),
                        ),
                      ),
                      AnimationConfiguration.staggeredList(
                        position: 1,
                        delay: const Duration(milliseconds: 60),
                        child: SlideAnimation(
                          verticalOffset: 16,
                          child: FadeInAnimation(
                            child: ControlSwitchTile(
                              title: 'Sprinkler',
                              subtitle: 'Automated irrigation line',
                              icon: Icons.grass,
                              value: _lightsOn,
                              busy: _loadingLights,
                              onChanged: _toggleLights,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const AppFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.isOnline});

  final bool isOnline;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dotColor = widget.isOnline
        ? RooteryTheme.green400
        : RooteryTheme.redAlert;
    return Stack(
      alignment: Alignment.center,
      children: [
        FadeTransition(
          opacity: Tween<double>(begin: 0.2, end: 0.7).animate(_controller),
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: dotColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
      ],
    );
  }
}
