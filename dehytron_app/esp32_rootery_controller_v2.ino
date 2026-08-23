/*
 * ROOTERY - Smart Hydroponics Controller v2.1
 * ESP32 + Supabase + Ntfy
 *
 * FIXED:
 * - Pump button proper ON/OFF toggle
 * - Sprinkler button proper ON/OFF toggle
 * - Reset button
 * - Active LOW relay support
 * - Manual sprinkler control won't be overridden immediately
 * - Improved button debounce
 */

// =====================================================
// PINOUT
// =====================================================

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

// =====================================================
// LIBRARIES
// =====================================================

#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include <DHT.h>
#include <OneWire.h>
#include <DallasTemperature.h>
#include <math.h>

// =====================================================
// WIFI / SUPABASE
// =====================================================

const char* WIFI_SSID     = "Test";
const char* WIFI_PASSWORD = "987654321";
const char* DEVICE_ID     = "ROOTERY_01";

const char* SUPABASE_URL =
  "https://yiyqgbdpuesjpzirrdcy.supabase.co";

const char* SUPABASE_KEY =
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlpeXFnYmRwdWVzanB6aXJyZGN5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQyNzQ1MjksImV4cCI6MjA4OTg1MDUyOX0.ENwp2gj8df8zTnceMS8j-p00dchHUqeT03XxNB6GR5U";

// =====================================================
// TANK SETTINGS
// =====================================================

const float MAIN_TANK_HEIGHT_CM      = 40.0f;
const float SPRINKLER_TANK_HEIGHT_CM = 30.0f;

// =====================================================
// RELAY SETTINGS
// =====================================================

// IMPORTANT:
// Most relay modules are ACTIVE LOW.
// If your relay works opposite, change true -> false.

const bool RELAY_ACTIVE_LOW = true;

#define RELAY_ON  (RELAY_ACTIVE_LOW ? LOW : HIGH)
#define RELAY_OFF (RELAY_ACTIVE_LOW ? HIGH : LOW)

// =====================================================
// SHOWCASE MODE
// =====================================================

const bool SHOWCASE_MODE = true;

// =====================================================
// TIMING
// =====================================================

#define SENSOR_INTERVAL       5000UL
#define SUPABASE_INTERVAL     30000UL
#define COMMAND_POLL_INTERVAL 1000UL
#define LCD_PAGE_INTERVAL     5000UL

#define DEBOUNCE_MS            50UL

// =====================================================
// SPRINKLER AUTOMATION
// =====================================================

#define SPRINKLER_RUN_MS      180000UL
#define SPRINKLER_WAIT_MS     1800000UL

#define AIR_TEMP_THRESHOLD    28.0f
#define WATER_TEMP_THRESHOLD  24.0f

// =====================================================
// TANK ALERT
// =====================================================

#define TANK_LOW_PCT          30.0f
#define ALERT_COOLDOWN_MS     600000UL

// =====================================================
// PH
// =====================================================

#define PH_VREF       3.3f
#define PH_SLOPE     -5.70f
#define PH_INTERCEPT 21.34f
#define PH_OFFSET     0.0f

// =====================================================
// TDS
// =====================================================

#define TDS_VREF      3.3f
#define TDS_FACTOR    0.5f

// =====================================================
// LCD
// =====================================================

#define LCD_ADDR  0x27
#define LCD_COLS  20
#define LCD_ROWS  4

LiquidCrystal_I2C lcd(LCD_ADDR, LCD_COLS, LCD_ROWS);

// =====================================================
// SENSOR OBJECTS
// =====================================================

DHT dht(PIN_DHT22, DHT22);

OneWire oneWire(PIN_DS18B20);
DallasTemperature ds18b20(&oneWire);

// =====================================================
// SENSOR DATA
// =====================================================

struct SensorData {

  float ph          = 7.0f;
  float tds         = 0.0f;

  float waterTemp   = 22.0f;
  float airTemp     = 25.0f;
  float humidity    = 60.0f;

  float mainTankPct = 100.0f;
  float sprTankPct  = 100.0f;

};

SensorData data;

// =====================================================
// SYSTEM STATES
// =====================================================

bool pumpOn      = false;
bool sprinklerOn = false;

bool pumpManualOff = false;

bool stateSyncPending = false;

// IMPORTANT:
// This prevents automatic sprinkler logic from immediately
// changing the state after a manual button press.

bool sprinklerManualMode = false;

// =====================================================
// AUTOMATION STATE
// =====================================================

enum SprinklerAutoState {

  AUTO_IDLE,
  AUTO_RUNNING,
  AUTO_WAITING

};

SprinklerAutoState autoState = AUTO_IDLE;

unsigned long autoTimer = 0;

// =====================================================
// ALERT TIMERS
// =====================================================

unsigned long lastMainTankAlert = 0;
unsigned long lastSprTankAlert  = 0;

