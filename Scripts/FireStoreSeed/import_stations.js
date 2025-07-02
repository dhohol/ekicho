const fs = require('fs');
const path = require('path');

// Load lines.json
const linesPath = path.join(__dirname, '../lines.json');
const outputPath = path.join(__dirname, 'firestore_stations_import_pray.json');

const data = JSON.parse(fs.readFileSync(linesPath, 'utf8'));
const stations = data.stations;
const lines = data.lines;

// Build a map of station_id to line_ids
const stationLineMap = {};

lines.forEach(line => {
  // Use iconAssetName for line_ids
  const lineId = line.iconAssetName ? `tokyo_${line.iconAssetName}` : null;
  if (!lineId) return;
  // Some lines have stations as array of objects, some as array of ids
  let stationObjs = line.stations;
  if (!stationObjs || !Array.isArray(stationObjs)) return;
  // If stations are objects, get their id; if strings, use as is
  stationObjs.forEach(station => {
    const sid = typeof station === 'string' ? station : station.id;
    if (!sid) return;
    if (!stationLineMap[sid]) stationLineMap[sid] = [];
    stationLineMap[sid].push(lineId);
  });
});

// Build the output stations object
const outputStations = {};
stations.forEach(station => {
  const sid = station.id;
  outputStations[`tokyo_${sid}`] = {
    station_id: `tokyo_${sid}`,
    name: station.name,
    lat: "",
    lng: "",
    city_id: "tokyo",
    is_active: true,
    line_ids: stationLineMap[sid] || []
  };
});

// Write to output file
fs.writeFileSync(outputPath, JSON.stringify({ stations: outputStations }, null, 2));
console.log('firestore_stations_import_pray.json created!'); 