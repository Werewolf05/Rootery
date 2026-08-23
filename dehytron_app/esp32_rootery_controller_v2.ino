/*
 * ROOTERY - Smart Hydroponics Controller v2.0
 * ESP32 + Supabase + Ntfy
 *
 * PINOUT
 * Pump Relay         GPIO 26  (Main water pump, active LOW)
 * Sprinkler Relay    GPIO 27  (Sprinkler, active LOW)
 * Pump Button        GPIO 32  (INPUT_PULLUP)
 * Sprinkler Button   GPIO 33  (INPUT_PULLUP)
 * Reset Button       GPIO 25  (INPUT_PULLUP)
 * pH Sensor          GPIO 34  (ADC)
 * TDS Sensor         GPIO 35  (ADC)
 * DS18B20            GPIO 4   (OneWire, water temp)
 * DHT22              GPIO 15  (Air temp + humidity)
 * Ultrasonic 1 TRIG  GPIO 5   (Main tank - water pump)
 * Ultrasonic 1 ECHO  GPIO 18
 * Ultrasonic 2 TRIG  GPIO 13  (Sprinkler tank)
 * Ultrasonic 2 ECHO  GPIO 14
 * LCD SDA            GPIO 21
 * LCD SCL            GPIO 22
 */

#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include <DHT.h>
#include <OneWire.h>
#include <DallasTemperature.h>
#include <math.h>

// ===============================================
// Configure these
// ===============================================
const char* WIFI_SSID       = "Test";
const char* WIFI_PASSWORD   = "987654321";
const char* DEVICE_ID       = "ROOTERY_01";

// Supabase - from Project Settings -> API
const char* SUPABASE_URL    = "https://yiyqgbdpuesjpzirrdcy.supabase.co";
const char* SUPABASE_KEY    = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlpeXFnYmRwdWVzanB6aXJyZGN5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQyNzQ1MjksImV4cCI6MjA4OTg1MDUyOX0.ENwp2gj8df8zTnceMS8j-p00dchHUqeT03XxNB6GR5U";  // anon/public key

// Tank physical dimensions
const float MAIN_TANK_HEIGHT_CM       = 40.0f;
const float SPRINKLER_TANK_HEIGHT_CM  = 30.0f;

// Demo/showcase mode: set true to stream realistic synthetic values when sensors are unreliable.
const bool SHOWCASE_MODE = true;

// ===============================================
// Pin definitions
// ===============================================
#define PIN_PUMP_RELAY        26
#define PIN_SPRINKLER_RELAY   27
#define PIN_BTN_PUMP          32
#define PIN_BTN_SPRINKLER     33
#define PIN_BTN_RESET         25
#define PIN_PH                34
#define PIN_TDS               35
#define PIN_DS18B20           4
#define PIN_DHT22             15
#define PIN_TRIG1             5
#define PIN_ECHO1             18
#define PIN_TRIG2             13
#define PIN_ECHO2             14

// Set to false for active-HIGH relay modules, true for active-LOW modules.
const bool RELAY_ACTIVE_LOW = false;
#define RELAY_ON   (RELAY_ACTIVE_LOW ? LOW : HIGH)
#define RELAY_OFF  (RELAY_ACTIVE_LOW ? HIGH : LOW)

// ===============================================
// Timing constants
// ===============================================
#define SENSOR_INTERVAL       5000UL
#define SUPABASE_INTERVAL     30000UL
#define COMMAND_POLL_INTERVAL 1000UL
#define LCD_PAGE_INTERVAL     5000UL
#define LONG_PRESS_MS         800UL
#define DEBOUNCE_MS           35UL

// Sprinkler automation
#define SPRINKLER_RUN_MS      180000UL
#define SPRINKLER_WAIT_MS     1800000UL
#define AIR_TEMP_THRESHOLD    28.0f
#define WATER_TEMP_THRESHOLD  24.0f

// Tank alert threshold
#define TANK_LOW_PCT          30.0f

