-- ===================================================
-- ROOTERY MINIMAL DATABASE SETUP
-- Simplified for App-Controlled System
-- ===================================================

-- 1. TELEMETRY TABLE (ESP32 â†’ Supabase)
CREATE TABLE IF NOT EXISTS telemetry (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  device_id TEXT NOT NULL DEFAULT 'ROOTERY_01',
  temperature FLOAT8,
  humidity FLOAT8,
  target_temp INT DEFAULT 50,
  cycle_running BOOLEAN DEFAULT FALSE,
  elapsed_seconds INT DEFAULT 0,
  remaining_seconds INT DEFAULT 0,
  progress_percent INT DEFAULT 0,
  light_on BOOLEAN DEFAULT FALSE,
  wifi_rssi INT,
  current_crop TEXT DEFAULT 'None',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. DEVICE COMMANDS TABLE (App â†’ ESP32)
CREATE TABLE IF NOT EXISTS device_commands (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  device_id TEXT NOT NULL DEFAULT 'ROOTERY_01',
  cmd TEXT NOT NULL,
  value TEXT,
  executed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Compatibility migration for existing deployments created with older schemas.
-- CREATE TABLE IF NOT EXISTS does not add missing columns to existing tables,
-- so we patch them here safely.
ALTER TABLE telemetry
  ADD COLUMN IF NOT EXISTS device_id TEXT NOT NULL DEFAULT 'ROOTERY_01';

-- Remove deprecated fields that are no longer used.
ALTER TABLE telemetry
  DROP COLUMN IF EXISTS target_airflow;

ALTER TABLE telemetry
  DROP COLUMN IF EXISTS heater_on;

ALTER TABLE telemetry
  DROP COLUMN IF EXISTS fan_on;

ALTER TABLE device_commands
  ADD COLUMN IF NOT EXISTS device_id TEXT NOT NULL DEFAULT 'ROOTERY_01';

ALTER TABLE device_commands
  ADD COLUMN IF NOT EXISTS cmd TEXT;

ALTER TABLE device_commands
  ADD COLUMN IF NOT EXISTS value TEXT;

ALTER TABLE device_commands
  ADD COLUMN IF NOT EXISTS command TEXT;

-- If an older schema used command/params instead of cmd/value, map command -> cmd.
UPDATE device_commands
SET cmd = command
WHERE cmd IS NULL
  AND EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'device_commands'
      AND column_name = 'command'
  );

ALTER TABLE device_commands
  ALTER COLUMN cmd SET DEFAULT 'UNKNOWN_CMD';

UPDATE device_commands
SET cmd = 'UNKNOWN_CMD'
WHERE cmd IS NULL;

ALTER TABLE device_commands
  ALTER COLUMN cmd SET NOT NULL;

-- If command exists (legacy schema), backfill and enforce non-null safely.
UPDATE device_commands
SET command = cmd
WHERE command IS NULL
  AND cmd IS NOT NULL;

ALTER TABLE device_commands
  ALTER COLUMN command SET DEFAULT 'UNKNOWN_CMD';

UPDATE device_commands
SET command = 'UNKNOWN_CMD'
WHERE command IS NULL;

CREATE TABLE IF NOT EXISTS device_states (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  device_id TEXT NOT NULL UNIQUE,
  current_state TEXT DEFAULT 'IDLE',
  target_temp INT,
  cycle_duration_sec INT,
  elapsed_seconds INT DEFAULT 0,
  progress_percent INT DEFAULT 0,
  current_crop TEXT,
  last_updated TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO device_states (device_id)
VALUES ('ROOTERY_01')
ON CONFLICT (device_id) DO NOTHING;

-- 3. CROP DATABASE TABLE (Optional - For app reference)
CREATE TABLE IF NOT EXISTS crop_database (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  crop_name TEXT NOT NULL UNIQUE,
  temperature INT NOT NULL,
  time_minutes INT NOT NULL,
  category TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE crop_database
  DROP COLUMN IF EXISTS airflow;

-- ===================================================
-- INSERT DEFAULT CROP DATA
-- ===================================================
INSERT INTO crop_database (crop_name, temperature, time_minutes, category) VALUES
  ('Tomato', 60, 180, 'Vegetable'),
  ('Carrot', 55, 150, 'Vegetable'),
  ('Apple', 50, 200, 'Fruit'),
  ('Banana', 50, 160, 'Fruit'),
  ('Chilli', 55, 140, 'Spice'),
  ('Onion', 55, 180, 'Vegetable'),
  ('Potato', 60, 200, 'Vegetable'),
  ('Ginger', 50, 160, 'Spice'),
  ('Mango', 55, 220, 'Fruit'),
  ('Beans', 55, 150, 'Vegetable'),
  ('Orange', 50, 180, 'Fruit'),
  ('Pineapple', 55, 210, 'Fruit'),
  ('Spinach', 45, 120, 'Leafy'),
  ('Lemon', 45, 100, 'Fruit'),
  ('Coconut', 55, 240, 'Fruit'),
  ('Papaya', 55, 200, 'Fruit'),
  ('Cauliflower', 60, 180, 'Vegetable'),
  ('Cabbage', 55, 160, 'Vegetable'),
  ('Capsicum', 55, 150, 'Vegetable'),
  ('Peas', 50, 140, 'Vegetable')
ON CONFLICT (crop_name) DO NOTHING;

-- ===================================================
-- ENABLE ROW LEVEL SECURITY (RLS)
-- ===================================================
ALTER TABLE telemetry ENABLE ROW LEVEL SECURITY;
ALTER TABLE device_commands ENABLE ROW LEVEL SECURITY;
ALTER TABLE crop_database ENABLE ROW LEVEL SECURITY;

-- ===================================================
-- TELEMETRY POLICIES (Allow ESP32 to send data)
-- ===================================================
-- Check if policy exists before creating
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'anon_all_telemetry' AND tablename = 'telemetry') THEN
    CREATE POLICY "anon_all_telemetry" ON telemetry
      FOR ALL TO anon USING (true) WITH CHECK (true);
  END IF;
END $$;

-- ===================================================
-- DEVICE COMMANDS POLICIES (Allow app to send commands)
-- ===================================================
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'anon_all_commands' AND tablename = 'device_commands') THEN
    CREATE POLICY "anon_all_commands" ON device_commands
      FOR ALL TO anon USING (true) WITH CHECK (true);
  END IF;
END $$;

-- ===================================================
-- CROP DATABASE POLICIES (Allow app to read crops)
-- ===================================================
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'anon_select_crops' AND tablename = 'crop_database') THEN
    CREATE POLICY "anon_select_crops" ON crop_database
      FOR SELECT TO anon USING (true);
  END IF;
