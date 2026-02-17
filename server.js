const express = require('express');
const fs = require('fs');
const path = require('path');
const app = express();
const PORT = process.env.PORT || 3456;
const DATA_FILE = path.join(__dirname, 'data.json');

app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

function loadData() {
  if (!fs.existsSync(DATA_FILE)) return {};
  return JSON.parse(fs.readFileSync(DATA_FILE, 'utf8'));
}
function saveData(d) { fs.writeFileSync(DATA_FILE, JSON.stringify(d, null, 2)); }

app.get('/api/status', (req, res) => res.json(loadData()));

app.post('/api/status', (req, res) => {
  const { series, album, status } = req.body;
  const data = loadData();
  if (!data[series]) data[series] = {};
  if (status) data[series][album] = status;
  else delete data[series][album];
  saveData(data);
  res.json({ ok: true });
});

app.listen(PORT, () => console.log(`Comic Tracker running on port ${PORT}`));
