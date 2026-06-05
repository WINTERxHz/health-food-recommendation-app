// import_foods.js
// ─────────────────────────────────────────────────────────
// วิธีใช้:
// 1. วางไฟล์นี้ไว้ในโฟลเดอร์เดียวกับ foods.json
// 2. npm install firebase-admin
// 3. node import_foods.js
//
// ✅ flow:
//    1) ลบ document ทั้งหมดใน collection "foods"
//    2) import foods.json ใหม่ทั้งหมด (ไม่มีซ้ำแน่นอน)
// ─────────────────────────────────────────────────────────

const admin = require("firebase-admin");
const serviceAccount = require("./healthy-food-app-12d5f-firebase-adminsdk-fbsvc-1e24281aab.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();
const foods = require("./foods.json");

const BATCH_SIZE = 400; // Firestore batch limit

// ── แปลงชื่อเมนูเป็น document ID ─────────────────────────
function toDocId(name) {
  return name.trim().replace(/\s+/g, "_").replace(/[\/\.]/g, "-");
}

// ── ใช้ isHealthy จาก foods.json โดยตรง ──────────────────
function getIsHealthy(food) {
  if (typeof food.isHealthy === "boolean") return food.isHealthy;
  if (food.category === "Vegetarian") return true;
  if (food.category === "Low Carb" && food.calories < 350) return true;
  if (food.category === "High Protein" && food.fat < 15) return true;
  if (food.category === "Balanced" && food.calories < 600) return true;
  return false;
}

// ── Step 1: ลบทุก document ใน collection ─────────────────
async function deleteCollection(collectionPath) {
  console.log("===========================================");
  console.log('  Step 1: ลบข้อมูลเก่าใน "' + collectionPath + '"');
  console.log("===========================================");

  const snap = await db.collection(collectionPath).get();

  if (snap.empty) {
    console.log("   (ไม่มีข้อมูลเก่า ข้ามขั้นตอนนี้)\n");
    return 0;
  }

  let deleted = 0;

  for (let i = 0; i < snap.docs.length; i += BATCH_SIZE) {
    const batch = db.batch();
    snap.docs.slice(i, i + BATCH_SIZE).forEach(function(doc) {
      batch.delete(doc.ref);
      deleted++;
    });
    await batch.commit();
    console.log(
      "   ลบแล้ว " +
      Math.min(i + BATCH_SIZE, snap.docs.length) +
      " / " + snap.docs.length + " รายการ"
    );
  }

  console.log("   ✅ ลบเสร็จ " + deleted + " รายการ\n");
  return deleted;
}

// ── Step 2: import ใหม่ทั้งหมด ───────────────────────────
async function importFoods() {
  console.log("===========================================");
  console.log("  Step 2: Import " + foods.length + " รายการใหม่");
  console.log("===========================================");

  let imported = 0;

  for (let i = 0; i < foods.length; i += BATCH_SIZE) {
    const chunk = foods.slice(i, i + BATCH_SIZE);
    const batch = db.batch();

    for (const food of chunk) {
      const docId = toDocId(food.name);
      const ref = db.collection("foods").doc(docId);

      batch.set(ref, {
        name:       food.name,
        calories:   food.calories,
        protein:    food.protein,
        fat:        food.fat,
        carbs:      food.carbs,
        category:   food.category,
        isHealthy:  getIsHealthy(food),
        imageUrl:   food.imageUrl   || null,
        source:     food.source     || null,
        source_url: food.source_url || null,
        createdAt:  admin.firestore.FieldValue.serverTimestamp(),
      });

      imported++;
    }

    await batch.commit();
    console.log(
      "   ✅ batch " + (Math.floor(i / BATCH_SIZE) + 1) +
      ": " + chunk.length + " รายการ"
    );
  }

  console.log("   ✅ import เสร็จ " + imported + " รายการ\n");
  return imported;
}

// ── Main ──────────────────────────────────────────────────
async function main() {
  console.log("\n  Foods Database Import Tool\n");

  const deleted  = await deleteCollection("foods");
  const imported = await importFoods();

  console.log("===========================================");
  console.log("  สรุปผล");
  console.log("===========================================");
  console.log("  ลบเก่า    : " + deleted  + " รายการ");
  console.log("  import ใหม่: " + imported + " รายการ");
  console.log("  เสร็จสมบูรณ์!");
  process.exit(0);
}

main().catch(function(err) {
  console.error("\nError:", err);
  process.exit(1);
});