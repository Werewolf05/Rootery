-- ================================================================
-- DEVICE COMMANDS TABLE SETUP
-- Purpose: Bidirectional communication between Flutter app and ESP32
-- Commands flow: Flutter → Database → ESP32 → Database (acknowledgment)
-- ================================================================

-- 1. CREATE COMMANDS TABLE
-- Stores commands sent from app to ESP32 devices
CREATE TABLE IF NOT EXISTS public.device_commands (
    id BIGSERIAL PRIMARY KEY,
    device_id TEXT NOT NULL DEFAULT 'ESP32-001',
    command_type TEXT NOT NULL CHECK (command_type IN (
        'start_drying',
        'stop_drying',
        'set_temperature',
        'emergency_stop'
    )),
    parameters JSONB DEFAULT '{}',
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN (
        'pending',
        'processing',
        'completed',
        'failed',
        'expired'
    )),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    sent_at TIMESTAMPTZ,
    executed_at TIMESTAMPTZ,
    error_message TEXT,
    created_by TEXT
);

-- 2. CREATE INDEXES FOR PERFORMANCE
CREATE INDEX IF NOT EXISTS idx_device_commands_device_id 
    ON public.device_commands(device_id);

CREATE INDEX IF NOT EXISTS idx_device_commands_status 
    ON public.device_commands(status);

CREATE INDEX IF NOT EXISTS idx_device_commands_created_at 
    ON public.device_commands(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_device_commands_pending 
    ON public.device_commands(device_id, status) 
    WHERE status = 'pending';

-- 3. ENABLE ROW LEVEL SECURITY
ALTER TABLE public.device_commands ENABLE ROW LEVEL SECURITY;

-- 4. CREATE RLS POLICIES
-- Allow app to insert commands
CREATE POLICY "Allow app to insert commands"
    ON public.device_commands
    FOR INSERT
    TO anon, authenticated
    WITH CHECK (true);

-- Allow app to read all commands
CREATE POLICY "Allow app to read commands"
    ON public.device_commands
    FOR SELECT
    TO anon, authenticated
    USING (true);

-- Allow ESP32 to read its pending commands
CREATE POLICY "Allow ESP32 to read pending commands"
    ON public.device_commands
    FOR SELECT
    TO anon
    USING (status = 'pending' OR status = 'processing');

-- Allow ESP32 to update command status
CREATE POLICY "Allow ESP32 to update commands"
    ON public.device_commands
    FOR UPDATE
    TO anon, authenticated
    USING (true);

-- 5. CREATE FUNCTION TO AUTO-EXPIRE OLD PENDING COMMANDS
CREATE OR REPLACE FUNCTION expire_old_commands()
RETURNS void AS $$
BEGIN
    UPDATE public.device_commands
    SET status = 'expired',
        error_message = 'Command expired after 5 minutes'
    WHERE status = 'pending'
    AND created_at < NOW() - INTERVAL '5 minutes';
END;
$$ LANGUAGE plpgsql;

-- 6. CREATE FUNCTION TO DELETE OLD COMPLETED COMMANDS
CREATE OR REPLACE FUNCTION delete_old_commands()
RETURNS void AS $$
BEGIN
    DELETE FROM public.device_commands
    WHERE status IN ('completed', 'expired', 'failed')
    AND created_at < NOW() - INTERVAL '7 days';
END;
$$ LANGUAGE plpgsql;

-- 7. CREATE VIEW FOR PENDING COMMANDS (for ESP32 to query)
CREATE OR REPLACE VIEW device_commands_pending AS
SELECT 
    id,
    device_id,
    command_type,
    parameters,
    created_at
FROM public.device_commands
WHERE status = 'pending'
ORDER BY created_at ASC;

-- 8. CREATE VIEW FOR COMMAND HISTORY (for app dashboard)
CREATE OR REPLACE VIEW device_commands_history AS
SELECT 
    id,
    device_id,
    command_type,
    parameters,
    status,
    created_at,
    executed_at,
    error_message,
    EXTRACT(EPOCH FROM (executed_at - created_at)) as execution_time_seconds
FROM public.device_commands
ORDER BY created_at DESC
LIMIT 100;

-- 9. ENABLE REALTIME FOR COMMANDS TABLE
ALTER PUBLICATION supabase_realtime ADD TABLE device_commands;

-- 10. INSERT SAMPLE COMMANDS FOR TESTING
INSERT INTO public.device_commands (device_id, command_type, parameters, status)
VALUES 
    ('ESP32-001', 'start_drying', '{"mode": "auto"}', 'pending'),
    ('ESP32-001', 'set_temperature', '{"target": 28}', 'pending'),
    ('ESP32-001', 'stop_drying', '{}', 'pending');

-- 11. VERIFICATION QUERIES
-- Check if table exists
SELECT EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'device_commands'
);

-- Check RLS is enabled
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE tablename = 'device_commands';

-- Check policies
SELECT policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'device_commands';

-- Check indexes
SELECT indexname, indexdef 
FROM pg_indexes 
WHERE tablename = 'device_commands';

-- Check pending commands
SELECT * FROM device_commands_pending;

-- Check command history
SELECT * FROM device_commands_history;

-- ================================================================
-- USAGE EXAMPLES
-- ================================================================

-- FLUTTER APP: Send a start drying command
-- INSERT INTO device_commands (device_id, command_type, parameters)
-- VALUES ('ESP32-001', 'start_drying', '{"mode": "auto"}');

-- FLUTTER APP: Send temperature setpoint command
-- INSERT INTO device_commands (device_id, command_type, parameters)
-- VALUES ('ESP32-001', 'set_temperature', '{"target": 28}');

-- ESP32: Fetch pending commands
-- SELECT * FROM device_commands_pending WHERE device_id = 'ESP32-001';

-- ESP32: Mark command as processing
-- UPDATE device_commands 
-- SET status = 'processing', sent_at = NOW() 
-- WHERE id = 123;

-- ESP32: Mark command as completed
-- UPDATE device_commands 
-- SET status = 'completed', executed_at = NOW() 
-- WHERE id = 123;

-- ESP32: Mark command as failed
-- UPDATE device_commands 
-- SET status = 'failed', executed_at = NOW(), error_message = 'Invalid parameter' 
-- WHERE id = 123;

-- ================================================================
-- MAINTENANCE
-- ================================================================

-- Run periodically to expire old pending commands (call from cron or app)
-- SELECT expire_old_commands();

-- Run periodically to clean up old completed commands
-- SELECT delete_old_commands();

-- Check command statistics
SELECT 
    command_type,
    status,
    COUNT(*) as count,
    AVG(EXTRACT(EPOCH FROM (executed_at - created_at))) as avg_execution_time
FROM device_commands
WHERE created_at > NOW() - INTERVAL '24 hours'
GROUP BY command_type, status;
