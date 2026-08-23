import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for sending commands to ESP32 via Supabase
/// Commands flow: Flutter → Supabase device_commands table → ESP32 polls every 5s
class CommandService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String deviceId = 'ROOTERY_01';

  static const String cmdStartPump = 'START_PUMP';
  static const String cmdStopPump = 'STOP_PUMP';
  static const String cmdLightsOn = 'LIGHTS_ON';
  static const String cmdLightsOff = 'LIGHTS_OFF';
  static const String cmdStartAeration = 'START_AERATION';
  static const String cmdStopAeration = 'STOP_AERATION';
  static const String cmdDoseNutrientA = 'DOSE_NUTRIENT_A';
  static const String cmdDoseNutrientB = 'DOSE_NUTRIENT_B';
  static const String cmdStartSprinkler = 'START_SPRINKLER';
  static const String cmdStopSprinkler = 'STOP_SPRINKLER';
  static const String cmdSetLightIntensity = 'SET_LIGHT_INTENSITY';
  static const String cmdRebootDevice = 'REBOOT_DEVICE';

  /// Generic method to send any command
  Future<void> sendCommand(String cmd, {String? value}) async {
    try {
      print('📤 Sending command: $cmd${value != null ? " = $value" : ""}');

      await _supabase.from('device_commands').insert({
        'device_id': deviceId,
        'cmd': cmd,
        'value': value,
        'executed': false,
      });

      print('✅ Command sent successfully');
    } catch (e) {
      print('❌ Error sending command: $e');
      rethrow;
    }
  }

  // ========== CYCLE CONTROL ==========

  // Legacy compatibility methods.

  Future<void> startCycle() async {
    await sendCommand('START_CYCLE');
  }

  Future<void> stopCycle() async {
    await sendCommand('STOP_CYCLE');
  }

  Future<void> pauseCycle() async {
    await sendCommand('PAUSE_CYCLE');
  }

  Future<void> resumeCycle() async {
    await sendCommand('RESUME_CYCLE');
  }

  // ========== PARAMETER SETTINGS ==========

  Future<void> setTemperature(int temperature) async {
    await sendCommand('SET_TEMP', value: temperature.toString());
  }

  Future<void> setAirflow(double airflow) async {
    await sendCommand('SET_AIRFLOW', value: airflow.toStringAsFixed(1));
  }

  Future<void> setMode(String mode) async {
    // mode should be 'AUTO' or 'MANUAL'
    await sendCommand('SET_MODE', value: mode.toUpperCase());
  }

  Future<void> setTime(String time) async {
    // time format: "HH:MM:SS"
    await sendCommand('SET_TIME', value: time);
  }

  // ========== CROP SELECTION ==========

  Future<void> selectCrop(int cropIndex) async {
    await sendCommand('SELECT_CROP', value: cropIndex.toString());
  }

  // ========== MANUAL HARDWARE CONTROL ==========

  Future<void> heaterOn() async {
    await sendCommand('HEATER_ON');
  }

  Future<void> heaterOff() async {
    await sendCommand('HEATER_OFF');
  }

  Future<void> fanOn() async {
    await sendCommand('FAN_ON');
  }

  Future<void> fanOff() async {
    await sendCommand('FAN_OFF');
  }

  // ========== SYSTEM CONTROL ==========

  Future<void> reboot() async {
    await sendCommand(cmdRebootDevice);
  }

  // ========== HYDROPONICS COMMANDS ==========

  Future<void> startPump() async => sendCommand(cmdStartPump);

  Future<void> stopPump() async => sendCommand(cmdStopPump);

  Future<void> setPump(bool enabled) async {
    await sendCommand(enabled ? cmdStartPump : cmdStopPump);
  }

  Future<void> lightsOn() async => sendCommand(cmdLightsOn);

  Future<void> lightsOff() async => sendCommand(cmdLightsOff);

  Future<void> setLights(bool enabled) async {
    await sendCommand(enabled ? cmdLightsOn : cmdLightsOff);
  }

  Future<void> startAeration() async => sendCommand(cmdStartAeration);

  Future<void> stopAeration() async => sendCommand(cmdStopAeration);

  Future<void> setAeration(bool enabled) async {
    await sendCommand(enabled ? cmdStartAeration : cmdStopAeration);
  }

  Future<void> doseNutrientA() async => sendCommand(cmdDoseNutrientA);

  Future<void> doseNutrientB() async => sendCommand(cmdDoseNutrientB);

  Future<void> startSprinkler() async => sendCommand(cmdStartSprinkler);

  Future<void> stopSprinkler() async => sendCommand(cmdStopSprinkler);

  Future<void> setSprinkler(bool enabled) async {
    await sendCommand(enabled ? cmdStartSprinkler : cmdStopSprinkler);
  }

  Future<void> setLightIntensity(int intensity) async {
    final clamped = intensity.clamp(0, 100);
    await sendCommand(cmdSetLightIntensity, value: clamped.toString());
  }

  Future<void> rebootDevice() async => sendCommand(cmdRebootDevice);

  Future<void> manualOverrideOff() async => sendCommand('MANUAL_OVERRIDE_OFF');

  Future<void> manualOverrideOn() async => sendCommand('MANUAL_OVERRIDE_ON');

  Future<void> stopAllActuators() async {
    await Future.wait([
      stopPump(),
      lightsOff(),
      stopAeration(),
      stopSprinkler(),
    ]);
  }

  // ========== COMMAND HISTORY ==========

  /// Get recent commands sent to device
  Future<List<Map<String, dynamic>>> getRecentCommands({int limit = 20}) async {
    try {
      final response = await _supabase
          .from('device_commands')
          .select()
          .eq('device_id', deviceId)
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error fetching commands: $e');
      return [];
    }
  }

  /// Get pending (unexecuted) commands
  Future<List<Map<String, dynamic>>> getPendingCommands() async {
    try {
      final response = await _supabase
          .from('device_commands')
          .select()
          .eq('device_id', deviceId)
          .eq('executed', false)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error fetching pending commands: $e');
      return [];
    }
  }
}
