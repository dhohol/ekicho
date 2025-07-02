const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function fixKokubunjiLine() {
  console.log('🔄 Fixing tokyo_kokubunji_line document...');
  
  try {
    const lineRef = db.collection('lines').doc('tokyo_kokubunji_line');
    const lineDoc = await lineRef.get();
    
    if (!lineDoc.exists) {
      console.log('❌ Line document tokyo_kokubunji_line does not exist');
      return;
    }
    
    const lineData = lineDoc.data();
    console.log('Current line data:', lineData);
    
    // Check if name field is missing
    if (!lineData.name) {
      console.log('⚠️ Name field is missing, adding it...');
      
      // Add the missing name field
      await lineRef.update({
        name: 'Kokubunji Line'
      });
      
      console.log('✅ Added name field to tokyo_kokubunji_line');
    } else {
      console.log('ℹ️ Name field already exists:', lineData.name);
    }
    
    // Let's also check what other required fields might be missing
    const requiredFields = [
      'line_id', 'name', 'company', 'city_id', 'line_symbol', 
      'color_name', 'color_hex', 'shape', 'icon_asset_name', 
      'station_ids', 'is_active'
    ];
    
    console.log('\n📋 Checking for missing required fields:');
    for (const field of requiredFields) {
      if (!(field in lineData)) {
        console.log(`❌ Missing field: ${field}`);
      } else {
        console.log(`✅ Field exists: ${field} = ${lineData[field]}`);
      }
    }
    
  } catch (error) {
    console.error('❌ Error fixing tokyo_kokubunji_line:', error);
  }
  
  process.exit(0);
}

// Run the fix
fixKokubunjiLine().catch(error => {
  console.error('❌ Script failed:', error);
  process.exit(1);
}); 