const admin = require("firebase-admin");

const serviceAccount = require("./healthy-food-app-12d5f-firebase-adminsdk-fbsvc-db8bf5094c.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

async function makeAdmin() {
  const uid = "o3MOym89t6G9zkzOAnOP"; 

  await admin.auth().setCustomUserClaims(uid, { admin: true });

  console.log("✅ User is now admin!");
  process.exit();
}

makeAdmin();