// =====================================================
// GENERAL TIMERS
// =====================================================

unsigned long lastSensorRead   = 0;
unsigned long lastSupabasePush = 0;
unsigned long lastCommandPoll  = 0;
unsigned long lastPageSwitch   = 0;

// =====================================================
// LCD
// =====================================================

uint8_t lcdPage = 0;
bool lcdNeedsRedraw = true;

// =====================================================
// BUTTON STRUCTURE
// =====================================================

struct Button {

  uint8_t pin;

  bool lastReading;
  bool stableState;

  unsigned long lastDebounceTime;

};

// =====================================================
// BUTTON OBJECTS
// =====================================================

Button btnPump = {

  PIN_BTN_PUMP,
  HIGH,
  HIGH,
  0

};

Button btnSprinkler = {

  PIN_BTN_SPRINKLER,
  HIGH,
  HIGH,
  0

};

Button btnReset = {

  PIN_BTN_RESET,
  HIGH,
  HIGH,
  0

};

// =====================================================
// LCD CUSTOM CHARACTERS
// =====================================================

byte charDrop[8] = {

  0x04,
  0x0E,
  0x0E,
  0x1F,
  0x1F,
  0x1F,
  0x0E,
  0x00

};

byte charTherm[8] = {

  0x04,
  0x0A,
  0x0A,
  0x0A,
  0x0E,
  0x1F,
  0x0E,
  0x00

};

byte charWave[8] = {

  0x00,
  0x00,
  0x0A,
  0x15,
  0x11,
  0x00,
  0x00,
  0x00

};

byte charAlert[8] = {

  0x04,
  0x0E,
  0x0E,
  0x0E,
  0x1F,
  0x00,
  0x04,
  0x00

};

// =====================================================
// FUNCTION DECLARATIONS
// =====================================================

void readSensors();

void generateShowcaseData();

float readPH();

float readTDS();

float measureDistance(
  uint8_t trig,
  uint8_t echo
);

float tankPercent(
  float distCm,
  float tankHeightCm
);

void runSprinklerAutomation();

void checkTankAlerts();

void setPump(bool on);

void setSprinkler(bool on);

void setAutoState(
  SprinklerAutoState state
);

void updateLCD();

void drawSplash();

void drawPage0();

void drawPage1();

void drawPage2();

void checkPumpButton();

void checkSprinklerButton();

void checkResetButton();

void onPumpPressed();

void onSprinklerPressed();

void onResetPressed();

bool pushToSupabase();

void pollCommandsFromSupabase();

void executeCommand(
  const String &cmd,
  const String &value
);

void markCommandExecuted(
  int commandId
);

void connectWiFi();

String phStatus(float ph);

String tdsStatus(float tds);

String tempStatus(float t);

// =====================================================
// CLAMP
// =====================================================

static float clampf(
  float v,
  float lo,
  float hi
) {

  if (v < lo)
    return lo;

  if (v > hi)
    return hi;

  return v;
}

// =====================================================
// SETUP
// =====================================================

void setup() {

  Serial.begin(115200);

  delay(500);

  Serial.println();
  Serial.println("================================");
  Serial.println("ROOTERY HYDROPONICS v2.1");
  Serial.println("BUTTON TEST FIXED");
  Serial.println("================================");

  randomSeed(
    (uint32_t)micros()
  );

  // ---------------------------------------------------
  // RELAYS
  // ---------------------------------------------------

  pinMode(
    PIN_PUMP_RELAY,
    OUTPUT
  );

  pinMode(
    PIN_SPRINKLER_RELAY,
    OUTPUT
  );

  // Make sure both are OFF during startup

  digitalWrite(
    PIN_PUMP_RELAY,
    RELAY_OFF
  );

  digitalWrite(
    PIN_SPRINKLER_RELAY,
    RELAY_OFF
  );

  // ---------------------------------------------------
  // BUTTONS
  // ---------------------------------------------------

  pinMode(
    PIN_BTN_PUMP,
    INPUT_PULLUP
  );

  pinMode(
    PIN_BTN_SPRINKLER,
    INPUT_PULLUP
  );

  pinMode(
    PIN_BTN_RESET,
    INPUT_PULLUP
  );

  // ---------------------------------------------------
  // ULTRASONIC
  // ---------------------------------------------------

  pinMode(
    PIN_TRIG1,
    OUTPUT
  );

  pinMode(
    PIN_ECHO1,
    INPUT
  );

  pinMode(
    PIN_TRIG2,
    OUTPUT
  );

  pinMode(
    PIN_ECHO2,
    INPUT
  );

  digitalWrite(
    PIN_TRIG1,
    LOW
  );

  digitalWrite(
    PIN_TRIG2,
    LOW
  );

  // ---------------------------------------------------
  // SENSORS
  // ---------------------------------------------------

  dht.begin();

  ds18b20.begin();

  // ---------------------------------------------------
  // LCD
  // ---------------------------------------------------

  Wire.begin(
    5,
    18
  );

  lcd.init();

  lcd.backlight();

  lcd.createChar(
    0,
    charDrop
  );

  lcd.createChar(
    1,
    charTherm
  );

  lcd.createChar(
    2,
    charWave
  );

  lcd.createChar(
    3,
    charAlert
  );

  drawSplash();

  // ---------------------------------------------------
  // WIFI
  // ---------------------------------------------------

  connectWiFi();

  // ---------------------------------------------------
  // SENSOR INITIAL READ
  // ---------------------------------------------------

  readSensors();

  lcd.clear();

  lcdNeedsRedraw = true;

}

