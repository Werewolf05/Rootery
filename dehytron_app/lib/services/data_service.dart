import 'dart:async';
import '../models/app_models.dart';
import 'supabase_service.dart';
import 'telemetry_service.dart';
import 'notification_service.dart';

class DataService {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  final _supabase = SupabaseService();
  final _telemetryService = TelemetryService();
  final _notificationService = NotificationService();

  // Set to true once database_setup.sql is executed in Supabase
  static const bool enableSupabasePolling = true;

  // Real-time sensor data stream
  final _sensorDataController = StreamController<SensorData>.broadcast();
  Stream<SensorData> get sensorDataStream => _sensorDataController.stream;

  final _telemetryStatusController =
      StreamController<TelemetryConnectionInfo>.broadcast();
  Stream<TelemetryConnectionInfo> get telemetryStatusStream =>
      _telemetryStatusController.stream;

  // Alert stream for insights page.
  final _alertsController = StreamController<List<SystemAlert>>.broadcast();
  Stream<List<SystemAlert>> get alertsStream => _alertsController.stream;

  // Drying progress stream
  final _progressController = StreamController<DryingProgress>.broadcast();
  Stream<DryingProgress> get progressStream => _progressController.stream;

  // Current values
  SensorData? _currentSensorData;
  DryingProgress? _currentProgress;
  List<SystemAlert> _currentAlerts = [];
  List<DryingBatch> _batches = [];
  List<Product> _products = [];

  Timer? _pollingTimer;
  StreamSubscription<TelemetryConnectionInfo>? _telemetryStatusSub;
  final Set<String> _seenReadingKeys = <String>{};
  DateTime? _latestSensorTimestamp;
  TelemetryConnectionInfo _currentTelemetryStatus =
      const TelemetryConnectionInfo(
        state: TelemetryConnectionState.connecting,
        message: 'Initializing telemetry...',
      );
  final Map<String, DateTime> _notificationThrottle = {};

  Future<void> initialize() async {
    await _notificationService.initialize();
    if (enableSupabasePolling) {
      await _loadInitialData();
      _telemetryStatusSub = _telemetryService.connectionStream.listen((status) {
        _currentTelemetryStatus = status;
        _telemetryStatusController.add(status);
      });
      _telemetryService.subscribeSensorData(_handleIncomingSensorData);
      _startPolling();
    } else {
      print(
        'Supabase polling disabled. Set enableSupabasePolling = true after database setup.',
      );
    }
  }

  Future<void> _loadInitialData() async {
    try {
      // Load products from Supabase
      final productsData = await _supabase.getProducts();
      _products = productsData.map((json) => Product.fromJson(json)).toList();

      // Load batches from Supabase
      final batchesData = await _supabase.getDryingBatches();
      _batches = batchesData.map((json) => DryingBatch.fromJson(json)).toList();

      // Load latest telemetry data from telemetry table.
      final sensorData = await _telemetryService.getLatestSensorData();
      if (sensorData != null) {
        _currentSensorData = sensorData;
        _sensorDataController.add(_currentSensorData!);
        _recomputeAlerts(sensorData);
      }

      // Load current drying progress
      final progressData = await _supabase.getCurrentDryingProgress();
      if (progressData != null) {
        _currentProgress = DryingProgress.fromJson(progressData);
        _progressController.add(_currentProgress!);
      }
    } catch (e) {
      print('Error loading initial data: $e');
      // Fallback to empty lists if Supabase fails
      _products = [];
      _batches = [];
    }
  }

