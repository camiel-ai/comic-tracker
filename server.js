const express = require('express');
const fs = require('fs');
const path = require('path');
const app = express();
const PORT = 3456;
const DATA_FILE = path.join(__dirname, 'data.json');

app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

function loadData() {
  if (!fs.existsSync(DATA_FILE)) return {};
  return JSON.parse(fs.readFileSync(DATA_FILE, 'utf8'));
}
function saveData(d) { fs.writeFileSync(DATA_FILE, JSON.stringify(d, null, 2)); }

// Get user statuses
app.get('/api/status', (req, res) => res.json(loadData()));

// Set album status: { series, album, status } where status = "owned"|"wanted"|null
app.post('/api/status', (req, res) => {
  const { series, album, status } = req.body;
  const data = loadData();
  if (!data[series]) data[series] = {};
  if (status) data[series][album] = status;
  else delete data[series][album];
  saveData(data);
  res.json({ ok: true });
});

app.listen(PORT, '0.0.0.0', () => console.log(`Comic Tracker running at http://localhost:${PORT}`));