// pH calibration
#define PH_VREF               3.3f
#define PH_SLOPE             -5.70f
#define PH_INTERCEPT          21.34f
#define PH_OFFSET             0.0f

// TDS calibration
#define TDS_VREF              3.3f
#define TDS_FACTOR            0.5f

// LCD
#define LCD_ADDR  0x27
#define LCD_COLS  20
#define LCD_ROWS  4

// ===============================================
// Objects
// ===============================================
LiquidCrystal_I2C lcd(LCD_ADDR, LCD_COLS, LCD_ROWS);
DHT dht(PIN_DHT22, DHT22);
OneWire oneWire(PIN_DS18B20);
DallasTemperature ds18b20(&oneWire);

// ===============================================
// Sensor data
// ===============================================
struct SensorData {
  float ph          = 7.0f;
  float tds         = 0.0f;
  float waterTemp   = 22.0f;
  float airTemp     = 25.0f;
  float humidity    = 60.0f;
  float mainTankPct = 100.0f;
  float sprTankPct  = 100.0f;
} data;

// ===============================================
// System state
// ===============================================
bool pumpOn           = false;
bool sprinklerOn      = false;
bool pumpManualOff    = false;
bool stateSyncPending  = false;

// Sprinkler automation FSM
enum SprinklerAutoState { AUTO_IDLE, AUTO_RUNNING, AUTO_WAITING };
SprinklerAutoState autoState = AUTO_IDLE;
unsigned long autoTimer      = 0;

// Alert cooldown
unsigned long lastMainTankAlert = 0;
unsigned long lastSprTankAlert  = 0;
#define ALERT_COOLDOWN_MS  600000UL

// Timing
unsigned long lastSensorRead    = 0;
unsigned long lastSupabasePush  = 0;
unsigned long lastCommandPoll   = 0;
unsigned long lastPageSwitch    = 0;
uint8_t lcdPage = 0;
bool lcdNeedsRedraw = true;

struct Button {
  uint8_t pin;
  bool stableState = true;
  bool lastRead = true;
  bool longFired = false;
  unsigned long pressStart = 0;
  unsigned long lastChange = 0;
};
Button btnPump      = {PIN_BTN_PUMP};
Button btnSprinkler = {PIN_BTN_SPRINKLER};
Button btnReset     = {PIN_BTN_RESET};

// Custom LCD chars
byte charDrop[8]  = {0x04,0x0E,0x0E,0x1F,0x1F,0x1F,0x0E,0x00};
byte charTherm[8] = {0x04,0x0A,0x0A,0x0A,0x0E,0x1F,0x0E,0x00};
byte charWave[8]  = {0x00,0x00,0x0A,0x15,0x11,0x00,0x00,0x00};
byte charAlert[8] = {0x04,0x0E,0x0E,0x0E,0x1F,0x00,0x04,0x00};

// ===============================================
// Forward declarations
// ===============================================
void readSensors();
void generateShowcaseData();
float readPH();
float readTDS();
float measureDistance(uint8_t trig, uint8_t echo);
float tankPercent(float distCm, float tankHeightCm);
void runSprinklerAutomation();
void checkTankAlerts();
void setPump(bool on);
void setSprinkler(bool on);
void setAutoState(SprinklerAutoState state);
void updateLCD();
void drawSplash();
void drawPage0();
void drawPage1();
void drawPage2();
void handleButton(Button &btn, void(*onShort)(), void(*onLong)());
void onPumpShort();
void onPumpLong();
void onSprinklerShort();
void onSprinklerLong();
void onResetShort();
void onResetLong();
void pushToSupabase();
void pollCommandsFromSupabase();
void executeCommand(const String &cmd, const String &value);
void markCommandExecuted(int commandId);
void connectWiFi();
String phStatus(float ph);
String tdsStatus(float tds);
String tempStatus(float t);

static float clampf(float v, float lo, float hi) {
  if (v < lo) return lo;
  if (v > hi) return hi;
  return v;
}