  void _startPolling() {
    if (!enableSupabasePolling) return;

    // Poll sensor telemetry every 3 seconds (realtime is still primary).
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        final sensorData = await _telemetryService.getLatestSensorData();
        if (sensorData != null) {
          _handleIncomingSensorData(sensorData);
        }

        final progressData = await _supabase.getCurrentDryingProgress();
        if (progressData != null) {
          _currentProgress = DryingProgress.fromJson(progressData);
          _progressController.add(_currentProgress!);
        }
      } catch (e) {
        print('Polling error: $e');
      }
    });
  }

  // Getters
  SensorData? get currentSensorData => _currentSensorData;
  List<SystemAlert> get currentAlerts => List.unmodifiable(_currentAlerts);
  DryingProgress? get currentProgress => _currentProgress;
  List<DryingBatch> get batches => List.unmodifiable(_batches);
  List<Product> get products => List.unmodifiable(_products);
  TelemetryConnectionInfo get currentTelemetryStatus => _currentTelemetryStatus;

  // Methods
  Future<void> startDrying(
    String cropType,
    double weight,
    double initialMoisture,
    double targetMoisture,
  ) async {
    try {
      final batchId = 'B${DateTime.now().millisecondsSinceEpoch}';
      await _supabase.startDrying(
        batchId: batchId,
        cropType: cropType,
        currentMoisture: initialMoisture,
        targetMoisture: targetMoisture,
      );

      // Update local state
      _currentProgress = DryingProgress(
        batchId: batchId,
        status: 'In Progress',
        progress: 0.0,
        estimatedTimeRemaining: const Duration(hours: 10),
        cropType: cropType,
        currentMoisture: initialMoisture,
        targetMoisture: targetMoisture,
      );
      _progressController.add(_currentProgress!);
    } catch (e) {
      print('Error starting drying: $e');
      rethrow;
    }
  }

  Future<void> stopDrying() async {
    if (_currentProgress != null) {
      try {
        await _supabase.stopDrying(_currentProgress!.batchId);

        // Update local state
        _currentProgress = DryingProgress(
          batchId: _currentProgress!.batchId,
          status: 'Stopped',
          progress: _currentProgress!.progress,
          estimatedTimeRemaining: Duration.zero,
          cropType: _currentProgress!.cropType,
          currentMoisture: _currentProgress!.currentMoisture,
          targetMoisture: _currentProgress!.targetMoisture,
        );
        _progressController.add(_currentProgress!);
      } catch (e) {
        print('Error stopping drying: $e');
        rethrow;
      }
    }
  }

  Future<void> addBatch(DryingBatch batch) async {
    try {
      await _supabase.insertDryingBatch(batch.toJson());
      _batches.insert(0, batch);
    } catch (e) {
      print('Error adding batch: $e');
      rethrow;
    }
  }

  Future<List<Product>> searchProducts(String query, String category) async {
    try {
      List<Map<String, dynamic>> productsData;

      if (query.isNotEmpty) {
        productsData = await _supabase.searchProducts(query);
      } else {
        productsData = await _supabase.getProducts(
          category: category != 'All' ? category : null,
        );
      }

      final products = productsData
          .map((json) => Product.fromJson(json))
          .toList();

      // Apply category filter if searching
      if (query.isNotEmpty && category != 'All') {
        return products.where((p) => p.category == category).toList();
      }

      return products;
    } catch (e) {
      print('Error searching products: $e');
      return [];
    }
  }

  Future<void> refreshData() async {
    await _loadInitialData();
  }

  void _handleIncomingSensorData(SensorData sensorData) {
    final key =
        '${sensorData.deviceId}_${sensorData.lastUpdate.toIso8601String()}_${sensorData.phLevel.toStringAsFixed(2)}_${sensorData.tdsLevel.toStringAsFixed(0)}';
    if (_seenReadingKeys.contains(key)) {
      return;
    }
    _seenReadingKeys.add(key);
    if (_seenReadingKeys.length > 4000) {
      _seenReadingKeys.remove(_seenReadingKeys.first);
    }

    if (_latestSensorTimestamp != null &&
        sensorData.lastUpdate.isBefore(_latestSensorTimestamp!)) {
      // Keep historic reading deduped, but do not regress current state with older points.
      return;
    }

    _latestSensorTimestamp = sensorData.lastUpdate;
    _currentSensorData = sensorData;
    _sensorDataController.add(sensorData);
    _recomputeAlerts(sensorData);
  }

  void _recomputeAlerts(SensorData data) {
    final alerts = <SystemAlert>[];

    if (data.phLevel < 5.5) {
      alerts.add(
        SystemAlert(
          id: 'ph_low',
          title: 'pH too low',
          message: 'Current pH is ${data.phLevel.toStringAsFixed(2)}',
          severity: AlertSeverity.warning,
          suggestion: 'Dose pH up solution in small increments and retest.',
          createdAt: DateTime.now(),
        ),
      );
      _notifyWithCooldown(
        key: 'ph',
        action: () => _notificationService.showPhOutOfRangeAlert(data.phLevel),
      );
    } else if (data.phLevel > 6.8) {
      alerts.add(
        SystemAlert(
          id: 'ph_high',
          title: 'pH too high',
          message: 'Current pH is ${data.phLevel.toStringAsFixed(2)}',
          severity: AlertSeverity.warning,
          suggestion: 'Add pH down to bring nutrient uptake back in range.',
          createdAt: DateTime.now(),
        ),
      );
      _notifyWithCooldown(
        key: 'ph',
        action: () => _notificationService.showPhOutOfRangeAlert(data.phLevel),
      );
    }

    if (data.tdsLevel > 900) {
      alerts.add(
        SystemAlert(
          id: 'tds_high',
          title: 'TDS high',
          message: 'Current TDS is ${data.tdsLevel.toStringAsFixed(0)} ppm',
          severity: AlertSeverity.warning,
          suggestion: 'Flush system when TDS exceeds 900 ppm.',
          createdAt: DateTime.now(),
        ),
      );
      _notifyWithCooldown(
        key: 'tds',
        action: () => _notificationService.showTdsHighAlert(data.tdsLevel),
      );
    }

    if (data.reservoirLevel < 25) {
      alerts.add(
        SystemAlert(
          id: 'reservoir_low',
          title: 'Reservoir level low',
          message:
              'Reservoir level at ${data.reservoirLevel.toStringAsFixed(0)}%',
          severity: AlertSeverity.critical,
          suggestion: 'Refill reservoir and inspect inlet valves.',
          createdAt: DateTime.now(),
        ),
      );
      _notifyWithCooldown(
        key: 'reservoir',
        action: () =>
            _notificationService.showLowReservoirAlert(data.reservoirLevel),
      );
    }

    if (!data.isOnline) {
      alerts.add(
        SystemAlert(
          id: 'offline',
          title: 'Device offline',
          message: '${data.deviceId} has stopped reporting telemetry.',
          severity: AlertSeverity.critical,
          suggestion: 'Check ESP32 power and network connectivity.',
          createdAt: DateTime.now(),
        ),
      );
      _notifyWithCooldown(
        key: 'offline',
        action: () =>
            _notificationService.showDeviceOfflineAlert(data.deviceId),
      );
    }

    _currentAlerts = alerts;
    _alertsController.add(List.unmodifiable(_currentAlerts));
  }

  void _notifyWithCooldown({
    required String key,
    required Future<void> Function() action,
  }) {
    final now = DateTime.now();
    final last = _notificationThrottle[key];
    if (last != null && now.difference(last).inMinutes < 10) {
      return;
    }
    _notificationThrottle[key] = now;
    action();
  }

  void dispose() {
    _pollingTimer?.cancel();
    _telemetryStatusSub?.cancel();
    _telemetryService.dispose();
    _telemetryStatusController.close();
    _sensorDataController.close();
    _progressController.close();
    _alertsController.close();
  }
}
