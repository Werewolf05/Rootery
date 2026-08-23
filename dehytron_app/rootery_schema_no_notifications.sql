-- ===================================================
-- ROOTERY DATABASE SCHEMA (NO NOTIFICATIONS)
-- For: ESP32 + Flutter app + Supabase
-- Run in Supabase SQL Editor
-- ===================================================

-- Optional cleanup scheduler extension
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- ===================================================
-- 1) SENSOR TELEMETRY (ESP32 -> Supabase)
-- Matches esp32_rootery_controller_v2.ino payload
-- ===================================================
CREATE TABLE IF NOT EXISTS public.sensor_telemetry (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- chemistry
  ph NUMERIC(4,2),
  tds_ppm INTEGER,
  water_temp_c NUMERIC(4,1),

  -- environment
  air_temp_c NUMERIC(4,1),
  humidity_pct INTEGER,

  -- tank levels
  main_tank_pct INTEGER,
  spr_tank_pct INTEGER,

  -- actuator + automation state
  pump_on BOOLEAN NOT NULL DEFAULT TRUE,
  sprinkler_on BOOLEAN NOT NULL DEFAULT FALSE,
  auto_state SMALLINT NOT NULL DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_sensor_telemetry_created
  ON public.sensor_telemetry (created_at DESC);

-- ===================================================
-- 2) DEVICE STATE (single latest row for dashboard)
-- ===================================================
CREATE TABLE IF NOT EXISTS public.device_state (
  id INTEGER PRIMARY KEY DEFAULT 1,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  pump_on BOOLEAN NOT NULL DEFAULT TRUE,
  sprinkler_on BOOLEAN NOT NULL DEFAULT FALSE,
  auto_state SMALLINT NOT NULL DEFAULT 0,
  wifi_rssi INTEGER,
  uptime_s BIGINT,
  online BOOLEAN NOT NULL DEFAULT FALSE
);

INSERT INTO public.device_state (id)
VALUES (1)
ON CONFLICT (id) DO NOTHING;

CREATE OR REPLACE FUNCTION public.touch_device_state_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_device_state_touch_updated_at ON public.device_state;
CREATE TRIGGER trg_device_state_touch_updated_at
BEFORE UPDATE ON public.device_state
FOR EACH ROW
EXECUTE FUNCTION public.touch_device_state_updated_at();

-- ===================================================
-- 3) DEVICE COMMANDS (optional now, ready for later)
-- App -> ESP32 control queue
-- ===================================================
CREATE TABLE IF NOT EXISTS public.device_commands (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  command TEXT NOT NULL,
  params JSONB,
  executed BOOLEAN NOT NULL DEFAULT FALSE,
  executed_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_device_commands_unexecuted
  ON public.device_commands (created_at ASC)
  WHERE executed = FALSE;

CREATE OR REPLACE FUNCTION public.set_device_command_executed_at()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.executed = TRUE AND OLD.executed = FALSE AND NEW.executed_at IS NULL THEN
    NEW.executed_at = NOW();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_device_commands_set_executed_at ON public.device_commands;
CREATE TRIGGER trg_device_commands_set_executed_at
BEFORE UPDATE ON public.device_commands
FOR EACH ROW
EXECUTE FUNCTION public.set_device_command_executed_at();

-- ===================================================
-- 4) RLS POLICIES
-- No alerts table/policies (notifications skipped)
-- ===================================================
ALTER TABLE public.sensor_telemetry ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.device_state ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.device_commands ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  -- sensor_telemetry: ESP32 can insert, app can read
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'sensor_telemetry' AND policyname = 'anon_insert_sensor_telemetry'
  ) THEN
    CREATE POLICY anon_insert_sensor_telemetry
      ON public.sensor_telemetry FOR INSERT
      TO anon WITH CHECK (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'sensor_telemetry' AND policyname = 'anon_select_sensor_telemetry'
  ) THEN
    CREATE POLICY anon_select_sensor_telemetry
      ON public.sensor_telemetry FOR SELECT
      TO anon USING (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'sensor_telemetry' AND policyname = 'authenticated_select_sensor_telemetry'
  ) THEN
    CREATE POLICY authenticated_select_sensor_telemetry
      ON public.sensor_telemetry FOR SELECT
      TO authenticated USING (true);
  END IF;

  -- device_state: ESP32/app upsert + read
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'device_state' AND policyname = 'anon_select_device_state'
  ) THEN
    CREATE POLICY anon_select_device_state
      ON public.device_state FOR SELECT
      TO anon USING (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'device_state' AND policyname = 'anon_insert_device_state'
  ) THEN
    CREATE POLICY anon_insert_device_state
      ON public.device_state FOR INSERT
      TO anon WITH CHECK (id = 1);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'device_state' AND policyname = 'anon_update_device_state'
  ) THEN
    CREATE POLICY anon_update_device_state
      ON public.device_state FOR UPDATE
      TO anon USING (id = 1) WITH CHECK (id = 1);
  END IF;

  -- device_commands: app inserts, ESP32 reads+marks executed
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'device_commands' AND policyname = 'anon_select_device_commands'
  ) THEN
    CREATE POLICY anon_select_device_commands
      ON public.device_commands FOR SELECT
      TO anon USING (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'device_commands' AND policyname = 'anon_update_device_commands'
  ) THEN
    CREATE POLICY anon_update_device_commands
      ON public.device_commands FOR UPDATE
      TO anon USING (executed = FALSE) WITH CHECK (executed = TRUE);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'device_commands' AND policyname = 'authenticated_insert_device_commands'
  ) THEN
    CREATE POLICY authenticated_insert_device_commands
      ON public.device_commands FOR INSERT
      TO authenticated WITH CHECK (true);
  END IF;
END $$;

-- ===================================================
-- 5) REALTIME SUBSCRIPTIONS
-- ===================================================
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'sensor_telemetry'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.sensor_telemetry;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'device_state'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.device_state;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'device_commands'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.device_commands;
  END IF;
END $$;

-- ===================================================
-- 6) VIEWS FOR APP/DASHBOARD
-- ===================================================
CREATE OR REPLACE VIEW public.latest_telemetry AS
SELECT *
FROM public.sensor_telemetry
ORDER BY created_at DESC
LIMIT 1;

CREATE OR REPLACE VIEW public.telemetry_24h AS
SELECT *
FROM public.sensor_telemetry
WHERE created_at > NOW() - INTERVAL '24 hours'
ORDER BY created_at ASC;

CREATE OR REPLACE VIEW public.pending_commands AS
SELECT id, command, params, created_at
FROM public.device_commands
WHERE executed = FALSE
ORDER BY created_at ASC;

-- ===================================================
-- 7) OPTIONAL DATA RETENTION (telemetry only)
-- ===================================================
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM cron.job WHERE jobname = 'rootery-delete-old-sensor-telemetry'
  ) THEN
    PERFORM cron.schedule(
      'rootery-delete-old-sensor-telemetry',
      '0 3 * * *',
      $$DELETE FROM public.sensor_telemetry WHERE created_at < NOW() - INTERVAL '30 days'$$
    );
  END IF;
END $$;

-- ===================================================
-- DONE CHECK
-- ===================================================
-- SELECT table_name FROM information_schema.tables
-- WHERE table_schema = 'public'
-- ORDER BY table_name;
