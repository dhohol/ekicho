const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// Define the station to line mappings
const stationLineMappings = {
  "tokyo_akebonobashi": "tokyo_shinjuku_line",
  "tokyo_bakuro-yokoyama": "tokyo_shinjuku_line",
  "tokyo_funabori": "tokyo_shinjuku_line",
  "tokyo_hamacho": "tokyo_shinjuku_line",
  "tokyo_higashi-koganei": "tokyo_chuo_line",
  "tokyo_higashi-murayama": "tokyo_shinjuku_line",
  "tokyo_higashi-ojima": "tokyo_shinjuku_line",
  "tokyo_ichinoe": "tokyo_shinjuku_line",
  "tokyo_iwamotocho": "tokyo_shinjuku_line",
  "tokyo_kikukawa": "tokyo_shinjuku_line",
  "tokyo_mizue": "tokyo_shinjuku_line",
  "tokyo_musashi-sakai": "tokyo_chuo_line",
  "tokyo_nishi-ojima": "tokyo_shinjuku_line",
  "tokyo_ogawamachi": "tokyo_shinjuku_line",
  "tokyo_ojima": "tokyo_shinjuku_line",
  "tokyo_shinozaki": "tokyo_shinjuku_line",
  "tokyo_takanodai": "tokyo_kokubunji_line",
  "tokyo_urakuracho": "tokyo_shinjuku_line"
};

async function updateStationLineIds(stationId, lineId) {
  try {
    const stationRef = db.collection('stations').doc(stationId);
    const stationDoc = await stationRef.get();
    
    if (!stationDoc.exists) {
      console.log(`❌ Station document ${stationId} does not exist`);
      return false;
    }
    
    const stationData = stationDoc.data();
    const currentLineIds = stationData.line_ids || [];
    
    if (!currentLineIds.includes(lineId)) {
      currentLineIds.push(lineId);
      await stationRef.update({ line_ids: currentLineIds });
      console.log(`✅ Updated station ${stationId} with line_ids: [${currentLineIds.join(', ')}]`);
    } else {
      console.log(`ℹ️ Station ${stationId} already has line_id ${lineId}`);
    }
    
    return true;
  } catch (error) {
    console.log(`❌ Error updating station ${stationId}: ${error.message}`);
    return false;
  }
}

async function updateLineStationIds(lineId, stationId) {
  try {
    const lineRef = db.collection('lines').doc(lineId);
    const lineDoc = await lineRef.get();
    
    if (!lineDoc.exists) {
      console.log(`❌ Line document ${lineId} does not exist`);
      return false;
    }
    
    const lineData = lineDoc.data();
    const currentStationIds = lineData.station_ids || [];
    
    if (!currentStationIds.includes(stationId)) {
      currentStationIds.push(stationId);
      await lineRef.update({ station_ids: currentStationIds });
      console.log(`✅ Updated line ${lineId} with station_ids: [${currentStationIds.join(', ')}]`);
    } else {
      console.log(`ℹ️ Line ${lineId} already has station_id ${stationId}`);
    }
    
    return true;
  } catch (error) {
    console.log(`❌ Error updating line ${lineId}: ${error.message}`);
    return false;
  }
}

async function fixMissingLineIds() {
  console.log('🔄 Starting line_ids migration...');
  
  let successCount = 0;
  let errorCount = 0;
  
  for (const [stationId, lineId] of Object.entries(stationLineMappings)) {
    console.log(`\n--- Processing ${stationId} -> ${lineId} ---`);
    
    const stationSuccess = await updateStationLineIds(stationId, lineId);
    if (stationSuccess) {
      const lineSuccess = await updateLineStationIds(lineId, stationId);
      if (lineSuccess) {
        successCount++;
        console.log(`✅ Successfully updated ${stationId} -> ${lineId}`);
      } else {
        errorCount++;
        console.log(`❌ Failed to update line ${lineId} for station ${stationId}`);
      }
    } else {
      errorCount++;
      console.log(`❌ Failed to update station ${stationId} with line ${lineId}`);
    }
  }
  
  console.log(`\n🎉 Migration completed: ${successCount} successful, ${errorCount} failed`);
  
  if (errorCount === 0) {
    console.log('✅ All updates completed successfully!');
  } else {
    console.log(`⚠️ ${errorCount} updates failed. Please check the logs above.`);
  }
  
  process.exit(0);
}

// Run the migration
fixMissingLineIds().catch(error => {
  console.error('❌ Migration failed:', error);
  process.exit(1);
}); 