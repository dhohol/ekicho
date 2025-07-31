const admin = require('firebase-admin');
const path = require('path');

// Path to your service account key JSON (adjust if needed)
const serviceAccount = require(path.join(__dirname, 'serviceAccountKey.json'));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function updateAllStations() {
  const stationsRef = db.collection('stations');
  const snapshot = await stationsRef.get();

  let batch = db.batch();
  let count = 0;
  let batchCount = 0;

  for (const doc of snapshot.docs) {
    const ref = stationsRef.doc(doc.id);
    batch.update(ref, { lat: null, lng: null });
    count++;
    batchCount++;
    // Firestore batch limit is 500
    if (batchCount === 500) {
      await batch.commit();
      batch = db.batch();
      batchCount = 0;
      console.log(`Committed 500 updates...`);
    }
  }

  // Commit any remaining updates
  if (batchCount > 0) {
    await batch.commit();
    console.log(`Committed final ${batchCount} updates...`);
  }

  console.log(`Updated ${count} stations to have lat/lng = null`);
}

updateAllStations()
  .then(() => {
    console.log('Done!');
    process.exit(0);
  })
  .catch(err => {
    console.error('Error updating stations:', err);
    process.exit(1);
  }); 