-- ============================================
-- Telemetry Table Setup for ESP32 Integration
-- ============================================
-- Run this SQL in your Supabase SQL Editor
-- This replaces/upgrades the esp_test table

-- ============================================
-- 1. CREATE TELEMETRY TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS public.telemetry (
    id BIGSERIAL PRIMARY KEY,
    temperature_c DECIMAL(5,2) NOT NULL,
    humidity_pct DECIMAL(5,2) NOT NULL,
    fan_rpm INTEGER,
    solar_wm2 DECIMAL(6,2),
    device_id TEXT DEFAULT 'ESP32-001',
    batch_id BIGINT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add comments
COMMENT ON TABLE public.telemetry IS 'Real-time sensor data from ESP32 devices';
COMMENT ON COLUMN public.telemetry.temperature_c IS 'Temperature in Celsius';
COMMENT ON COLUMN public.telemetry.humidity_pct IS 'Relative humidity percentage';
COMMENT ON COLUMN public.telemetry.fan_rpm IS 'Fan speed in RPM';
COMMENT ON COLUMN public.telemetry.solar_wm2 IS 'Solar intensity in watts per square meter';
COMMENT ON COLUMN public.telemetry.device_id IS 'ESP32 device identifier';
COMMENT ON COLUMN public.telemetry.batch_id IS 'Associated drying batch (if any)';

-- ============================================
-- 2. ENABLE ROW LEVEL SECURITY
-- ============================================

ALTER TABLE public.telemetry ENABLE ROW LEVEL SECURITY;

-- ============================================
-- 3. CREATE RLS POLICIES
-- ============================================

-- Allow anonymous inserts (ESP32 devices)
DROP POLICY IF EXISTS "Allow public insert" ON public.telemetry;
CREATE POLICY "Allow public insert" ON public.telemetry
    FOR INSERT 
    TO anon
    WITH CHECK (true);

-- Allow anonymous reads (Flutter app)
DROP POLICY IF EXISTS "Allow public read" ON public.telemetry;
CREATE POLICY "Allow public read" ON public.telemetry
    FOR SELECT 
    TO anon
    USING (true);

-- Allow authenticated users full access
DROP POLICY IF EXISTS "Allow authenticated all" ON public.telemetry;
CREATE POLICY "Allow authenticated all" ON public.telemetry
    FOR ALL 
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- ============================================
-- 4. CREATE INDEXES FOR PERFORMANCE
-- ============================================

CREATE INDEX IF NOT EXISTS idx_telemetry_created_at 
    ON public.telemetry(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_telemetry_device_id 
    ON public.telemetry(device_id);

CREATE INDEX IF NOT EXISTS idx_telemetry_batch_id 
    ON public.telemetry(batch_id);

CREATE INDEX IF NOT EXISTS idx_telemetry_temperature 
    ON public.telemetry(temperature_c);

-- ============================================
-- 5. CREATE FUNCTION TO AUTO-DELETE OLD DATA
-- ============================================

CREATE OR REPLACE FUNCTION delete_old_telemetry_data()
RETURNS void AS $$
BEGIN
    DELETE FROM public.telemetry
    WHERE id NOT IN (
        SELECT id FROM public.telemetry
        ORDER BY created_at DESC
        LIMIT 1000
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 6. CREATE VIEW FOR LATEST READING
-- ============================================

CREATE OR REPLACE VIEW public.telemetry_latest AS
SELECT 
    id,
    temperature_c,
    humidity_pct,
    fan_rpm,
    solar_wm2,
    device_id,
    batch_id,
    created_at,
    EXTRACT(EPOCH FROM (NOW() - created_at)) AS seconds_ago
FROM public.telemetry
ORDER BY created_at DESC
LIMIT 1;

GRANT SELECT ON public.telemetry_latest TO anon, authenticated;

-- ============================================
-- 7. CREATE VIEW FOR STATISTICS
-- ============================================

CREATE OR REPLACE VIEW public.telemetry_stats AS
SELECT 
    COUNT(*) AS total_readings,
    ROUND(AVG(temperature_c)::numeric, 2) AS avg_temp,
    ROUND(MIN(temperature_c)::numeric, 2) AS min_temp,
    ROUND(MAX(temperature_c)::numeric, 2) AS max_temp,
    ROUND(AVG(humidity_pct)::numeric, 2) AS avg_humidity,
    ROUND(MIN(humidity_pct)::numeric, 2) AS min_humidity,
    ROUND(MAX(humidity_pct)::numeric, 2) AS max_humidity,
    ROUND(AVG(fan_rpm)::numeric, 0) AS avg_fan_rpm,
    ROUND(AVG(solar_wm2)::numeric, 2) AS avg_solar,
    MIN(created_at) AS first_reading,
    MAX(created_at) AS last_reading
FROM public.telemetry;

GRANT SELECT ON public.telemetry_stats TO anon, authenticated;

-- ============================================
-- 8. ENABLE REALTIME
-- ============================================

ALTER PUBLICATION supabase_realtime ADD TABLE telemetry;

-- ============================================
-- 9. INSERT SAMPLE DATA
-- ============================================

INSERT INTO public.telemetry (
    temperature_c, 
    humidity_pct, 
    fan_rpm, 
    solar_wm2
) VALUES
    (25.5, 60.0, 1200, 450.0),
    (26.2, 58.5, 1250, 480.0),
    (27.0, 57.0, 1300, 520.0),
    (26.8, 56.5, 1280, 510.0),
    (25.9, 59.0, 1220, 470.0);

-- ============================================
-- 10. VERIFICATION QUERIES
-- ============================================

-- Check table exists
SELECT EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'telemetry'
) AS table_exists;

-- Check RLS enabled
SELECT relname, relrowsecurity 
FROM pg_class 
WHERE relname = 'telemetry';

-- Check policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd
FROM pg_policies
WHERE tablename = 'telemetry';

-- Check indexes
SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'telemetry';

-- View sample data
SELECT * FROM public.telemetry ORDER BY created_at DESC LIMIT 5;

-- View latest reading
SELECT * FROM public.telemetry_latest;

-- View statistics
SELECT * FROM public.telemetry_stats;

-- ============================================
-- SETUP COMPLETE! ✅
-- ============================================
