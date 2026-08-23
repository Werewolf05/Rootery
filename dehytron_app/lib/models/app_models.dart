enum CropType { lettuce, tomato, basil, spinach, custom }

enum AlertSeverity { info, warning, critical }

enum BatchStatus { active, upcoming, completed }

class SensorData {
  final String deviceId;
  final double phLevel;
  final double tdsLevel;
  final double waterTemperature;
  final double airTemperature;
  final double airHumidity;
  final double reservoirLevel;
  final bool pumpOn;
  final bool sprinklerOn;
  final int autoState;
  final bool isOnline;
  final DateTime lastUpdate;

  const SensorData({
    required this.deviceId,
    required this.phLevel,
    required this.tdsLevel,
    required this.waterTemperature,
    required this.airTemperature,
    required this.airHumidity,
    required this.reservoirLevel,
    required this.pumpOn,
    required this.sprinklerOn,
    required this.autoState,
    required this.isOnline,
    required this.lastUpdate,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value is DateTime) return value;
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }
      return DateTime.now();
    }

    double asDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0;
      return 0;
    }

    final lastUpdate = parseDate(
      json['last_update'] ?? json['created_at'] ?? json['timestamp'],
    );

    final onlineValue = json['is_online'] ?? json['device_online'];
    final isOnline = onlineValue == null
        ? DateTime.now().difference(lastUpdate).inMinutes < 5
        : (onlineValue == true || onlineValue == 1);

    return SensorData(
      deviceId: (json['device_id'] ?? 'HYDROPONICS_01').toString(),
      phLevel: asDouble(json['ph_level'] ?? json['ph'] ?? 0),
      tdsLevel: asDouble(json['tds_level'] ?? json['tds_ppm'] ?? 0),
      waterTemperature: asDouble(
        json['water_temperature'] ??
            json['water_temp'] ??
            json['water_temp_c'] ??
            0,
      ),
      airTemperature: asDouble(
        json['air_temperature'] ??
            json['air_temp_c'] ??
            json['temperature'] ??
            0,
      ),
      airHumidity: asDouble(
        json['air_humidity'] ?? json['humidity'] ?? json['humidity_pct'] ?? 0,
      ),
      reservoirLevel: asDouble(
        json['reservoir_level'] ??
            json['reservoir_level_percent'] ??
            json['main_tank_pct'] ??
            0,
      ),
      pumpOn: json['pump_on'] == true || json['pump_on'] == 1,
      sprinklerOn: json['sprinkler_on'] == true || json['sprinkler_on'] == 1,
      autoState: (json['auto_state'] as num?)?.toInt() ?? 0,
      isOnline: isOnline,
      lastUpdate: lastUpdate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'device_id': deviceId,
      'ph_level': phLevel,
      'tds_level': tdsLevel,
      'water_temperature': waterTemperature,
      'air_temperature': airTemperature,
      'air_humidity': airHumidity,
      'reservoir_level': reservoirLevel,
      'pump_on': pumpOn,
      'sprinkler_on': sprinklerOn,
      'auto_state': autoState,
      'is_online': isOnline,
      'last_update': lastUpdate.toIso8601String(),
    };
  }

  // Backward-compatible aliases for existing dehydrator-era widgets.
  double get temperature => airTemperature;
  double get humidity => airHumidity;
  double get airflow => 0;
  int get fanSpeed => 0;
  bool get heaterStatus => false;
  double get solarIntensity => 0;
  DateTime get timestamp => lastUpdate;

  String get autoModeLabel {
    switch (autoState) {
      case 0:
        return 'IDLE';
      case 1:
        return 'RUNNING';
      case 2:
        return 'WAITING';
      default:
        return 'UNKNOWN';
    }
  }
}

class FarmDevice {
  final String id;
  final String name;
  final bool isOnline;
  final DateTime lastSeen;
  final Map<String, bool> actuatorStates;

  const FarmDevice({
    required this.id,
    required this.name,
    required this.isOnline,
    required this.lastSeen,
    required this.actuatorStates,
  });