// =====================================================
// LOOP
// =====================================================

void loop() {

  unsigned long now = millis();

  // ===================================================
  // BUTTONS
  // ===================================================

  checkPumpButton();

  checkSprinklerButton();

  checkResetButton();

  // ===================================================
  // SUPABASE STATE SYNC
  // ===================================================

  if (stateSyncPending) {

    if (WiFi.status() == WL_CONNECTED) {

      if (pushToSupabase()) {

        stateSyncPending = false;

        lastSupabasePush = now;

      }

    }
    else {

      connectWiFi();

    }

  }

  // ===================================================
  // SENSOR UPDATE
  // ===================================================

  if (
    now - lastSensorRead >=
    SENSOR_INTERVAL
  ) {

    lastSensorRead = now;

    readSensors();

    // Only run automatic sprinkler control
    // when sprinkler is NOT in manual mode.

    if (!sprinklerManualMode) {

      runSprinklerAutomation();

    }

    checkTankAlerts();

    lcdNeedsRedraw = true;

  }

  // ===================================================
  // SUPABASE PERIODIC UPDATE
  // ===================================================

  if (
    !stateSyncPending &&
    now - lastSupabasePush >=
    SUPABASE_INTERVAL
  ) {

    lastSupabasePush = now;

    if (
      WiFi.status() ==
      WL_CONNECTED
    ) {

      if (!pushToSupabase()) {

        stateSyncPending = true;

      }

    }
    else {

      connectWiFi();

    }

  }

  // ===================================================
  // SUPABASE COMMANDS
  // ===================================================

  if (
    now - lastCommandPoll >=
    COMMAND_POLL_INTERVAL
  ) {

    lastCommandPoll = now;

    if (
      WiFi.status() ==
      WL_CONNECTED
    ) {

      pollCommandsFromSupabase();

    }

  }

  // ===================================================
  // LCD PAGE
  // ===================================================

  if (
    now - lastPageSwitch >=
    LCD_PAGE_INTERVAL
  ) {

    lastPageSwitch = now;

    lcdPage =
      (lcdPage + 1) % 3;

    lcd.clear();

    lcdNeedsRedraw = true;

  }

  // ===================================================
  // LCD UPDATE
  // ===================================================

  if (lcdNeedsRedraw) {

    updateLCD();

    lcdNeedsRedraw = false;

  }

}

// =====================================================
// PUMP BUTTON
// =====================================================

void checkPumpButton() {

  bool reading =
    digitalRead(PIN_BTN_PUMP);

  if (
    reading !=
    btnPump.lastReading
  ) {

    btnPump.lastDebounceTime =
      millis();

    btnPump.lastReading =
      reading;

  }

  if (
    millis() -
    btnPump.lastDebounceTime >
    DEBOUNCE_MS
  ) {

    if (
      reading !=
      btnPump.stableState
    ) {

      btnPump.stableState =
        reading;

      // Button pressed

      if (
        btnPump.stableState ==
        LOW
      ) {

        onPumpPressed();

      }

    }

  }

}

// =====================================================
// SPRINKLER BUTTON
// =====================================================

void checkSprinklerButton() {

  bool reading =
    digitalRead(
      PIN_BTN_SPRINKLER
    );

  if (
    reading !=
    btnSprinkler.lastReading
  ) {

    btnSprinkler.lastDebounceTime =
      millis();

    btnSprinkler.lastReading =
      reading;

  }

  if (
    millis() -
    btnSprinkler.lastDebounceTime >
    DEBOUNCE_MS
  ) {

    if (
      reading !=
      btnSprinkler.stableState
    ) {

      btnSprinkler.stableState =
        reading;

      if (
        btnSprinkler.stableState ==
        LOW
      ) {

        onSprinklerPressed();

      }

    }

  }

}

// =====================================================
// RESET BUTTON
// =====================================================

void checkResetButton() {

  bool reading =
    digitalRead(
      PIN_BTN_RESET
    );

  if (
    reading !=
    btnReset.lastReading
  ) {

    btnReset.lastDebounceTime =
      millis();

    btnReset.lastReading =
      reading;

  }

  if (
    millis() -
    btnReset.lastDebounceTime >
    DEBOUNCE_MS
  ) {

    if (
      reading !=
      btnReset.stableState
    ) {

      btnReset.stableState =
        reading;

      if (
        btnReset.stableState ==
        LOW
      ) {

        onResetPressed();

      }

    }

  }

}

