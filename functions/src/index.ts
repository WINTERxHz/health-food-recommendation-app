import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

admin.initializeApp();

const ADMIN_SECRET = "my-super-secret-2025"; // ← เปลี่ยนเป็นค่าของคุณเอง

export const makeMeAdmin = onCall(async (request) => {
  // 1. ต้อง login ก่อน
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "You must be logged in.");
  }

  // 2. ต้องมี secret ถูกต้อง
  const secret = request.data?.secret;
  if (secret !== ADMIN_SECRET) {
    throw new HttpsError("permission-denied", "Invalid secret key.");
  }

  const uid = request.auth.uid;
  await admin.auth().setCustomUserClaims(uid, {admin: true});

  return {message: `User ${uid} is now admin!`};
});