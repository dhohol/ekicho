const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function findOrphanStations() {
  // 1. Get all stations (id and name)
  const stationsSnap = await db.collection('stations').get();
  const allStations = {};
  stationsSnap.forEach(doc => {
    const data = doc.data();
    allStations[doc.id] = data.name || '(no name)';
  });

  // 2. Get all lines and collect all referenced station_ids
  const linesSnap = await db.collection('lines').get();
  const referencedStationIds = new Set();
  linesSnap.forEach(doc => {
    const data = doc.data();
    if (Array.isArray(data.station_ids)) {
      data.station_ids.forEach(id => referencedStationIds.add(id));
    }
  });

  // 3. Find orphan stations
  const orphanStations = [];
  Object.keys(allStations).forEach(stationId => {
    if (!referencedStationIds.has(stationId)) {
      orphanStations.push({ id: stationId, name: allStations[stationId] });
    }
  });

  // 4. Output results
  if (orphanStations.length === 0) {
    console.log('🎉 No orphan stations found! All stations are referenced by at least one line.');
  } else {
    console.log(`🚨 Found ${orphanStations.length} orphan stations:`);
    orphanStations.forEach(station => console.log(`${station.id}: ${station.name}`));
  }
}

findOrphanStations().then(() => process.exit()); 