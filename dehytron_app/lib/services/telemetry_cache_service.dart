import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';

class TelemetryCacheService {
  static const String _dbName = 'telemetry_cache.db';
  static const String _storeName = 'telemetry';
  static const int _maxRecords = 5000;

  final StoreRef<String, Map<String, dynamic>> _store = stringMapStoreFactory
      .store(_storeName);

  Database? _db;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized && _db != null) {
      return;
    }

    final Directory appDir = await getApplicationDocumentsDirectory();
    final String dbPath = p.join(appDir.path, _dbName);
    final DatabaseFactory dbFactory = databaseFactoryIo;
    _db = await dbFactory.openDatabase(dbPath);
    _initialized = true;
  }

  Future<void> saveReading(Map<String, dynamic> row) async {
    await initialize();
    final db = _db;
    if (db == null) return;

    final normalized = _normalizeRow(row);
    final key = _rowKey(normalized);

    await _store.record(key).put(db, normalized);
    await _compactIfNeeded(db);
  }

  Future<void> saveReadings(List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return;
    await initialize();
    final db = _db;
    if (db == null) return;

    await db.transaction((txn) async {
      for (final row in rows) {
        final normalized = _normalizeRow(row);
        final key = _rowKey(normalized);
        await _store.record(key).put(txn, normalized);
      }
    });

    await _compactIfNeeded(db);
  }

  Future<Map<String, dynamic>?> getLatest() async {
    await initialize();
    final db = _db;
    if (db == null) return null;

    final records = await _store.find(
      db,
      finder: Finder(sortOrders: [SortOrder('created_at', false)], limit: 1),
    );

    if (records.isEmpty) return null;
    return Map<String, dynamic>.from(records.first.value);
  }

  Future<List<Map<String, dynamic>>> getRecent({
    int limit = 50,
    DateTime? since,
  }) async {
    await initialize();
    final db = _db;
    if (db == null) return <Map<String, dynamic>>[];

    final finder = Finder(
      filter: since == null
          ? null
          : Filter.greaterThanOrEquals('created_at', since.toIso8601String()),
      sortOrders: [SortOrder('created_at', false)],
      limit: limit,
    );

    final records = await _store.find(db, finder: finder);
    return records.map((r) => Map<String, dynamic>.from(r.value)).toList();
  }

  Future<void> _compactIfNeeded(Database db) async {
    final count = await _store.count(db);
    if (count <= _maxRecords) return;

    final overflow = count - _maxRecords;
    final oldRecords = await _store.find(
      db,
      finder: Finder(sortOrders: [SortOrder('created_at')], limit: overflow),
    );

    if (oldRecords.isEmpty) return;
    await db.transaction((txn) async {
      for (final rec in oldRecords) {
        await _store.record(rec.key).delete(txn);
      }
    });
  }

  String _rowKey(Map<String, dynamic> row) {
    final id = row['id']?.toString() ?? '';
    final device = row['device_id']?.toString() ?? 'UNKNOWN';
    final createdAt = row['created_at']?.toString() ?? '';
    final ph = row['ph']?.toString() ?? row['ph_level']?.toString() ?? '';
    final tds =
        row['tds_ppm']?.toString() ?? row['tds_level']?.toString() ?? '';
    if (id.isNotEmpty) {
      return '$device|$id|$createdAt';
    }
    return '$device|$createdAt|$ph|$tds';
  }

  Map<String, dynamic> _normalizeRow(Map<String, dynamic> row) {
    final out = <String, dynamic>{};
    row.forEach((key, value) {
      if (value == null || value is String || value is num || value is bool) {
        out[key] = value;
      } else {
        out[key] = value.toString();
      }
    });

    out['created_at'] =
        (out['created_at'] ?? out['last_update'] ?? out['timestamp'] ?? '')
            .toString();
    return out;
  }

  Future<void> dispose() async {
    final db = _db;
    _db = null;
    _initialized = false;
    if (db != null) {
      await db.close();
    }
  }
}