// =====================================================
// PUMP PRESSED
// =====================================================

void onPumpPressed() {

  Serial.println();
  Serial.println(
    ">>> PUMP BUTTON PRESSED"
  );

  // Toggle

  if (pumpOn) {

    setPump(false);

    pumpManualOff = true;

    Serial.println(
      ">>> PUMP OFF"
    );

  }
  else {

    setPump(true);

    pumpManualOff = false;

    Serial.println(
      ">>> PUMP ON"
    );

  }

}

// =====================================================
// SPRINKLER PRESSED
// =====================================================

void onSprinklerPressed() {

  Serial.println();
  Serial.println(
    ">>> SPRINKLER BUTTON PRESSED"
  );

  // Manual button means manual mode

  sprinklerManualMode = true;

  // Stop automatic state

  setAutoState(
    AUTO_IDLE
  );

  // Toggle sprinkler

  if (sprinklerOn) {

    setSprinkler(false);

    Serial.println(
      ">>> SPRINKLER OFF"
    );

  }
  else {

    setSprinkler(true);

    Serial.println(
      ">>> SPRINKLER ON"
    );

  }

}

// =====================================================
// RESET PRESSED
// =====================================================

void onResetPressed() {

  Serial.println();
  Serial.println(
    ">>> RESET BUTTON PRESSED"
  );

  setPump(false);

  setSprinkler(false);

  setAutoState(
    AUTO_IDLE
  );

  pumpManualOff = true;

  sprinklerManualMode = false;

  lcd.clear();

  lcdNeedsRedraw = true;

  Serial.println(
    ">>> SYSTEM RESET"
  );

}

// =====================================================
// READ SENSORS
// =====================================================

void readSensors() {

  if (SHOWCASE_MODE) {

    generateShowcaseData();

    Serial.printf(
      "[Showcase] AirT=%.1fC "
      "Hum=%.0f%% "
      "WatT=%.1fC "
      "pH=%.2f "
      "TDS=%.0f "
      "Main=%.0f%% "
      "Spr=%.0f%%\n",

      data.airTemp,
      data.humidity,
      data.waterTemp,
      data.ph,
      data.tds,
      data.mainTankPct,
      data.sprTankPct
    );

    return;

  }

  // DHT22

  float h =
    dht.readHumidity();

  float t =
    dht.readTemperature();

  if (
    !isnan(h) &&
    !isnan(t)
  ) {

    data.humidity = h;

    data.airTemp = t;

  }

  // DS18B20

  ds18b20.requestTemperatures();

  float wt =
    ds18b20.getTempCByIndex(0);

  if (
    wt !=
    DEVICE_DISCONNECTED_C &&
    wt > -10
  ) {

    data.waterTemp = wt;

  }

  // pH / TDS

  data.ph =
    readPH();

  data.tds =
    readTDS();

  // Ultrasonic

  float d1 =
    measureDistance(
      PIN_TRIG1,
      PIN_ECHO1
    );

  float d2 =
    measureDistance(
      PIN_TRIG2,
      PIN_ECHO2
    );

  if (d1 > 0) {

    data.mainTankPct =
      tankPercent(
        d1,
        MAIN_TANK_HEIGHT_CM
      );

  }

  if (d2 > 0) {

    data.sprTankPct =
      tankPercent(
        d2,
        SPRINKLER_TANK_HEIGHT_CM
      );

  }

}

// =====================================================
// SHOWCASE DATA
// =====================================================

void generateShowcaseData() {

  const float t =
    millis() / 1000.0f;

  const float noiseA =
    random(-25, 26) / 100.0f;

  const float noiseB =
    random(-20, 21) / 100.0f;

  const float noiseC =
    random(-15, 16) / 100.0f;

  data.airTemp =
    clampf(
      25.8f +
      1.2f * sinf(t / 70.0f) +
      noiseA,

      22.0f,
      30.5f
    );

  data.waterTemp =
    clampf(
      22.6f +
      0.8f *
      sinf(
        t / 95.0f +
        0.7f
      ) +
      noiseB,

      20.0f,
      26.5f
    );

  data.humidity =
    clampf(
      62.0f +
      8.0f *
      sinf(
        t / 85.0f +
        1.4f
      ) +
      noiseC * 3.0f,

      50.0f,
      78.0f
    );

  float phBase =
    6.05f +
    0.15f *
    sinf(
      t / 120.0f +
      0.2f
    ) +
    random(-8, 9) / 100.0f;

  float tdsBase =
    840.0f +
    120.0f *
    sinf(
      t / 110.0f +
      1.1f
    ) +
    random(-45, 46);

  data.ph =
    clampf(
      phBase,
      5.6f,
      6.6f
    );

  data.tds =
    clampf(
      tdsBase,
      580.0f,
      1250.0f
    );

  if (pumpOn) {

    data.mainTankPct =
      clampf(
        data.mainTankPct - 0.35f,
        46.0f,
        100.0f
      );

  }
  else {

    data.mainTankPct =
      clampf(
        data.mainTankPct - 0.08f,
        46.0f,
        100.0f
      );

  }

  if (
    sprinklerOn ||
    autoState == AUTO_RUNNING
  ) {

    data.sprTankPct =
      clampf(
        data.sprTankPct - 0.45f,
        35.0f,
        100.0f
      );

  }
  else {

    data.sprTankPct =
      clampf(
        data.sprTankPct - 0.05f,
        35.0f,
        100.0f
      );

  }

}

