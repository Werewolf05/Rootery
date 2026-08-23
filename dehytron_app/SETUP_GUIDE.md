# App-Controlled System - Setup Guide

## Current Status
âœ… **Flutter App** - Fully implemented as primary controller
âœ… **Database Schema** - Ready in `database_setup.sql`
â³ **Supabase Setup** - Need to execute SQL
â³ **ESP32 Firmware** - Need to update to follow app commands

## What's Already Done (No Changes Needed)

### 1. App Control Logic âœ…
The app already has complete control logic:
- `CommandService` - Sends commands to ESP32
- `DataService` - Monitors telemetry and manages state
- Controls screen - Full UI for manual/auto control
- Crop database - 20+ presets with parameters
- Timer management - Tracks drying progress
- Progress calculation - Monitors moisture reduction

### 2. Command System âœ…
App can send all these commands:
```dart
// Cycle control
await CommandService().startCycle();
await CommandService().stopCycle();
await CommandService().pauseCycle();

// Parameter control
await CommandService().setTemperature(60);
await CommandService().setAirflow(2.5);
await CommandService().setMode('AUTO');

// Manual hardware control
await CommandService().heaterOn();
await CommandService().heaterOff();
await CommandService().fanOn();
await CommandService().fanOff();
```

### 3. UI Features âœ…
- Dashboard with real-time telemetry
- Controls screen with Auto/Manual modes
- Crop selection dropdown
- Multi-crop compatibility analysis
- Progress tracking with timer
- Device status monitoring
- Command history

## What You Need to Do

### Step 1: Setup Supabase Database (5 minutes)

1. **Open Supabase Dashboard**
   - Go to https://supabase.com
   - Login to your project

2. **Open SQL Editor**
   - Click "SQL Editor" in sidebar
   - Click "New Query"

3. **Execute Database Setup**
   - Copy entire content of `database_setup.sql`
   - Paste into SQL editor
   - Click "Run"
   - Wait for "âœ… ROOTERY Database setup complete!" message

4. **Verify Tables Created**
   - Click "Table Editor" in sidebar
   - You should see:
     - `telemetry`
     - `device_commands`
     - `device_states`
     - `crop_database`

5. **Check Crop Data**
   - Click on `crop_database` table
   - Should see 20 crops (Tomato, Apple, Banana, etc.)

### Step 2: Enable App Polling (DONE âœ…)

Changed `enableSupabasePolling = true` in `data_service.dart`

The app will now:
- Poll telemetry every 3 seconds
- Monitor device state
- Update UI in real-time

### Step 3: Update ESP32 Firmware

The ESP32 needs to be updated to:

#### A. Poll for Commands (every 5 seconds)
```cpp
void checkForCommands() {
  HTTPClient http;
  String url = SUPABASE_URL + "/rest/v1/device_commands?device_id=eq.ROOTERY_01&executed=eq.false&order=created_at.asc";
  
  http.begin(url);
  http.addHeader("apikey", SUPABASE_ANON_KEY);
  http.addHeader("Authorization", "Bearer " + SUPABASE_ANON_KEY);
  
  int httpCode = http.GET();
  if (httpCode == 200) {
    String payload = http.getString();
    // Parse JSON array of commands
    // Execute each command
    // Mark as executed
  }
}
```

#### B. Execute Commands
```cpp
void executeCommand(String cmd, String value) {
  Serial.println("Executing: " + cmd);
  
  if (cmd == "START_CYCLE") {
    cycleRunning = true;
  } 
  else if (cmd == "STOP_CYCLE") {
    cycleRunning = false;
    digitalWrite(HEATER_PIN, LOW);
    digitalWrite(FAN_PIN, LOW);
  }
  else if (cmd == "SET_TEMP") {
    targetTemp = value.toInt();
  }
  else if (cmd == "SET_AIRFLOW") {
    targetAirflow = value.toFloat();
  }
  else if (cmd == "HEATER_ON") {
    digitalWrite(HEATER_PIN, HIGH);
  }
  else if (cmd == "HEATER_OFF") {
    digitalWrite(HEATER_PIN, LOW);
  }
  else if (cmd == "FAN_ON") {
    digitalWrite(FAN_PIN, HIGH);
  }
  else if (cmd == "FAN_OFF") {
    digitalWrite(FAN_PIN, LOW);
  }
}
```

