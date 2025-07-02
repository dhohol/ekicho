const admin = require("firebase-admin");
const fs = require("fs");
const path = require("path");

// Load service account key
const serviceAccountPath = path.resolve(__dirname, "serviceAccountKey.json");
const serviceAccount = require(serviceAccountPath);

// Initialize Firebase
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// Load Firestore data
const dataPath = path.resolve(__dirname, "firestore_lines_import.json");
const data = require(dataPath);

// Import function
const importLines = async () => {
  const lines = data.lines;

  if (!lines || Object.keys(lines).length === 0) {
    console.error("❌ No lines found in JSON. Check your file.");
    return;
  }

  console.log(`📦 Importing ${Object.keys(lines).length} lines...`);

  for (const [id, lineData] of Object.entries(lines)) {
    try {
      await db.collection("lines").doc(id).set(lineData);
      console.log(`✅ Imported line: ${id}`);
    } catch (err) {
      console.error(`❌ Failed to import line ${id}:`, err);
    }
  }

  console.log("🎉 All lines imported!");
};

// Run it
importLines();