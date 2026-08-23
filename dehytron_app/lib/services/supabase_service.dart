import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  final _client = Supabase.instance.client;

  // ========== AUTH METHODS ==========

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? userData,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: userData,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final response = await _client
        .from('users')
        .select()
        .eq('id', userId)
        .maybeSingle();
    return response;
  }

  Future<void> updateUserProfile({
    required String userId,
    required Map<String, dynamic> updates,
  }) async {
    await _client.from('users').update(updates).eq('id', userId);
  }

  // ========== PRODUCT METHODS ==========

  Future<List<Map<String, dynamic>>> getProducts({String? category}) async {
    try {
      dynamic query = _client.from('products').select();

      if (category != null) {
        query = query.eq('category', category);
      }

      final response = await query.order('name', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching products: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    try {
      final response = await _client
          .from('products')
          .select()
          .ilike('name', '%$query%')
          .order('name', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error searching products: $e');
      return [];
    }
  }

  // ========== DRYING BATCH METHODS ==========

  Future<List<Map<String, dynamic>>> getDryingBatches() async {
    try {
      final response = await _client
          .from('drying_batches')
          .select()
          .order('start_time', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching drying batches: $e');
      return [];
    }
  }

  Future<void> insertDryingBatch(Map<String, dynamic> batch) async {
    await _client.from('drying_batches').insert(batch);
  }

  Future<void> startDrying({
    required String batchId,
    required String cropType,
    required double currentMoisture,
    required double targetMoisture,
  }) async {
    await _client.from('drying_batches').insert({
      'batch_id': batchId,
      'crop_type': cropType,
      'current_moisture': currentMoisture,
      'target_moisture': targetMoisture,
      'start_time': DateTime.now().toIso8601String(),
      'status': 'active',
    });
  }

  Future<void> stopDrying(String batchId) async {
    await _client
        .from('drying_batches')
        .update({
          'status': 'completed',
          'end_time': DateTime.now().toIso8601String(),
        })
        .eq('batch_id', batchId);
  }

  // ========== SENSOR DATA METHODS ==========

  Future<Map<String, dynamic>?> getLatestSensorData() async {
    try {
      final response = await _client
          .from('sensor_data')
          .select()
          .order('timestamp', ascending: false)
          .limit(1)
          .maybeSingle();
      return response;
    } catch (e) {
      print('Error fetching latest sensor data: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getSensorDataHistory({
    DateTime? startTime,
    DateTime? endTime,
    int? limit,
  }) async {
    try {
      dynamic query = _client.from('sensor_data').select();

      if (startTime != null) {
        query = query.gte('timestamp', startTime.toIso8601String());
      }
      if (endTime != null) {
        query = query.lte('timestamp', endTime.toIso8601String());
      }

      query = query.order('timestamp', ascending: false);

      if (limit != null) {
        query = query.limit(limit);
      }

      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching sensor data history: $e');
      return [];
    }
  }

  // ========== DRYING PROGRESS METHODS ==========

  Future<Map<String, dynamic>?> getCurrentDryingProgress() async {
    try {
      final response = await _client
          .from('drying_batches')
          .select()
          .eq('status', 'active')
          .order('start_time', ascending: false)
          .limit(1)
          .maybeSingle();
      return response;
    } catch (e) {
      print('Error fetching current drying progress: $e');
      return null;
    }
  }

  // ========== REPORT METHODS ==========

  Future<List<Map<String, dynamic>>> getReports({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      dynamic query = _client.from('drying_batches').select();

      if (startDate != null) {
        query = query.gte('start_time', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('start_time', endDate.toIso8601String());
      }

      query = query.order('start_time', ascending: false);

      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching reports: $e');
      return [];
    }
  }

  // ========== ESP32 DATA METHODS ==========

  Future<void> sendControlCommand({
    required String command,
    Map<String, dynamic>? parameters,
  }) async {
    await _client.from('control_commands').insert({
      'command': command,
      'parameters': parameters,
      'timestamp': DateTime.now().toIso8601String(),
      'status': 'pending',
    });
  }

  Future<List<Map<String, dynamic>>> getControlCommands({
    String? status,
  }) async {
    try {
      dynamic query = _client.from('control_commands').select();

      if (status != null) {
        query = query.eq('status', status);
      }

      query = query.order('timestamp', ascending: false);

      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching control commands: $e');
      return [];
    }
  }

  // ========== MARKETPLACE METHODS ==========

  Future<List<Map<String, dynamic>>> getMarketplaceProducts() async {
    try {
      final response = await _client
          .from('marketplace')
          .select()
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching marketplace products: $e');
      return [];
    }
  }

  Future<void> addMarketplaceProduct(Map<String, dynamic> product) async {
    await _client.from('marketplace').insert(product);
  }

  Future<void> updateMarketplaceProduct({
    required String productId,
    required Map<String, dynamic> updates,
  }) async {
    await _client.from('marketplace').update(updates).eq('id', productId);
  }

  Future<void> deleteMarketplaceProduct(String productId) async {
    await _client.from('marketplace').delete().eq('id', productId);
  }

  // ========== FEEDBACK METHODS ==========

  Future<void> submitFeedback({
    required String userId,
    required String feedbackText,
    int? rating,
  }) async {
    await _client.from('feedback').insert({
      'user_id': userId,
      'feedback_text': feedbackText,
      'rating': rating,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getFeedback() async {
    try {
      final response = await _client
          .from('feedback')
          .select()
          .order('timestamp', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching feedback: $e');
      return [];
    }
  }
}