void setup() {
  Serial.begin(115200);
  Serial.println(F("\nRootery Hydroponics v2.0"));
  randomSeed((uint32_t)micros());

  pinMode(PIN_PUMP_RELAY,      OUTPUT);
  pinMode(PIN_SPRINKLER_RELAY, OUTPUT);
  digitalWrite(PIN_PUMP_RELAY,      RELAY_OFF);
  digitalWrite(PIN_SPRINKLER_RELAY, RELAY_OFF);

  pinMode(PIN_BTN_PUMP,      INPUT_PULLUP);
  pinMode(PIN_BTN_SPRINKLER, INPUT_PULLUP);
  pinMode(PIN_BTN_RESET,     INPUT_PULLUP);

  pinMode(PIN_TRIG1, OUTPUT);
  pinMode(PIN_ECHO1, INPUT);
  pinMode(PIN_TRIG2, OUTPUT);
  pinMode(PIN_ECHO2, INPUT);
  digitalWrite(PIN_TRIG1, LOW);
  digitalWrite(PIN_TRIG2, LOW);

  dht.begin();
  ds18b20.begin();

  Wire.begin(21, 22);
  lcd.init();
  lcd.backlight();
  lcd.createChar(0, charDrop);
  lcd.createChar(1, charTherm);
  lcd.createChar(2, charWave);
  lcd.createChar(3, charAlert);

  drawSplash();
  connectWiFi();

  readSensors();
  lcd.clear();
  lcdNeedsRedraw = true;
}

void loop() {
  unsigned long now = millis();

  handleButton(btnPump,      onPumpShort,      onPumpLong);
  handleButton(btnSprinkler, onSprinklerShort, onSprinklerLong);
  handleButton(btnReset,     onResetShort,     onResetLong);

  if (stateSyncPending) {
    if (WiFi.status() == WL_CONNECTED) {
      if (pushToSupabase()) {
        stateSyncPending = false;
        lastSupabasePush = now;
      }
    } else {
      connectWiFi();
    }
  }

  if (now - lastSensorRead >= SENSOR_INTERVAL) {
    lastSensorRead = now;
    readSensors();
    runSprinklerAutomation();
    checkTankAlerts();
    lcdNeedsRedraw = true;
  }

  if (!stateSyncPending && now - lastSupabasePush >= SUPABASE_INTERVAL) {
    lastSupabasePush = now;
    if (WiFi.status() == WL_CONNECTED) {
      if (!pushToSupabase()) {
        stateSyncPending = true;
      }
    } else {
      connectWiFi();
    }
  }

  if (now - lastCommandPoll >= COMMAND_POLL_INTERVAL) {
    lastCommandPoll = now;
    if (WiFi.status() == WL_CONNECTED) {
      pollCommandsFromSupabase();
    }
  }

  if (now - lastPageSwitch >= LCD_PAGE_INTERVAL) {
    lastPageSwitch = now;
    lcdPage = (lcdPage + 1) % 3;
    lcd.clear();
    lcdNeedsRedraw = true;
  }

  if (lcdNeedsRedraw) {
    updateLCD();
    lcdNeedsRedraw = false;
  }
}

void readSensors() {
  if (SHOWCASE_MODE) {
    generateShowcaseData();
    Serial.printf("[Showcase] AirT=%.1fC Hum=%.0f%% WatT=%.1fC pH=%.2f TDS=%.0fppm MainTank=%.0f%% SprTank=%.0f%%\n",
      data.airTemp, data.humidity, data.waterTemp, data.ph, data.tds,
      data.mainTankPct, data.sprTankPct);
    return;
  }

  float h = dht.readHumidity();
  float t = dht.readTemperature();
  if (!isnan(h) && !isnan(t)) {
    data.humidity = h;
    data.airTemp = t;
  }

  ds18b20.requestTemperatures();
  float wt = ds18b20.getTempCByIndex(0);
  if (wt != DEVICE_DISCONNECTED_C && wt > -10) {
    data.waterTemp = wt;
  }

  data.ph  = readPH();
  data.tds = readTDS();

  float d1 = measureDistance(PIN_TRIG1, PIN_ECHO1);
  float d2 = measureDistance(PIN_TRIG2, PIN_ECHO2);
  if (d1 > 0) data.mainTankPct = tankPercent(d1, MAIN_TANK_HEIGHT_CM);
  if (d2 > 0) data.sprTankPct  = tankPercent(d2, SPRINKLER_TANK_HEIGHT_CM);

  Serial.printf("[Sensors] AirT=%.1fC Hum=%.0f%% WatT=%.1fC pH=%.2f TDS=%.0fppm MainTank=%.0f%% SprTank=%.0f%%\n",
    data.airTemp, data.humidity, data.waterTemp, data.ph, data.tds,
    data.mainTankPct, data.sprTankPct);
}

