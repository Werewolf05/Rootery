import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_models.dart';

class BatchService {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<HydroBatch>? _localCache;

  Future<List<HydroBatch>> getBatches() async {
    if (_localCache != null) {
      return List<HydroBatch>.from(_localCache!);
    }

    try {
      final rows = await _supabase
          .from('hydro_batches')
          .select()
          .order('planting_date', ascending: false);
      final mapped = List<Map<String, dynamic>>.from(
        rows,
      ).map(HydroBatch.fromJson).toList();
      _localCache = mapped;
      return List<HydroBatch>.from(mapped);
    } catch (_) {
      // No demo fallback: default to empty batches when backend is unavailable.
      _localCache = <HydroBatch>[];
      return const <HydroBatch>[];
    }
  }

  Future<void> createBatch(HydroBatch batch) async {
    await _supabase.from('hydro_batches').insert(batch.toJson());
    final cache = _localCache ??= <HydroBatch>[];
    cache.insert(0, batch);
  }

  Future<void> markCompleted(String batchId) async {
    await _supabase
        .from('hydro_batches')
        .update({'status': BatchStatus.completed.name})
        .eq('id', batchId);

    final cache = _localCache;
    if (cache != null) {
      final index = cache.indexWhere((b) => b.id == batchId);
      if (index != -1) {
        final current = cache[index];
        cache[index] = HydroBatch(
          id: current.id,
          batchName: current.batchName,
          cropType: current.cropType,
          plantingDate: current.plantingDate,
          expectedHarvestDate: current.expectedHarvestDate,
          growthDurationDays: current.growthDurationDays,
          status: BatchStatus.completed,
        );
      }
    }
  }

  Future<void> deleteBatch(String batchId) async {
    await _supabase.from('hydro_batches').delete().eq('id', batchId);
    final cache = _localCache;
    cache?.removeWhere((b) => b.id == batchId);
  }
}