// =====================================================
// PH
// =====================================================

float readPH() {

  long sum = 0;

  for (
    int i = 0;
    i < 10;
    i++
  ) {

    sum +=
      analogRead(PIN_PH);

    delay(5);

  }

  float voltage =
    (sum / 10.0f) *
    PH_VREF /
    4095.0f;

  float ph =
    PH_SLOPE *
    voltage +
    PH_INTERCEPT +
    PH_OFFSET;

  return constrain(
    ph,
    0.0f,
    14.0f
  );

}

// =====================================================
// TDS
// =====================================================

float readTDS() {

  long sum = 0;

  for (
    int i = 0;
    i < 10;
    i++
  ) {

    sum +=
      analogRead(PIN_TDS);

    delay(5);

  }

  float voltage =
    (sum / 10.0f) *
    TDS_VREF /
    4095.0f;

  float tempCoeff =
    1.0f +
    0.02f *
    (data.waterTemp - 25.0f);

  float compV =
    voltage /
    tempCoeff;

  float tds =
    (
      133.42f *
      compV *
      compV *
      compV

      - 255.86f *
      compV *
      compV

      + 857.39f *
      compV
    ) *
    TDS_FACTOR;

  return max(
    0.0f,
    tds
  );

}

// =====================================================
// DISTANCE
// =====================================================

float measureDistance(
  uint8_t trig,
  uint8_t echo
) {

  digitalWrite(
    trig,
    LOW
  );

  delayMicroseconds(2);

  digitalWrite(
    trig,
    HIGH
  );

  delayMicroseconds(10);

  digitalWrite(
    trig,
    LOW
  );

  long dur =
    pulseIn(
      echo,
      HIGH,
      30000
    );

  if (dur == 0)
    return -1;

  return
    dur *
    0.0343f /
    2.0f;

}

// =====================================================
// TANK PERCENT
// =====================================================

float tankPercent(
  float distCm,
  float tankHeightCm
) {

  float level =
    tankHeightCm -
    distCm;

  return constrain(
    (
      level /
      tankHeightCm
    ) * 100.0f,

    0.0f,
    100.0f
  );

}

// =====================================================
// AUTOMATIC SPRINKLER
// =====================================================

void runSprinklerAutomation() {

  // NEVER interfere with manual mode

  if (sprinklerManualMode)
    return;

  unsigned long now =
    millis();

  bool tooHot =
    (
      data.airTemp >
      AIR_TEMP_THRESHOLD
    )
    ||
    (
      data.waterTemp >
      WATER_TEMP_THRESHOLD
    );

  switch (autoState) {

    case AUTO_IDLE:

      if (tooHot) {

        Serial.println(
          "[AUTO] High temperature - sprinkler ON"
        );

        setSprinkler(true);

        autoTimer =
          now;

        setAutoState(
          AUTO_RUNNING
        );

      }

      break;

    case AUTO_RUNNING:

      if (
        now - autoTimer >=
        SPRINKLER_RUN_MS
      ) {

        Serial.println(
          "[AUTO] Sprinkler run complete"
        );

        setSprinkler(false);

        autoTimer =
          now;

        setAutoState(
          AUTO_WAITING
        );

      }

      break;

    case AUTO_WAITING:

      if (
        now - autoTimer >=
        SPRINKLER_WAIT_MS
      ) {

        if (tooHot) {

          Serial.println(
            "[AUTO] Still hot - sprinkler ON"
          );

          setSprinkler(true);

          autoTimer =
            now;

          setAutoState(
            AUTO_RUNNING
          );

        }
        else {

          Serial.println(
            "[AUTO] Temperature normal"
          );

          setAutoState(
            AUTO_IDLE
          );

        }

      }

      break;

  }

}

// =====================================================
// SET PUMP
// =====================================================

void setPump(bool on) {

  pumpOn = on;

  digitalWrite(
    PIN_PUMP_RELAY,
    on ?
    RELAY_ON :
    RELAY_OFF
  );

  Serial.print(
    "[PUMP] "
  );

  Serial.println(
    on ?
    "ON" :
    "OFF"
  );

  stateSyncPending = true;

  lcdNeedsRedraw = true;

}