void generateShowcaseData() {
  // Smooth, believable drift over time for live demos.
  const float t = millis() / 1000.0f;
  const float noiseA = random(-25, 26) / 100.0f;
  const float noiseB = random(-20, 21) / 100.0f;
  const float noiseC = random(-15, 16) / 100.0f;

  data.airTemp = clampf(25.8f + 1.2f * sinf(t / 70.0f) + noiseA, 22.0f, 30.5f);
  data.waterTemp = clampf(22.6f + 0.8f * sinf(t / 95.0f + 0.7f) + noiseB, 20.0f, 26.5f);
  data.humidity = clampf(62.0f + 8.0f * sinf(t / 85.0f + 1.4f) + noiseC * 3.0f, 50.0f, 78.0f);

  float phBase = 6.05f + 0.15f * sinf(t / 120.0f + 0.2f) + random(-8, 9) / 100.0f;
  float tdsBase = 840.0f + 120.0f * sinf(t / 110.0f + 1.1f) + random(-45, 46);

  data.ph = clampf(phBase, 5.6f, 6.6f);
  data.tds = clampf(tdsBase, 580.0f, 1250.0f);

  if (pumpOn) {
    data.mainTankPct = clampf(data.mainTankPct - 0.35f, 46.0f, 100.0f);
  } else {
    data.mainTankPct = clampf(data.mainTankPct - 0.08f, 46.0f, 100.0f);
  }

  if (sprinklerOn || autoState == AUTO_RUNNING) {
    data.sprTankPct = clampf(data.sprTankPct - 0.45f, 35.0f, 100.0f);
  } else {
    data.sprTankPct = clampf(data.sprTankPct - 0.05f, 35.0f, 100.0f);
  }

  // Simulate occasional refill so levels do not only decline during long demos.
  if (random(0, 1000) < 6) {
    data.mainTankPct = clampf(data.mainTankPct + random(5, 13), 46.0f, 100.0f);
  }
  if (random(0, 1000) < 6) {
    data.sprTankPct = clampf(data.sprTankPct + random(4, 11), 35.0f, 100.0f);
  }
}

float readPH() {
  long sum = 0;
  for (int i = 0; i < 10; i++) {
    sum += analogRead(PIN_PH);
    delay(5);
  }
  float voltage = (sum / 10.0f) * PH_VREF / 4095.0f;
  float ph = PH_SLOPE * voltage + PH_INTERCEPT + PH_OFFSET;
  return constrain(ph, 0.0f, 14.0f);
}

float readTDS() {
  long sum = 0;
  for (int i = 0; i < 10; i++) {
    sum += analogRead(PIN_TDS);
    delay(5);
  }
  float voltage = (sum / 10.0f) * TDS_VREF / 4095.0f;
  float tempCoeff = 1.0f + 0.02f * (data.waterTemp - 25.0f);
  float compV = voltage / tempCoeff;
  float tds = (133.42f * compV * compV * compV
             - 255.86f * compV * compV
             + 857.39f * compV) * TDS_FACTOR;
  return max(0.0f, tds);
}

float measureDistance(uint8_t trig, uint8_t echo) {
  digitalWrite(trig, LOW);
  delayMicroseconds(2);
  digitalWrite(trig, HIGH);
  delayMicroseconds(10);
  digitalWrite(trig, LOW);
  long dur = pulseIn(echo, HIGH, 30000);
  if (dur == 0) return -1;
  return dur * 0.0343f / 2.0f;
}

