import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'dart:math';
import '../models/app_models.dart';
import 'telemetry_cache_service.dart';

enum TelemetryConnectionState {
  connecting,
  connected,
  reconnecting,
  offline,
  error,
}

class TelemetryConnectionInfo {
  final TelemetryConnectionState state;
  final String message;
  final int? retryInSeconds;

  const TelemetryConnectionInfo({
    required this.state,
    required this.message,
    this.retryInSeconds,
  });
}

class TelemetryService {
  final supabase = Supabase.instance.client;
  final List<RealtimeChannel> _channels = [];
  final _rawTelemetryController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _sensorStreamController = StreamController<SensorData>.broadcast();
  final _connectionStreamController =
      StreamController<TelemetryConnectionInfo>.broadcast();
  static const List<String> _telemetryTables = [
    'sensor_telemetry',
    'telemetry',
  ];
  final TelemetryCacheService _cacheService = TelemetryCacheService();

  String? _activeTelemetryTable;
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;
  bool _isDisposed = false;

  final Set<String> _seenEventKeys = <String>{};
  static const int _maxSeenKeys = 6000;

  TelemetryConnectionInfo _currentConnection = const TelemetryConnectionInfo(
    state: TelemetryConnectionState.connecting,
    message: 'Connecting to telemetry stream...',
  );

  Stream<SensorData> get sensorStream => _sensorStreamController.stream;
  Stream<TelemetryConnectionInfo> get connectionStream =>
      _connectionStreamController.stream;
  TelemetryConnectionInfo get currentConnection => _currentConnection;

  Future<void> _initCache() async {
    await _cacheService.initialize();
  }

  void _emitConnection(TelemetryConnectionInfo info) {
    _currentConnection = info;
    if (!_connectionStreamController.isClosed) {
      _connectionStreamController.add(info);
    }
  }

  bool _isMissingTableError(Object e) {
    final s = e.toString().toLowerCase();
    return s.contains('does not exist') ||
        s.contains('42p01') ||
        s.contains('not found');
  }

  Future<String?> _resolveTelemetryTable() async {
    if (_activeTelemetryTable != null) {
      return _activeTelemetryTable;
    }
    for (final table in _telemetryTables) {
      try {
        await supabase.from(table).select('id').limit(1);
        _activeTelemetryTable = table;
        return table;
      } catch (e) {
        if (!_isMissingTableError(e)) {
          // If it's a transient/network error we still prefer first table.
          _activeTelemetryTable = table;
          return table;
        }
      }
    }
    return _telemetryTables.first;
  }

  String _eventKeyFromRow(Map<String, dynamic> row) {
    final id = row['id']?.toString() ?? '';
    final device = row['device_id']?.toString() ?? '';
    final ts =
        (row['created_at'] ?? row['last_update'] ?? row['timestamp'])
            ?.toString() ??
        '';
    final ph = (row['ph'] ?? row['ph_level'])?.toString() ?? '';
    final tds = (row['tds_ppm'] ?? row['tds_level'])?.toString() ?? '';
    return '$id|$device|$ts|$ph|$tds';
  }

  bool _dedupeEvent(Map<String, dynamic> row) {
    final key = _eventKeyFromRow(row);
    if (_seenEventKeys.contains(key)) {
      return true;
    }
    _seenEventKeys.add(key);
    if (_seenEventKeys.length > _maxSeenKeys) {
      _seenEventKeys.remove(_seenEventKeys.first);
    }
    return false;
  }

  void _scheduleReconnect({String reason = 'Connection dropped'}) {
    if (_isDisposed) return;
    _reconnectTimer?.cancel();
    _reconnectAttempts++;
    final delay = min(30, pow(2, _reconnectAttempts).toInt());
    _emitConnection(
      TelemetryConnectionInfo(
        state: TelemetryConnectionState.reconnecting,
        message: '$reason. Reconnecting...',
        retryInSeconds: delay,
      ),
    );
    _reconnectTimer = Timer(Duration(seconds: delay), () {
      _subscribeRealtime();
    });
  }

  void _handleSubscribeStatus(dynamic status, String table, dynamic error) {
    final statusText = status.toString().toLowerCase();
    if (statusText.contains('subscribed')) {
      _reconnectAttempts = 0;
      _emitConnection(
        TelemetryConnectionInfo(
          state: TelemetryConnectionState.connected,
          message: 'Live telemetry connected ($table)',
        ),
      );
      return;
    }

    if (statusText.contains('channelerror') ||
        statusText.contains('timedout') ||
        statusText.contains('closed')) {
      _scheduleReconnect(reason: 'Realtime stream unavailable');
      return;
    }

    if (error != null) {
      _emitConnection(
        TelemetryConnectionInfo(
          state: TelemetryConnectionState.error,
          message: 'Realtime error: $error',
        ),
      );
    }
  }

  Future<void> _subscribeRealtime() async {
    if (_isDisposed) return;
    unsubscribe();
    final table = await _resolveTelemetryTable();
    final safeTable = table ?? _telemetryTables.first;

    _emitConnection(
      TelemetryConnectionInfo(
        state: TelemetryConnectionState.connecting,
        message: 'Connecting live telemetry...',
      ),
    );

    final channel = supabase
        .channel('public:$safeTable')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: safeTable,
          callback: (payload) {
            if (payload.newRecord.isEmpty) {
              return;
            }
            final mapped = Map<String, dynamic>.from(payload.newRecord);
            if (_dedupeEvent(mapped)) {
              return;
            }
            _cacheService.saveReading(mapped);
            _rawTelemetryController.add(mapped);
            _sensorStreamController.add(SensorData.fromJson(mapped));
          },
        )
        .subscribe((status, [error]) {
          _handleSubscribeStatus(status, safeTable, error);
        });