// =====================================================
// SET SPRINKLER
// =====================================================

void setSprinkler(bool on) {

  sprinklerOn = on;

  digitalWrite(
    PIN_SPRINKLER_RELAY,
    on ?
    RELAY_ON :
    RELAY_OFF
  );

  Serial.print(
    "[SPRINKLER] "
  );

  Serial.println(
    on ?
    "ON" :
    "OFF"
  );

  stateSyncPending = true;

  lcdNeedsRedraw = true;

}

// =====================================================
// AUTO STATE
// =====================================================

void setAutoState(
  SprinklerAutoState state
) {

  autoState =
    state;

  stateSyncPending =
    true;

  lcdNeedsRedraw =
    true;

}

// =====================================================
// TANK ALERTS
// =====================================================

void checkTankAlerts() {

  unsigned long now =
    millis();

  if (
    data.mainTankPct <
    TANK_LOW_PCT
  ) {

    if (
      now -
      lastMainTankAlert >
      ALERT_COOLDOWN_MS
    ) {

      lastMainTankAlert =
        now;

      Serial.printf(
        "[WARN] Main tank low: %.0f%%\n",
        data.mainTankPct
      );

    }

  }

  if (
    data.sprTankPct <
    TANK_LOW_PCT
  ) {

    if (
      now -
      lastSprTankAlert >
      ALERT_COOLDOWN_MS
    ) {

      lastSprTankAlert =
        now;

      Serial.printf(
        "[WARN] Sprinkler tank low: %.0f%%\n",
        data.sprTankPct
      );

    }

  }

}

// =====================================================
// LCD
// =====================================================

void updateLCD() {

  switch (lcdPage) {

    case 0:
      drawPage0();
      break;

    case 1:
      drawPage1();
      break;

    case 2:
      drawPage2();
      break;

  }

}

// =====================================================
// LCD PAGE 0
// =====================================================

void drawPage0() {

  lcd.setCursor(
    0,
    0
  );

  lcd.print("PMP:");

  lcd.print(
    pumpOn ?
    "[ON ] " :
    "[OFF] "
  );

  lcd.print("SPR:");

  lcd.print(
    sprinklerOn ?
    "[ON ]" :
    "[OFF]"
  );

  lcd.setCursor(
    0,
    1
  );

  lcd.print(
    "Main:"
  );

  int bars1 =
    constrain(
      (int)(
        data.mainTankPct /
        10
      ),
      0,
      10
    );

  for (
    int i = 0;
    i < 10;
    i++
  ) {

    lcd.write(
      i < bars1 ?
      (byte)2 :
      '-'
    );

  }

  char pct[6];

  snprintf(
    pct,
    sizeof(pct),
    "%3.0f%%",
    data.mainTankPct
  );

  lcd.print(
    pct
  );

  lcd.setCursor(
    0,
    2
  );

  lcd.print(
    "Spr: "
  );

  int bars2 =
    constrain(
      (int)(
        data.sprTankPct /
        10
      ),
      0,
      10
    );

  for (
    int i = 0;
    i < 10;
    i++
  ) {

    lcd.write(
      i < bars2 ?
      (byte)2 :
      '-'
    );

  }

  snprintf(
    pct,
    sizeof(pct),
    "%3.0f%%",
    data.sprTankPct
  );

  lcd.print(
    pct
  );

  lcd.setCursor(
    0,
    3
  );

  if (sprinklerManualMode) {

    lcd.print(
      "[MANUAL SPRINKLER]"
    );

  }
  else {

    lcd.print(
      "[AUTO MODE]       "
    );

  }

}

// =====================================================
// LCD PAGE 1
// =====================================================

void drawPage1() {

  lcd.setCursor(
    0,
    0
  );

  lcd.print(
    " pH    TDS   W.Temp "
  );

  lcd.setCursor(
    0,
    1
  );

  char buf[21];

  snprintf(
    buf,
    sizeof(buf),
    " %-5.1f %-6.0f%-5.1fC",
    data.ph,
    data.tds,
    data.waterTemp
  );

  lcd.print(
    buf
  );

  lcd.setCursor(
    0,
    2
  );

  String row2 =
    phStatus(data.ph) +
    tdsStatus(data.tds) +
    tempStatus(data.waterTemp);

  while (
    row2.length() < 20
  ) {

    row2 += ' ';

  }

  lcd.print(
    row2.substring(
      0,
      20
    )
  );

  lcd.setCursor(
    0,
    3
  );

  lcd.print(
    "   Water Chemistry  "
  );

}

// =====================================================
// LCD PAGE 2
// =====================================================

