import { cert, getApps, initializeApp } from "firebase-admin/app";
import fs from "fs";
import path from "path";

let firebaseApp;

export function getFirebaseApp() {
  if (firebaseApp) return firebaseApp;

  const inlineServiceAccount = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (inlineServiceAccount) {
    firebaseApp =
      getApps()[0] ??
      initializeApp({
        credential: cert(JSON.parse(inlineServiceAccount)),
      });
    return firebaseApp;
  }

  const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;
  if (serviceAccountPath) {
    const absolutePath = path.resolve(serviceAccountPath);
    if (!fs.existsSync(absolutePath)) return null;
    const serviceAccount = JSON.parse(fs.readFileSync(absolutePath, "utf8"));
    firebaseApp =
      getApps()[0] ??
      initializeApp({
        credential: cert(serviceAccount),
      });
    return firebaseApp;
  }

  const projectId = process.env.FIREBASE_PROJECT_ID;
  const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
  const privateKey = process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, "\n");

  if (!projectId || !clientEmail || !privateKey) return null;

  firebaseApp =
    getApps()[0] ??
    initializeApp({
      credential: cert({
        projectId,
        clientEmail,
        privateKey,
      }),
    });
  return firebaseApp;
}