END $$;

-- ===================================================
-- CREATE INDEXES FOR PERFORMANCE
-- ===================================================
-- Index for querying telemetry by device and time
CREATE INDEX IF NOT EXISTS idx_telemetry_device_created 
  ON telemetry(device_id, created_at DESC);

-- Index for querying unexecuted commands
CREATE INDEX IF NOT EXISTS idx_commands_device_executed 
  ON device_commands(device_id, executed, created_at ASC);

-- Index for device states queries
CREATE INDEX IF NOT EXISTS idx_device_states_device 
  ON device_states(device_id);

-- Index for crop queries
CREATE INDEX IF NOT EXISTS idx_crop_name 
  ON crop_database(crop_name);

-- ===================================================
-- CREATE FUNCTIONS AND TRIGGERS
-- ===================================================

-- Function to automatically update last_updated timestamp
CREATE OR REPLACE FUNCTION update_last_updated_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.last_updated = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger for device_states table
CREATE TRIGGER update_device_states_timestamp 
  BEFORE UPDATE ON device_states
  FOR EACH ROW
  EXECUTE FUNCTION update_last_updated_column();

-- Function to clean up old telemetry data (keep last 30 days)
CREATE OR REPLACE FUNCTION cleanup_old_telemetry()
RETURNS void AS $$
BEGIN
  DELETE FROM telemetry 
  WHERE created_at < NOW() - INTERVAL '30 days';