void drawPage2() {

  char buf[21];

  lcd.setCursor(
    0,
    0
  );

  snprintf(
    buf,
    sizeof(buf),
    " Air Temp:%5.1fC ",
    data.airTemp
  );

  lcd.print(
    buf
  );

  lcd.setCursor(
    0,
    1
  );

  snprintf(
    buf,
    sizeof(buf),
    " Humidity: %2.0f%%    ",
    data.humidity
  );

  lcd.print(
    buf
  );

  lcd.setCursor(
    0,
    2
  );

  bool tempOk =
    data.airTemp >= 20 &&
    data.airTemp <= 28;

  bool humOk =
    data.humidity >= 50 &&
    data.humidity <= 70;

  if (
    tempOk &&
    humOk
  ) {

    lcd.print(
      " Status:   [GOOD]   "
    );

  }
  else if (!tempOk) {

    lcd.print(
      " TEMP OUT OF RANGE! "
    );

  }
  else {

    lcd.print(
      " HUM OUT OF RANGE!  "
    );

  }

  lcd.setCursor(
    0,
    3
  );

  if (sprinklerManualMode) {

    lcd.print(
      " Sprinkler: MANUAL  "
    );

  }
  else {

    switch (autoState) {

      case AUTO_IDLE:

        lcd.print(
          " Auto-spr: STANDBY  "
        );

        break;

      case AUTO_RUNNING:

        lcd.print(
          " Auto-spr: RUNNING  "
        );

        break;

      case AUTO_WAITING:

        lcd.print(
          " Auto-spr: WAITING  "
        );

        break;

    }

  }

}

// =====================================================
// SPLASH
// =====================================================

void drawSplash() {

  lcd.clear();

  lcd.setCursor(
    3,
    1
  );

  lcd.print(
    "  HYDROPONICS   "
  );

  lcd.setCursor(
    3,
    2
  );

  lcd.print(
    "  ROOTERY v2.1  "
  );

  delay(2500);

  lcd.clear();

  lcd.setCursor(
    2,
    1
  );

  lcd.print(
    "Connecting WiFi..."
  );

  delay(500);

}

// =====================================================
// WIFI
// =====================================================

void connectWiFi() {

  if (
    WiFi.status() ==
    WL_CONNECTED
  )
    return;

  Serial.printf(
    "[WiFi] Connecting to %s ",
    WIFI_SSID
  );

  WiFi.begin(
    WIFI_SSID,
    WIFI_PASSWORD
  );

  int tries = 0;

  while (
    WiFi.status() !=
    WL_CONNECTED &&
    tries < 20
  ) {

    delay(500);

    Serial.print(".");

    tries++;

  }

  if (
    WiFi.status() ==
    WL_CONNECTED
  ) {

    Serial.printf(
      "\n[WiFi] Connected! IP: %s\n",
      WiFi.localIP()
        .toString()
        .c_str()
    );

  }
  else {

    Serial.println(
      "\n[WiFi] Connection failed"
    );

  }

}

// =====================================================
// SUPABASE PUSH
// =====================================================

bool pushToSupabase() {

  String url =
    String(SUPABASE_URL) +
    "/rest/v1/sensor_telemetry";

  StaticJsonDocument<384>
    doc;

  doc["ph"] =
    round(
      data.ph * 100
    ) / 100.0;

  doc["tds_ppm"] =
    (int)data.tds;

  doc["water_temp_c"] =
    round(
      data.waterTemp * 10
    ) / 10.0;

  doc["air_temp_c"] =
    round(
      data.airTemp * 10
    ) / 10.0;

  doc["humidity_pct"] =
    (int)data.humidity;

  doc["main_tank_pct"] =
    (int)data.mainTankPct;

  doc["spr_tank_pct"] =
    (int)data.sprTankPct;

  doc["pump_on"] =
    pumpOn;

  doc["sprinkler_on"] =
    sprinklerOn;

  doc["auto_state"] =
    (int)autoState;

  String body;

  serializeJson(
    doc,
    body
  );

  HTTPClient http;

  http.begin(url);

  http.setTimeout(1800);

  http.addHeader(
    "Content-Type",
    "application/json"
  );

  http.addHeader(
    "apikey",
    SUPABASE_KEY
  );

  http.addHeader(
    "Authorization",
    String("Bearer ") +
    SUPABASE_KEY
  );

  http.addHeader(
    "Prefer",
    "return=minimal"
  );

  int code =
    http.POST(body);

  if (
    code >= 200 &&
    code < 300
  ) {

    Serial.printf(
      "[Supabase] Push OK -> HTTP %d\n",
      code
    );

    http.end();

    return true;

  }

  Serial.printf(
    "[Supabase] Push failed -> HTTP %d\n",
    code
  );

  http.end();

  return false;

}

// =====================================================
// SUPABASE COMMAND POLLING
// =====================================================

