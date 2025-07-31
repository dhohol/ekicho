const admin = require('firebase-admin');
const path = require('path');

// Path to your service account key JSON (adjust if needed)
const serviceAccount = require(path.join(__dirname, 'serviceAccountKey.json'));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// List of station names
const stationNames = [
  'Arakawa-kuyakushomae',
  'Arakawa-nanachome',
  'Machiya-ekimae',
  'Machiya-nichome',
  'Higashi-ogu-sanchome',
  'Kumanomae',
  'Miyanomae',
  'Odai',
  'Takinogawa-itchome',
  'Nishigahara-yonchome',
  'Shin-koshinzuka'
];

// Helper to create document_id and station_id
function toStationId(name) {
  return 'tokyo_' + name
    .toLowerCase()
    .replace(/[^a-z0-9\s-]/g, '') // remove special chars
    .replace(/\s+/g, '-')         // spaces to dash
    .replace(/_/g, '-')           // underscores to dash
}

async function addStationsAndUpdateLine() {
  const batch = db.batch();
  const newStationIds = [];

  for (const name of stationNames) {
    const stationId = toStationId(name);
    const docId = stationId;
    newStationIds.push(stationId);
    const stationRef = db.collection('stations').doc(docId);
    batch.set(stationRef, {
      station_id: stationId,
      name: name,
      city_id: 'tokyo',
      line_ids: ['tokyo_arakawa_line'],
      lat: null,
      lng: null,
      is_active: true
    }, { merge: true });
  }

  // Update the tokyo_arakawa_line's station_ids array
  const lineRef = db.collection('lines').doc('tokyo_arakawa_line');
  const lineDoc = await lineRef.get();
  let stationIds = [];
  if (lineDoc.exists && Array.isArray(lineDoc.data().station_ids)) {
    // Merge with existing, avoid duplicates
    const existing = lineDoc.data().station_ids;
    stationIds = Array.from(new Set([...existing, ...newStationIds]));
  } else {
    stationIds = newStationIds;
  }
  batch.update(lineRef, { station_ids: stationIds });

  await batch.commit();
  console.log(`Added/updated ${newStationIds.length} stations and updated tokyo_arakawa_line.`);
}

addStationsAndUpdateLine()
  .then(() => {
    console.log('Done!');
    process.exit(0);
  })
  .catch(err => {
    console.error('Error:', err);
    process.exit(1);
  }); 