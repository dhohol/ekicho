const admin = require('firebase-admin');
const path = require('path');

// Path to your service account key JSON (adjust if needed)
const serviceAccount = require(path.join(__dirname, 'serviceAccountKey.json'));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function checkCityField() {
  const stationsRef = db.collection('stations');
  const snapshot = await stationsRef.get();
  let count = 0;
  let ids = [];

  snapshot.forEach(doc => {
    const data = doc.data();
    if (data.city !== undefined && data.city_id === undefined) {
      count++;
      ids.push(doc.id);
    }
  });

  console.log(`Stations with 'city' (and not 'city_id'): ${count}`);
  if (ids.length > 0) {
    console.log('Affected station document IDs:', ids);
  }
}

checkCityField()
  .then(() => {
    console.log('Done!');
    process.exit(0);
  })
  .catch(err => {
    console.error('Error:', err);
    process.exit(1);
  }); 