#### C. Mark Commands as Executed
```cpp
void markCommandExecuted(int commandId) {
  HTTPClient http;
  String url = SUPABASE_URL + "/rest/v1/device_commands?id=eq." + String(commandId);
  
  http.begin(url);
  http.addHeader("apikey", SUPABASE_ANON_KEY);
  http.addHeader("Authorization", "Bearer " + SUPABASE_ANON_KEY);
  http.addHeader("Content-Type", "application/json");
  
  String payload = "{\"executed\":true}";
  http.PATCH(payload);
}
```

#### D. Send Telemetry (every 10 seconds)
```cpp
void sendTelemetry() {
  float temp = dht.readTemperature();
  float humidity = dht.readHumidity();
  
  HTTPClient http;
  String url = SUPABASE_URL + "/rest/v1/telemetry";
  
  http.begin(url);
  http.addHeader("apikey", SUPABASE_ANON_KEY);
  http.addHeader("Authorization", "Bearer " + SUPABASE_ANON_KEY);
  http.addHeader("Content-Type", "application/json");
  http.addHeader("Prefer", "return=minimal");
  
  String payload = "{";
  payload += "\"device_id\":\"ROOTERY_01\",";
  payload += "\"temperature\":" + String(temp) + ",";
  payload += "\"humidity\":" + String(humidity) + ",";
  payload += "\"heater_state\":" + String(digitalRead(HEATER_PIN)) + ",";
  payload += "\"fan_state\":" + String(digitalRead(FAN_PIN)) + ",";
  payload += "\"wifi_rssi\":" + String(WiFi.RSSI());
  payload += "}";
  
  http.POST(payload);
}
```

#### E. Main Loop
```cpp
void loop() {
  unsigned long currentMillis = millis();
  
  // Check for commands every 5 seconds
  if (currentMillis - lastCommandCheck >= 5000) {
    checkForCommands();
    lastCommandCheck = currentMillis;
  }
  
  // Send telemetry every 10 seconds
  if (currentMillis - lastTelemetry >= 10000) {
    sendTelemetry();
    lastTelemetry = currentMillis;
  }
  
  // Control hardware based on setpoints
  if (cycleRunning) {
    controlTemperature();
    controlFan();
  }
  
  delay(100);
}
```

## Testing the System

### Test 1: Command Flow
1. **In App:** Tap "Start Drying" on Controls screen
2. **Check Supabase:** Open `device_commands` table
   - Should see: `cmd='START_CYCLE', executed=false`
3. **ESP32 Polls:** Within 5 seconds
4. **Check Again:** `executed=true`
5. **Verify:** Heater/fan turn on

### Test 2: Telemetry Flow
1. **ESP32 Sends:** Every 10 seconds
2. **Check Supabase:** Open `telemetry` table
   - Should see new rows with temp/humidity
3. **Check App:** Dashboard shows real-time values

### Test 3: Complete Drying Cycle
1. Select "Tomato" crop
2. Enter weight: 50kg
3. Tap "Start Drying"
4. App sends: `START_CYCLE`, `SET_TEMP 60`, `SET_AIRFLOW 2.0`
5. ESP32 executes within 5 seconds
6. Monitor dashboard for 3 hours (or test with shorter time)
7. App calculates progress from humidity readings
8. When complete, app sends `STOP_CYCLE`

## Key Differences from Device-Controlled System

### âŒ OLD (Device-Controlled):
- ESP32 had timer logic
- ESP32 decided when to stop
- ESP32 calculated progress
- Limited by ESP32 memory/processing

### âœ… NEW (App-Controlled):
- **App has timer logic** - More accurate
- **App decides when to stop** - Based on moisture readings
- **App calculates progress** - Complex algorithms possible
- **ESP32 just executes** - Simple, reliable
- **Easy to update** - Change app, not firmware
- **Rich UI** - Beautiful progress tracking
- **Multi-device** - Control many ESP32s from one app

## Summary

### Already Implemented âœ…
- App control logic
- Command service
- Telemetry monitoring
- UI for all controls
- Crop database
- Progress tracking

### You Need To Do
1. âœ… Run `database_setup.sql` in Supabase (5 minutes)
2. âœ… Enable polling in app (ALREADY DONE)
3. â³ Update ESP32 firmware to:
   - Poll commands every 5 seconds
   - Execute commands
   - Mark commands as executed
   - Send telemetry every 10 seconds

That's it! The app is ready to be the master controller.