  factory FarmDevice.fromJson(Map<String, dynamic> json) {
    final statesRaw = json['actuator_states'];
    final states = <String, bool>{};
    if (statesRaw is Map<String, dynamic>) {
      for (final entry in statesRaw.entries) {
        states[entry.key] = entry.value == true || entry.value == 1;
      }
    }

    return FarmDevice(
      id: (json['id'] ?? json['device_id'] ?? '').toString(),
      name: (json['name'] ?? 'Main Controller').toString(),
      isOnline: json['is_online'] == true || json['is_online'] == 1,
      lastSeen:
          DateTime.tryParse((json['last_seen'] ?? '').toString()) ??
          DateTime.now(),
      actuatorStates: states,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'is_online': isOnline,
      'last_seen': lastSeen.toIso8601String(),
      'actuator_states': actuatorStates,
    };
  }
}

class HydroBatch {
  final String id;
  final String batchName;
  final CropType cropType;
  final DateTime plantingDate;
  final DateTime expectedHarvestDate;
  final int growthDurationDays;
  final BatchStatus status;

  const HydroBatch({
    required this.id,
    required this.batchName,
    required this.cropType,
    required this.plantingDate,
    required this.expectedHarvestDate,
    required this.growthDurationDays,
    required this.status,
  });

  factory HydroBatch.fromJson(Map<String, dynamic> json) {
    CropType parseCrop(dynamic value) {
      final normalized = (value ?? '').toString().toLowerCase();
      switch (normalized) {
        case 'lettuce':
          return CropType.lettuce;
        case 'tomato':
          return CropType.tomato;
        case 'basil':
          return CropType.basil;
        case 'spinach':
          return CropType.spinach;
        default:
          return CropType.custom;
      }
    }

    BatchStatus parseStatus(dynamic value) {
      final normalized = (value ?? '').toString().toLowerCase();
      switch (normalized) {
        case 'active':
          return BatchStatus.active;
        case 'upcoming':
          return BatchStatus.upcoming;
        case 'completed':
          return BatchStatus.completed;
        default:
          return BatchStatus.active;
      }
    }

    final plantingDate =
        DateTime.tryParse((json['planting_date'] ?? '').toString()) ??
        DateTime.now();
    final expectedHarvestDate =
        DateTime.tryParse((json['expected_harvest_date'] ?? '').toString()) ??
        plantingDate.add(const Duration(days: 30));

    return HydroBatch(
      id: (json['id'] ?? json['batch_id'] ?? '').toString(),
      batchName: (json['batch_name'] ?? 'Unnamed Batch').toString(),
      cropType: parseCrop(json['crop_type']),
      plantingDate: plantingDate,
      expectedHarvestDate: expectedHarvestDate,
      growthDurationDays: (json['growth_duration_days'] ?? 30) as int,
      status: parseStatus(json['status']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'batch_name': batchName,
      'crop_type': cropType.name,
      'planting_date': plantingDate.toIso8601String(),
      'expected_harvest_date': expectedHarvestDate.toIso8601String(),
      'growth_duration_days': growthDurationDays,
      'status': status.name,
    };
  }

  double get progressPercentage {
    if (status == BatchStatus.completed) return 100;
    if (status == BatchStatus.upcoming) return 0;
    final total = growthDurationDays <= 0 ? 1 : growthDurationDays;
    final elapsed = DateTime.now().difference(plantingDate).inDays;
    final pct = (elapsed / total) * 100;
    return pct.clamp(0, 100);
  }
}

class SystemAlert {
  final String id;
  final String title;
  final String message;
  final AlertSeverity severity;
  final String suggestion;
  final DateTime createdAt;

  const SystemAlert({
    required this.id,
    required this.title,
    required this.message,
    required this.severity,
    required this.suggestion,
    required this.createdAt,
  });

