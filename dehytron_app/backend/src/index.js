// src/index.js
require('dotenv').config();
const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');

// Start MQTT bridge
require('./services/mqttBridge');

const devicesRoute = require('./routes/devices');

const app = express();
app.use(cors());
app.use(bodyParser.json());

app.use('/devices', devicesRoute);

const PORT = process.env.PORT || 4000;
app.listen(PORT, () => {
  console.log("Rootery backend running on port", PORT);
});