    _channels.add(channel);
  }

  /// Fetch the latest telemetry reading from ESP32
  Future<Map<String, dynamic>?> getLatestTelemetry() async {
    await _initCache();
    final active = await _resolveTelemetryTable();
    final candidates = <String>[
      if (active != null) active,
      ..._telemetryTables,
    ].toSet().toList();

    for (final table in candidates) {
      try {
        final response = await supabase
            .from(table)
            .select()
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();
        if (response != null) {
          await _cacheService.saveReading(response);
          _emitConnection(
            TelemetryConnectionInfo(
              state: TelemetryConnectionState.connected,
              message: 'Telemetry loaded from cloud',
            ),
          );
          return response;
        }
      } catch (e) {
        if (!_isMissingTableError(e)) {
          _emitConnection(
            const TelemetryConnectionInfo(
              state: TelemetryConnectionState.offline,
              message: 'Cloud unavailable. Using local cache.',
            ),
          );
        }
      }
    }

    return _cacheService.getLatest();
  }

  /// Fetch recent telemetry history (last N readings)
  Future<List<Map<String, dynamic>>> getRecentTelemetry({
    int limit = 50,
    DateTime? since,
  }) async {
    await _initCache();
    final active = await _resolveTelemetryTable();
    final candidates = <String>[
      if (active != null) active,
      ..._telemetryTables,
    ].toSet().toList();

    for (final table in candidates) {
      try {
        dynamic query = supabase.from(table).select();
        if (since != null) {
          query = query.gte('created_at', since.toIso8601String());
        }
        final response = await query
            .order('created_at', ascending: false)
            .limit(limit);

        final rows = List<Map<String, dynamic>>.from(response);
        if (rows.isNotEmpty) {
          await _cacheService.saveReadings(rows);
          return rows;
        }
      } catch (e) {
        if (!_isMissingTableError(e)) {
          _emitConnection(
            const TelemetryConnectionInfo(
              state: TelemetryConnectionState.offline,
              message: 'Cloud unavailable. Showing cached telemetry.',
            ),
          );
        }
      }
    }

    return _cacheService.getRecent(limit: limit, since: since);
  }

  Future<SensorData?> getLatestSensorData() async {
    final raw = await getLatestTelemetry();
    if (raw == null) return null;
    return SensorData.fromJson(raw);
  }

  /// Subscribe to real-time telemetry updates
  void subscribeToTelemetry(Function(Map<String, dynamic>) onUpdate) {
    _rawTelemetryController.stream.listen(onUpdate);
    _subscribeRealtime();
  }

  void subscribeSensorData(Function(SensorData) onUpdate) {
    _sensorStreamController.stream.listen(onUpdate);
    _subscribeRealtime();
  }

  /// Unsubscribe from real-time updates
  void unsubscribe() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    for (final channel in _channels) {
      channel.unsubscribe();
    }
    _channels.clear();
  }

  /// Get telemetry statistics
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final rows = await getRecentTelemetry(limit: 100);
      if (rows.isEmpty) return {};
      final data = rows.map(SensorData.fromJson).toList();

      double avgPh = 0;
      double avgTds = 0;
      double avgAirTemp = 0;
      double avgHumidity = 0;
      double maxPh = -999;
      double minPh = 999;
      double maxTds = -999;
      double minTds = 999;

      for (final reading in data) {
        final ph = reading.phLevel;
        final tds = reading.tdsLevel;
        final airTemp = reading.airTemperature;
        final humidity = reading.airHumidity;

        avgPh += ph;
        avgTds += tds;
        avgAirTemp += airTemp;
        avgHumidity += humidity;

        maxPh = ph > maxPh ? ph : maxPh;
        minPh = ph < minPh ? ph : minPh;
        maxTds = tds > maxTds ? tds : maxTds;
        minTds = tds < minTds ? tds : minTds;
      }

      final count = data.length;
      return {
        'total_readings': count,
        'avg_ph': avgPh / count,
        'avg_tds': avgTds / count,
        'avg_air_temperature': avgAirTemp / count,
        'avg_humidity': avgHumidity / count,
        'max_ph': maxPh,
        'min_ph': minPh,
        'max_tds': maxTds,
        'min_tds': minTds,
      };
    } catch (e) {
      print('Error calculating statistics: $e');
      return {};
    }
  }

  Future<List<SensorData>> getSensorSeries({
    required Duration period,
    int limit = 500,
  }) async {
    final since = DateTime.now().subtract(period);
    final rows = await getRecentTelemetry(limit: limit, since: since);
    final map = <String, SensorData>{};
    for (final row in rows) {
      final sensor = SensorData.fromJson(row);
      final key =
          '${sensor.deviceId}_${sensor.lastUpdate.toIso8601String()}_${sensor.phLevel.toStringAsFixed(2)}_${sensor.tdsLevel.toStringAsFixed(0)}';
      final existing = map[key];
      if (existing == null || sensor.lastUpdate.isAfter(existing.lastUpdate)) {
        map[key] = sensor;
      }
    }

    final ordered = map.values.toList()
      ..sort((a, b) => a.lastUpdate.compareTo(b.lastUpdate));
    return ordered;
  }

  void dispose() {
    _isDisposed = true;
    unsubscribe();
    _connectionStreamController.close();
    _rawTelemetryController.close();
    _cacheService.dispose();
    _sensorStreamController.close();
  }
}