END;
$$ language 'plpgsql';

-- ===================================================
-- CLEANUP FUNCTION (Optional)
-- ===================================================
CREATE OR REPLACE FUNCTION cleanup_old_data()
RETURNS void AS $$
BEGIN
  -- Delete telemetry older than 30 days
  DELETE FROM telemetry 
  WHERE created_at < NOW() - INTERVAL '30 days';
  
  -- Delete executed commands older than 7 days
  DELETE FROM device_commands 
  WHERE executed = true 
  AND created_at < NOW() - INTERVAL '7 days';
END;
$$ language 'plpgsql';

-- ===================================================
-- SIMPLE VIEW FOR PENDING COMMANDS
-- ===================================================
CREATE OR REPLACE VIEW pending_commands AS
SELECT 
  id,
  device_id,
  cmd,
  value,
  created_at,
  EXTRACT(EPOCH FROM (NOW() - created_at)) as seconds_pending
FROM device_commands 
WHERE executed = false
ORDER BY created_at ASC;

-- ===================================================
-- SIMPLE VIEW FOR CROP PRESETS
-- ===================================================
CREATE OR REPLACE VIEW crop_presets AS
SELECT 
  crop_name,
  temperature,
  time_minutes,
  category
FROM crop_database
ORDER BY category, crop_name;

-- ===================================================
-- SIMPLE PROCEDURE TO SEND COMMAND
-- ===================================================
CREATE OR REPLACE PROCEDURE send_command(
  device_id_param TEXT,
  command_param TEXT,
  value_param TEXT DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO device_commands (device_id, command, cmd, value, executed)
  VALUES (device_id_param, command_param, command_param, value_param, false);
END;
$$;

-- ===================================================
-- TEST DATA (Optional)
-- ===================================================
-- Insert a test command
INSERT INTO device_commands (device_id, command, cmd, value, executed) 
VALUES ('ROOTERY_01', 'SET_TEMP', 'SET_TEMP', '55', false)
ON CONFLICT DO NOTHING;

-- Insert test telemetry
INSERT INTO telemetry (device_id, temperature, humidity, target_temp, current_crop)
VALUES ('ROOTERY_01', 25.5, 60.0, 50, 'Tomato')
ON CONFLICT DO NOTHING;

-- ===================================================
-- VERIFY SETUP
-- ===================================================
DO $$
BEGIN
  -- Check tables
  RAISE NOTICE 'Database setup complete!';
  RAISE NOTICE 'Tables: telemetry, device_commands, crop_database';
  RAISE NOTICE 'RLS policies applied';
  RAISE NOTICE 'Indexes created';
  RAISE NOTICE '';
  RAISE NOTICE 'APP COMMANDS:';
  RAISE NOTICE '  SELECT_CROP, START_CYCLE, STOP_CYCLE';
  RAISE NOTICE '  SET_TEMP, SET_TIME, REBOOT';
END $$;

-- ===================================================
-- USEFUL QUERIES
-- ===================================================
/*
-- 1. Get latest telemetry
SELECT * FROM telemetry 
WHERE device_id = 'ROOTERY_01' 
ORDER BY created_at DESC 
LIMIT 5;

-- 2. Get pending commands
SELECT * FROM pending_commands 
WHERE device_id = 'ROOTERY_01';

-- 3. Send a command from app
CALL send_command('ROOTERY_01', 'START_CYCLE', '');

-- 4. Get crop list
SELECT * FROM crop_presets;

-- 5. Clean old data (run weekly)
SELECT cleanup_old_data();
*/

