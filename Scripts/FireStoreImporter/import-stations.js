const admin = require("firebase-admin");
const serviceAccount = require("./serviceAccountKey.json");
const { stations } = require("./firestore_stations_import.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function importStations() {
  const batch = db.batch();
  const stationsCollection = db.collection("stations");

  Object.entries(stations).forEach(([stationId, stationData]) => {
    const stationRef = stationsCollection.doc(stationId);
    batch.set(stationRef, {
      name: stationData.name,
      station_id: stationData.station_id,
      city_id: stationData.city_id,
      line_ids: stationData.line_ids,
      lat: stationData.lat || null,
      lng: stationData.lng || null,
      is_active: stationData.is_active ?? true,
    });
  });

  try {
    await batch.commit();
    console.log(`✅ Successfully imported ${Object.keys(stations).length} stations.`);
  } catch (error) {
    console.error("❌ Error importing stations:", error);
  }
}

importStations();