float tankPercent(float distCm, float tankHeightCm) {
  float level = tankHeightCm - distCm;
  return constrain((level / tankHeightCm) * 100.0f, 0.0f, 100.0f);
}

void runSprinklerAutomation() {
  unsigned long now = millis();
  bool tooHot = (data.airTemp > AIR_TEMP_THRESHOLD || data.waterTemp > WATER_TEMP_THRESHOLD);

  switch (autoState) {
    case AUTO_IDLE:
      if (tooHot) {
        Serial.println(F("[Auto] High temp detected - starting sprinkler"));
        setSprinkler(true);
        autoTimer = now;
        setAutoState(AUTO_RUNNING);
      }
      break;

    case AUTO_RUNNING:
      if (now - autoTimer >= SPRINKLER_RUN_MS) {
        Serial.println(F("[Auto] Sprinkler run complete - waiting 30 min"));
        setSprinkler(false);
        autoTimer = now;
        setAutoState(AUTO_WAITING);
      }
      break;

    case AUTO_WAITING:
      if (now - autoTimer >= SPRINKLER_WAIT_MS) {
        if (tooHot) {
          Serial.println(F("[Auto] Still hot after wait - running sprinkler again"));
          setSprinkler(true);
          autoTimer = now;
          setAutoState(AUTO_RUNNING);
        } else {
          Serial.println(F("[Auto] Temperature normalised - returning to idle"));
          setAutoState(AUTO_IDLE);
        }
      }
      break;
  }
}

void checkTankAlerts() {
  unsigned long now = millis();

  if (data.mainTankPct < TANK_LOW_PCT && (now - lastMainTankAlert > ALERT_COOLDOWN_MS)) {
    lastMainTankAlert = now;
    Serial.printf("[Warn] Main tank low: %.0f%%\n", data.mainTankPct);
  }

  if (data.sprTankPct < TANK_LOW_PCT && (now - lastSprTankAlert > ALERT_COOLDOWN_MS)) {
    lastSprTankAlert = now;
    Serial.printf("[Warn] Sprinkler tank low: %.0f%%\n", data.sprTankPct);
  }
}

void setPump(bool on) {
  if (pumpOn == on) return;
  pumpOn = on;
  digitalWrite(PIN_PUMP_RELAY, on ? RELAY_ON : RELAY_OFF);
  Serial.printf("[Pump] %s\n", on ? "ON" : "OFF");
  stateSyncPending = true;
  lcdNeedsRedraw = true;
}

void setSprinkler(bool on) {
  if (sprinklerOn == on) return;
  sprinklerOn = on;
  digitalWrite(PIN_SPRINKLER_RELAY, on ? RELAY_ON : RELAY_OFF);
  Serial.printf("[Sprinkler] %s\n", on ? "ON" : "OFF");
  stateSyncPending = true;
  lcdNeedsRedraw = true;
}

void setAutoState(SprinklerAutoState state) {
  if (autoState == state) return;
  autoState = state;
  stateSyncPending = true;
  lcdNeedsRedraw = true;
}

void onPumpShort() {
  pumpManualOff = pumpOn;
  setPump(!pumpOn);
  Serial.println(F("[Btn] Pump toggled"));
}

void onPumpLong() {
  setPump(true);
  pumpManualOff = false;
  Serial.println(F("[Btn] Pump forced ON"));
}

void onSprinklerShort() {
  setAutoState(AUTO_IDLE);
  setSprinkler(!sprinklerOn);
  Serial.println(F("[Btn] Sprinkler toggled"));
}

void onSprinklerLong() {
  setAutoState(AUTO_IDLE);
  setSprinkler(true);
  Serial.println(F("[Btn] Sprinkler forced ON"));
}

void onResetShort() {
  setPump(false);
  setSprinkler(false);
  setAutoState(AUTO_IDLE);
  pumpManualOff = true;
  lcd.clear();
  lcdNeedsRedraw = true;
  Serial.println(F("[Reset] System reset - pump OFF, sprinkler OFF"));
}

