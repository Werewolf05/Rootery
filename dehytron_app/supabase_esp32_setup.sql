-- ============================================
-- Rootery ESP32 Integration - Database Setup
-- ============================================
-- Run this entire file in Supabase SQL Editor
-- Dashboard â†’ SQL Editor â†’ New Query â†’ Paste â†’ Run

-- ============================================
-- 1. CREATE ESP_TEST TABLE
-- ============================================
-- This table stores real-time sensor data from ESP32

CREATE TABLE IF NOT EXISTS public.esp_test (
    id BIGSERIAL PRIMARY KEY,
    temp DECIMAL(5,2) NOT NULL,
    humidity DECIMAL(5,2) NOT NULL,
    message TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add comments for documentation
COMMENT ON TABLE public.esp_test IS 'Stores real-time sensor data from ESP32 devices';
COMMENT ON COLUMN public.esp_test.temp IS 'Temperature in Celsius';
COMMENT ON COLUMN public.esp_test.humidity IS 'Relative humidity percentage';
COMMENT ON COLUMN public.esp_test.message IS 'Optional status message from ESP32';

-- ============================================
-- 2. ENABLE ROW LEVEL SECURITY (RLS)
-- ============================================

ALTER TABLE public.esp_test ENABLE ROW LEVEL SECURITY;

-- ============================================
-- 3. CREATE RLS POLICIES
-- ============================================

-- Allow anonymous (ESP32) to insert data
DROP POLICY IF EXISTS "Allow public insert" ON public.esp_test;
CREATE POLICY "Allow public insert" ON public.esp_test
    FOR INSERT 
    TO anon
    WITH CHECK (true);

-- Allow anonymous (Flutter app) to read data
DROP POLICY IF EXISTS "Allow public read" ON public.esp_test;
CREATE POLICY "Allow public read" ON public.esp_test
    FOR SELECT 
    TO anon
    USING (true);

-- Allow authenticated users full access
DROP POLICY IF EXISTS "Allow authenticated all" ON public.esp_test;
CREATE POLICY "Allow authenticated all" ON public.esp_test
    FOR ALL 
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- ============================================
-- 4. CREATE INDEXES FOR PERFORMANCE
-- ============================================

-- Index for fast queries sorted by timestamp
CREATE INDEX IF NOT EXISTS idx_esp_test_created_at 
    ON public.esp_test(created_at DESC);

-- Index for temperature range queries
CREATE INDEX IF NOT EXISTS idx_esp_test_temp 
    ON public.esp_test(temp);

-- Index for humidity range queries
CREATE INDEX IF NOT EXISTS idx_esp_test_humidity 
    ON public.esp_test(humidity);

-- ============================================
-- 5. CREATE FUNCTION TO AUTO-DELETE OLD DATA
-- ============================================
-- Keeps only last 1000 records to prevent table bloat

CREATE OR REPLACE FUNCTION delete_old_esp_test_data()
RETURNS void AS $$
BEGIN
    DELETE FROM public.esp_test
    WHERE id NOT IN (
        SELECT id FROM public.esp_test
        ORDER BY created_at DESC
        LIMIT 1000
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 6. CREATE CRON JOB (Optional - requires pg_cron extension)
-- ============================================
-- Automatically cleanup old data every hour
-- Note: This requires the pg_cron extension to be enabled
-- Dashboard â†’ Database â†’ Extensions â†’ Enable pg_cron

-- Uncomment below if you have pg_cron enabled:
/*
SELECT cron.schedule(
    'cleanup-esp-test-data',
    '0 * * * *',  -- Every hour
    'SELECT delete_old_esp_test_data();'
);
*/

-- ============================================
-- 7. INSERT SAMPLE DATA FOR TESTING
-- ============================================

INSERT INTO public.esp_test (temp, humidity, message) VALUES
    (25.2, 60.0, 'ESP32 test OK'),
    (26.5, 58.5, 'Normal operation'),
    (24.8, 62.3, 'Sensor reading'),
    (27.1, 55.7, 'Drying in progress'),
    (25.9, 59.2, 'System stable'),
    (26.3, 57.8, 'All sensors OK'),
    (25.5, 61.0, 'Temperature normal'),
    (24.9, 63.5, 'Humidity high'),
    (26.8, 56.2, 'Optimal conditions'),
    (25.7, 60.5, 'Data logging active');

-- ============================================
-- 8. CREATE VIEW FOR LATEST READINGS
-- ============================================

CREATE OR REPLACE VIEW public.esp_test_latest AS
SELECT 
    id,
    temp,
    humidity,
    message,
    created_at,
    EXTRACT(EPOCH FROM (NOW() - created_at)) AS seconds_ago
FROM public.esp_test
ORDER BY created_at DESC
LIMIT 1;

-- Grant access to view
GRANT SELECT ON public.esp_test_latest TO anon, authenticated;

-- ============================================
-- 9. CREATE VIEW FOR STATISTICS
-- ============================================

CREATE OR REPLACE VIEW public.esp_test_stats AS
SELECT 
    COUNT(*) AS total_readings,
    ROUND(AVG(temp)::numeric, 2) AS avg_temp,
    ROUND(MIN(temp)::numeric, 2) AS min_temp,
    ROUND(MAX(temp)::numeric, 2) AS max_temp,
    ROUND(AVG(humidity)::numeric, 2) AS avg_humidity,
    ROUND(MIN(humidity)::numeric, 2) AS min_humidity,
    ROUND(MAX(humidity)::numeric, 2) AS max_humidity,
    MIN(created_at) AS first_reading,
    MAX(created_at) AS last_reading
FROM public.esp_test;

-- Grant access to view
GRANT SELECT ON public.esp_test_stats TO anon, authenticated;

-- ============================================
-- 10. ENABLE REALTIME (Optional)
-- ============================================
-- This allows Flutter app to receive instant updates
-- Dashboard â†’ Database â†’ Replication â†’ esp_test â†’ Enable

ALTER PUBLICATION supabase_realtime ADD TABLE esp_test;

-- ============================================
-- 11. VERIFICATION QUERIES
-- ============================================
-- Run these to verify setup worked correctly

-- Check if table exists
SELECT EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'esp_test'
) AS table_exists;

-- Check RLS is enabled
SELECT relname, relrowsecurity 
FROM pg_class 
WHERE relname = 'esp_test';

-- Check policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies
WHERE tablename = 'esp_test';

-- Check indexes
SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'esp_test';

-- View sample data
SELECT * FROM public.esp_test ORDER BY created_at DESC LIMIT 5;

-- View latest reading
SELECT * FROM public.esp_test_latest;

-- View statistics
SELECT * FROM public.esp_test_stats;

-- ============================================
-- SETUP COMPLETE! âœ…
-- ============================================
-- 
-- Next steps:
-- 1. Upload ESP32 code to your device
-- 2. Open Serial Monitor to verify connection
-- 3. Run Flutter app and navigate to ESP32 Data screen
-- 4. Watch real-time sensor data flow in!
--
-- Troubleshooting:
-- - If ESP32 gets HTTP 404: Table doesn't exist, check table name
-- - If ESP32 gets HTTP 401: Check RLS policies allow anon inserts
-- - If no data in app: Verify ESP32 is sending data (check Supabase dashboard)
-- 
-- ============================================