  factory SystemAlert.fromJson(Map<String, dynamic> json) {
    AlertSeverity parseSeverity(dynamic value) {
      final normalized = (value ?? '').toString().toLowerCase();
      switch (normalized) {
        case 'critical':
          return AlertSeverity.critical;
        case 'warning':
          return AlertSeverity.warning;
        default:
          return AlertSeverity.info;
      }
    }

    return SystemAlert(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      severity: parseSeverity(json['severity']),
      suggestion: (json['suggestion'] ?? '').toString(),
      createdAt:
          DateTime.tryParse((json['created_at'] ?? '').toString()) ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'severity': severity.name,
      'suggestion': suggestion,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// Legacy models retained for compatibility with existing legacy screens.
class Product {
  final String id;
  final String name;
  final String farm;
  final double price;
  final String unit;
  final double rating;
  final String category;
  final int stock;
  final String imageUrl;
  final String description;

  Product({
    required this.id,
    required this.name,
    required this.farm,
    required this.price,
    required this.unit,
    required this.rating,
    required this.category,
    required this.stock,
    required this.imageUrl,
    required this.description,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      farm: (json['farm'] ?? '').toString(),
      price: (json['price'] ?? 0).toDouble(),
      unit: (json['unit'] ?? '').toString(),
      rating: (json['rating'] ?? 0).toDouble(),
      category: (json['category'] ?? '').toString(),
      stock: (json['stock'] ?? 0) as int,
      imageUrl: (json['imageUrl'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'farm': farm,
      'price': price,
      'unit': unit,
      'rating': rating,
      'category': category,
      'stock': stock,
      'imageUrl': imageUrl,
      'description': description,
    };
  }
}

class DryingBatch {
  final String batchId;
  final String crop;
  final double weight;
  final Duration duration;
  final double initialMoisture;
  final double finalMoisture;
  final double avgTemp;
  final double avgHumidity;
  final double avgAirflow;
  final String status;
  final DateTime startDate;
  final DateTime? endDate;

  DryingBatch({
    required this.batchId,
    required this.crop,
    required this.weight,
    required this.duration,
    required this.initialMoisture,
    required this.finalMoisture,
    required this.avgTemp,
    required this.avgHumidity,
    required this.avgAirflow,
    required this.status,
    required this.startDate,
    this.endDate,
  });

  factory DryingBatch.fromJson(Map<String, dynamic> json) {
    return DryingBatch(
      batchId: (json['batchId'] ?? '').toString(),
      crop: (json['crop'] ?? '').toString(),
      weight: (json['weight'] ?? 0).toDouble(),
      duration: Duration(minutes: (json['durationMinutes'] ?? 0) as int),
      initialMoisture: (json['initialMoisture'] ?? 0).toDouble(),
      finalMoisture: (json['finalMoisture'] ?? 0).toDouble(),
      avgTemp: (json['avgTemp'] ?? 0).toDouble(),
      avgHumidity: (json['avgHumidity'] ?? 0).toDouble(),
      avgAirflow: (json['avgAirflow'] ?? 0).toDouble(),
      status: (json['status'] ?? '').toString(),
      startDate:
          DateTime.tryParse((json['startDate'] ?? '').toString()) ??
          DateTime.now(),
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'batchId': batchId,
      'crop': crop,
      'weight': weight,
      'durationMinutes': duration.inMinutes,
      'initialMoisture': initialMoisture,
      'finalMoisture': finalMoisture,
      'avgTemp': avgTemp,
      'avgHumidity': avgHumidity,
      'avgAirflow': avgAirflow,
      'status': status,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
    };
  }

  String get formattedDuration {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  String get formattedDate {
    return '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
  }
}

// Drying Progress Model
class DryingProgress {
  final String batchId;
  final String status;
  final double progress;
  final Duration estimatedTimeRemaining;
  final String cropType;
  final double currentMoisture;
  final double targetMoisture;

  DryingProgress({
    required this.batchId,
    required this.status,
    required this.progress,
    required this.estimatedTimeRemaining,
    required this.cropType,
    required this.currentMoisture,
    required this.targetMoisture,
  });

  factory DryingProgress.fromJson(Map<String, dynamic> json) {
    return DryingProgress(
      batchId: json['batchId'] ?? '',
      status: json['status'] ?? 'Idle',
      progress: (json['progress'] ?? 0).toDouble(),
      estimatedTimeRemaining: Duration(minutes: json['estimatedMinutes'] ?? 0),
      cropType: json['cropType'] ?? '',
      currentMoisture: (json['currentMoisture'] ?? 0).toDouble(),
      targetMoisture: (json['targetMoisture'] ?? 0).toDouble(),
    );
  }

  String get formattedTimeRemaining {
    final hours = estimatedTimeRemaining.inHours;
    final minutes = estimatedTimeRemaining.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }
}

// User Model
class User {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final String? farm;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.farm,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'Farmer/Client',
      phone: json['phone'],
      farm: json['farm'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'phone': phone,
      'farm': farm,
    };
  }
}