void onResetLong() {
  Serial.println(F("[Reset] Restarting ESP32..."));
  delay(200);
  ESP.restart();
}

void handleButton(Button &btn, void(*onShort)(), void(*onLong)()) {
  const unsigned long now = millis();
  const bool raw = digitalRead(btn.pin);

  if (raw != btn.lastRead) {
    btn.lastRead = raw;
    btn.lastChange = now;
  }

  // Wait until input is stable for debounce window.
  if (now - btn.lastChange < DEBOUNCE_MS) return;

  if (btn.stableState != raw) {
    btn.stableState = raw;
    if (!raw) {
      btn.pressStart = now;
      btn.longFired = false;
    } else {
      if (!btn.longFired && (now - btn.pressStart < LONG_PRESS_MS)) {
        onShort();
      }
    }
  }

  if (!btn.stableState && !btn.longFired && (now - btn.pressStart >= LONG_PRESS_MS)) {
    btn.longFired = true;
    onLong();
  }
}

void drawSplash() {
  lcd.clear();
  lcd.setCursor(3, 1);
  lcd.print(F("  HYDROPONICS   "));
  lcd.setCursor(3, 2);
  lcd.print(F("  ROOTERY v2.0  "));
  delay(2500);
  lcd.clear();
  lcd.setCursor(2, 1);
  lcd.print(F("Connecting WiFi..."));
  delay(500);
}

void updateLCD() {
  switch (lcdPage) {
    case 0: drawPage0(); break;
    case 1: drawPage1(); break;
    case 2: drawPage2(); break;
  }
}

void drawPage0() {
  lcd.setCursor(0, 0);
  lcd.print(F("PMP:"));
  lcd.print(pumpOn ? F("[ON ] ") : F("[OFF] "));
  lcd.print(F("SPR:"));
  lcd.print(sprinklerOn ? F("[ON ]") : F("[OFF]"));

  lcd.setCursor(0, 1);
  lcd.print(F("Main:"));
  int bars1 = constrain((int)(data.mainTankPct / 10), 0, 10);
  for (int i = 0; i < 10; i++) lcd.write(i < bars1 ? (byte)2 : '-');
  char pct[6];
  snprintf(pct, sizeof(pct), "%3.0f%%", data.mainTankPct);
  lcd.print(pct);

  lcd.setCursor(0, 2);
  lcd.print(F("Spr: "));
  int bars2 = constrain((int)(data.sprTankPct / 10), 0, 10);
  for (int i = 0; i < 10; i++) lcd.write(i < bars2 ? (byte)2 : '-');
  snprintf(pct, sizeof(pct), "%3.0f%%", data.sprTankPct);
  lcd.print(pct);

  lcd.setCursor(0, 3);
  if (autoState != AUTO_IDLE) {
    lcd.print(F("[AUTO MODE ACTIVE]  "));
  } else {
    lcd.print(F("[1]Pump [2]Spr [R]  "));
  }
}

void drawPage1() {
  lcd.setCursor(0, 0);
  lcd.print(F(" pH    TDS   W.Temp "));

  lcd.setCursor(0, 1);
  char buf[21];
  snprintf(buf, sizeof(buf), " %-5.1f %-6.0f%-5.1fC", data.ph, data.tds, data.waterTemp);
  lcd.print(buf);

  lcd.setCursor(0, 2);
  String ps = phStatus(data.ph);
  String ts = tdsStatus(data.tds);
  String ws = tempStatus(data.waterTemp);
  String row2 = ps + ts + ws;
  while (row2.length() < 20) row2 += ' ';
  lcd.print(row2.substring(0, 20));

  lcd.setCursor(0, 3);
  lcd.print(F("   Water Chemistry  "));
}

