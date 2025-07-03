const admin = require('firebase-admin');
const fs = require('fs');
const serviceAccount = require('./serviceAccountKey.json');
const path = require('path');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function exportStations() {
  try {
    const stationsSnap = await db.collection('stations').get();
    const stations = [];
    stationsSnap.forEach(doc => {
      stations.push({ id: doc.id, ...doc.data() });
    });
    const outputPath = path.join(__dirname, 'stations_export.json');
    fs.writeFileSync(outputPath, JSON.stringify(stations, null, 2));
    console.log(`✅ Exported ${stations.length} stations to ${outputPath}`);
  } catch (error) {
    console.error('❌ Error exporting stations:', error);
  }
}

exportStations(); 