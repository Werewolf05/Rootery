const mqtt = require('mqtt');
const supabase = require('./supabaseClient');

const broker = process.env.MQTT_BROKER_URL || 'mqtt://broker.emqx.io';
const client = mqtt.connect(broker);

client.on('connect', () => {
  console.log('MQTT connected to', broker);
  client.subscribe('rootery/+/telemetry', { qos: 1 });
  client.subscribe('rootery/+/status', { qos: 1 });
});

client.on('message', async (topic, msg) => {
  try {
    const payload = JSON.parse(msg.toString());
    const parts = topic.split('/');
    const deviceKey = parts[1];
    const channel = parts[2];

    if (channel === "telemetry") {
      const { data: device } = await supabase
        .from('devices')
        .select('id')
        .eq('device_id', deviceKey)
        .single();

      await supabase.from('telemetry').insert({
        device_id: device ? device.id : null,
        device_key: deviceKey,
        ts: payload.ts || new Date().toISOString(),
        temperature_c: payload.temperature_c ?? null,
        humidity_pct: payload.humidity_pct ?? null,
        light_lux: payload.light_lux ?? null,
        fan_rpm: payload.fan_rpm ?? null,
        airflow_lpm: payload.airflow_est_lpm ?? null,
        heater_on: payload.heater_on ?? null,
        fan_on: payload.fan_on ?? null,
        mode: payload.mode ?? null,
        current_preset: payload.current_preset ?? null,
        raw_payload: payload
      });

      await supabase.from('devices')
        .update({ last_seen: new Date().toISOString(), is_online: true })
        .eq('device_id', deviceKey);

      console.log("Telemetry stored for", deviceKey);
    }

    if (channel === "status") {
      await supabase.from('devices')
        .update({ last_seen: new Date().toISOString(), is_online: payload.online })
        .eq('device_id', deviceKey);
    }

  } catch (err) {
    console.error("MQTT message error:", err.message);
  }
});

module.exports = client;