void drawPage2() {
  char buf[21];
  lcd.setCursor(0, 0);
  snprintf(buf, sizeof(buf), " Air  Temp:%5.1fC  ", data.airTemp);
  lcd.print(buf);

  lcd.setCursor(0, 1);
  snprintf(buf, sizeof(buf), " Humidity:  %2.0f%%    ", data.humidity);
  lcd.print(buf);

  lcd.setCursor(0, 2);
  bool tempOk = data.airTemp >= 20 && data.airTemp <= 28;
  bool humOk  = data.humidity >= 50 && data.humidity <= 70;
  if (tempOk && humOk) {
    lcd.print(F(" Status:   [GOOD]   "));
  } else if (!tempOk) {
    lcd.print(F(" TEMP OUT OF RANGE! "));
  } else {
    lcd.print(F(" HUM  OUT OF RANGE! "));
  }

  lcd.setCursor(0, 3);
  switch (autoState) {
    case AUTO_IDLE:    lcd.print(F(" Auto-spr:  STANDBY ")); break;
    case AUTO_RUNNING: lcd.print(F(" Auto-spr:  RUNNING ")); break;
    case AUTO_WAITING: lcd.print(F(" Auto-spr:  WAITING ")); break;
  }
}

void connectWiFi() {
  if (WiFi.status() == WL_CONNECTED) return;
  Serial.printf("[WiFi] Connecting to %s ", WIFI_SSID);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  int tries = 0;
  while (WiFi.status() != WL_CONNECTED && tries < 20) {
    delay(500);
    Serial.print('.');
    tries++;
  }
  if (WiFi.status() == WL_CONNECTED) {
    Serial.printf("\n[WiFi] Connected! IP: %s\n", WiFi.localIP().toString().c_str());
  } else {
    Serial.println(F("\n[WiFi] Failed - will retry on next cycle"));
  }
}

bool pushToSupabase() {
  String url = String(SUPABASE_URL) + "/rest/v1/sensor_telemetry";

  StaticJsonDocument<384> doc;
  doc["ph"]            = round(data.ph * 100) / 100.0;
  doc["tds_ppm"]       = (int)data.tds;
  doc["water_temp_c"]  = round(data.waterTemp * 10) / 10.0;
  doc["air_temp_c"]    = round(data.airTemp * 10) / 10.0;
  doc["humidity_pct"]  = (int)data.humidity;
  doc["main_tank_pct"] = (int)data.mainTankPct;
  doc["spr_tank_pct"]  = (int)data.sprTankPct;
  doc["pump_on"]       = pumpOn;
  doc["sprinkler_on"]  = sprinklerOn;
  doc["auto_state"]    = (int)autoState;

  String body;
  serializeJson(doc, body);

  int code = -1;
  for (int attempt = 0; attempt < 3; attempt++) {
    HTTPClient http;
    http.begin(url);
    http.setTimeout(1800);
    http.addHeader("Content-Type", "application/json");
    http.addHeader("apikey", SUPABASE_KEY);
    http.addHeader("Authorization", String("Bearer ") + SUPABASE_KEY);
    http.addHeader("Prefer", "return=minimal");

    code = http.POST(body);
    if (code >= 200 && code < 300) {
      Serial.printf("[Supabase] Telemetry push OK (attempt %d) -> HTTP %d\n", attempt + 1, code);
      http.end();
      return true;
    }

    String errBody = http.getString();
    Serial.printf("[Supabase] Telemetry push fail (attempt %d) -> HTTP %d, body: %s\n", attempt + 1, code, errBody.c_str());
    http.end();

    // Retry only network/server failures.
    if (code <= 0 || code >= 500) {
      delay(250UL * (attempt + 1));
      continue;
    }
    break;
  }

  return false;
}