void pollCommandsFromSupabase() {

  String url =
    String(SUPABASE_URL) +
    "/rest/v1/device_commands?device_id=eq." +
    DEVICE_ID +
    "&executed=eq.false" +
    "&select=id,cmd,command,value" +
    "&order=created_at.asc" +
    "&limit=5";

  HTTPClient http;

  http.begin(url);

  http.setTimeout(1200);

  http.addHeader(
    "apikey",
    SUPABASE_KEY
  );

  http.addHeader(
    "Authorization",
    String("Bearer ") +
    SUPABASE_KEY
  );

  int code =
    http.GET();

  if (
    code < 200 ||
    code >= 300
  ) {

    Serial.printf(
      "[Supabase] Command poll failed -> HTTP %d\n",
      code
    );

    http.end();

    return;

  }

  String payload =
    http.getString();

  http.end();

  StaticJsonDocument<512>
    doc;

  DeserializationError err =
    deserializeJson(
      doc,
      payload
    );

  if (err) {

    Serial.printf(
      "[Supabase] JSON error: %s\n",
      err.c_str()
    );

    return;

  }

  JsonArray arr =
    doc.as<JsonArray>();

  for (
    JsonObject obj :
    arr
  ) {

    int id =
      obj["id"] |
      -1;

    String cmd =
      obj["cmd"] |
      "";

    if (
      cmd.length() == 0
    ) {

      cmd =
        obj["command"] |
        "";

    }

    String value =
      obj["value"] |
      "";

    if (
      id < 0 ||
      cmd.length() == 0
    )
      continue;

    Serial.printf(
      "[CMD] %s %s\n",
      cmd.c_str(),
      value.c_str()
    );

    executeCommand(
      cmd,
      value
    );

    markCommandExecuted(
      id
    );

  }

}

// =====================================================
// EXECUTE COMMAND
// =====================================================

void executeCommand(
  const String &cmd,
  const String &value
) {

  if (
    cmd == "START_PUMP" ||
    cmd == "START_CYCLE"
  ) {

    pumpManualOff = false;

    setPump(true);

    return;

  }

  if (
    cmd == "STOP_PUMP" ||
    cmd == "STOP_CYCLE"
  ) {

    pumpManualOff = true;

    setPump(false);

    return;

  }

  if (
    cmd == "START_SPRINKLER"
  ) {

    sprinklerManualMode =
      true;

    setAutoState(
      AUTO_IDLE
    );

    setSprinkler(true);

    return;

  }

  if (
    cmd == "STOP_SPRINKLER"
  ) {

    sprinklerManualMode =
      true;

    setAutoState(
      AUTO_IDLE
    );

    setSprinkler(false);

    return;

  }

  if (
    cmd == "REBOOT" ||
    cmd == "REBOOT_DEVICE"
  ) {

    Serial.println(
      "[CMD] Rebooting..."
    );

    delay(100);

    ESP.restart();

    return;

  }

  if (
    cmd == "SET_MODE"
  ) {

    if (
      value == "AUTO"
    ) {

      sprinklerManualMode =
        false;

      setAutoState(
        AUTO_IDLE
      );

      Serial.println(
        "[CMD] AUTO MODE"
      );

    }
    else {

      sprinklerManualMode =
        true;

      setAutoState(
        AUTO_IDLE
      );

      Serial.println(
        "[CMD] MANUAL MODE"
      );

    }

    return;

  }

}

// =====================================================
// MARK COMMAND EXECUTED
// =====================================================

void markCommandExecuted(
  int commandId
) {

  String url =
    String(SUPABASE_URL) +
    "/rest/v1/device_commands?id=eq." +
    String(commandId);

  StaticJsonDocument<64>
    doc;

  doc["executed"] =
    true;

  String body;

  serializeJson(
    doc,
    body
  );

  HTTPClient http;

  http.begin(url);

  http.setTimeout(1200);

  http.addHeader(
    "Content-Type",
    "application/json"
  );

  http.addHeader(
    "apikey",
    SUPABASE_KEY
  );

  http.addHeader(
    "Authorization",
    String("Bearer ") +
    SUPABASE_KEY
  );

  http.addHeader(
    "Prefer",
    "return=minimal"
  );

  int code =
    http.PATCH(body);

  Serial.printf(
    "[CMD] Mark executed %d -> HTTP %d\n",
    commandId,
    code
  );

  http.end();

}

// =====================================================
// PH STATUS
// =====================================================

String phStatus(
  float ph
) {

  if (ph < 5.5f)
    return "[LOW] ";

  if (ph > 6.5f)
    return "[HI]  ";

  return "[OK]  ";

}

// =====================================================
// TDS STATUS
// =====================================================

String tdsStatus(
  float tds
) {

  if (tds < 400)
    return "[LOW] ";

  if (tds > 1600)
    return "[HI]  ";

  return "[OK]  ";

}

// =====================================================
// TEMPERATURE STATUS
// =====================================================

String tempStatus(
  float t
) {

  if (t < 18)
    return "[COLD]";

  if (t > 24)
    return "[WARM]";

  return "[OK]  ";

}