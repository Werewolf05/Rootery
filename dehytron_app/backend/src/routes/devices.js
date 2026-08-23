const express = require('express');
const router = express.Router();
const mqttClient = require('../services/mqttBridge');
const supabase = require('../services/supabaseClient');

// Send control command
router.post('/:deviceId/control', async (req, res) => {
  const { deviceId } = req.params;
  const cmd = req.body;

  const topic = `rootery/${deviceId}/control`;

  mqttClient.publish(topic, JSON.stringify(cmd), { qos: 1 }, (err) => {
    if (err) return res.status(500).json({ error: 'MQTT publish failed', details: err.message });

    return res.json({ ok: true });
  });
});

// Get latest telemetry
router.get('/:deviceId/latest', async (req, res) => {
  const { deviceId } = req.params;

  const { data } = await supabase
    .from('telemetry')
    .select('*')
    .eq('device_key', deviceId)
    .order('ts', { ascending: false })
    .limit(1);

  res.json(data ? data[0] : null);
});

module.exports = router;