void pollCommandsFromSupabase() {
  String url = String(SUPABASE_URL)
             + "/rest/v1/device_commands?device_id=eq." + DEVICE_ID
             + "&executed=eq.false"
             + "&select=id,cmd,command,value"
             + "&order=created_at.asc"
             + "&limit=5";

  HTTPClient http;
  http.begin(url);
  http.setTimeout(1200);
  http.addHeader("apikey", SUPABASE_KEY);
  http.addHeader("Authorization", String("Bearer ") + SUPABASE_KEY);

  int code = http.GET();
  if (code < 200 || code >= 300) {
    Serial.printf("[Supabase] Command poll failed -> HTTP %d\n", code);
    http.end();
    return;
  }

  String payload = http.getString();
  http.end();

  StaticJsonDocument<512> doc;
  DeserializationError err = deserializeJson(doc, payload);
  if (err) {
    Serial.printf("[Supabase] Command JSON parse error: %s\n", err.c_str());
    return;
  }

  JsonArray arr = doc.as<JsonArray>();
  if (arr.size() == 0) {
    return;
  }

  for (JsonObject obj : arr) {
    int id = obj["id"] | -1;
    String cmd = obj["cmd"] | "";
    if (cmd.length() == 0) {
      cmd = obj["command"] | "";
    }
    String value = obj["value"] | "";

    if (id < 0 || cmd.length() == 0) {
      Serial.println(F("[Cmd] Invalid command row; skipping"));
      continue;
    }

    Serial.printf("[Cmd] Executing id=%d cmd=%s value=%s\n", id, cmd.c_str(), value.c_str());
    executeCommand(cmd, value);
    markCommandExecuted(id);
  }
}

void executeCommand(const String &cmd, const String &value) {
  if (cmd == "START_PUMP" || cmd == "START_CYCLE") {
    setPump(true);
    pumpManualOff = false;
    return;
  }

  if (cmd == "STOP_PUMP" || cmd == "STOP_CYCLE") {
    setPump(false);
    pumpManualOff = true;
    return;
  }

  if (cmd == "START_SPRINKLER") {
    setAutoState(AUTO_IDLE);
    setSprinkler(true);
    return;
  }

  if (cmd == "STOP_SPRINKLER") {
    setAutoState(AUTO_IDLE);
    setSprinkler(false);
    return;
  }

  if (cmd == "REBOOT" || cmd == "REBOOT_DEVICE") {
    Serial.println(F("[Cmd] Reboot requested"));
    delay(100);
    ESP.restart();
    return;
  }

  if (cmd == "SET_MODE") {
    if (value == "AUTO") {
      setAutoState(AUTO_IDLE);
      Serial.println(F("[Cmd] Mode set to AUTO"));
    } else {
      setAutoState(AUTO_IDLE);
      Serial.println(F("[Cmd] Mode set to MANUAL"));
    }
    return;
  }

  Serial.printf("[Cmd] Unsupported command: %s\n", cmd.c_str());
}

void markCommandExecuted(int commandId) {
  String url = String(SUPABASE_URL)
             + "/rest/v1/device_commands?id=eq." + String(commandId);

  StaticJsonDocument<64> doc;
  doc["executed"] = true;

  String body;
  serializeJson(doc, body);

  HTTPClient http;
  http.begin(url);
  http.setTimeout(1200);
  http.addHeader("Content-Type", "application/json");
  http.addHeader("apikey", SUPABASE_KEY);
  http.addHeader("Authorization", String("Bearer ") + SUPABASE_KEY);
  http.addHeader("Prefer", "return=minimal");

  int code = http.PATCH(body);
  if (code >= 200 && code < 300) {
    Serial.printf("[Cmd] Marked executed id=%d\n", commandId);
  } else {
    String errBody = http.getString();
    Serial.printf("[Cmd] Failed to mark executed id=%d -> HTTP %d, body: %s\n", commandId, code, errBody.c_str());
  }
  http.end();
}

String phStatus(float ph) {
  if (ph < 5.5f) return "[LOW] ";
  if (ph > 6.5f) return "[HI]  ";
  return "[OK]  ";
}

String tdsStatus(float tds) {
  if (tds < 400) return "[LOW] ";
  if (tds > 1600) return "[HI]  ";
  return "[OK]  ";
}

String tempStatus(float t) {
  if (t < 18) return "[COLD]";
  if (t > 24) return "[WARM]";
  return "[OK]  ";
}
