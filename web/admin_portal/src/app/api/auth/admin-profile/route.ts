import { NextRequest, NextResponse } from "next/server";
import { getAuth } from "firebase-admin/auth";
import { getFirestore } from "firebase-admin/firestore";
import { initializeApp, cert, getApps } from "firebase-admin/app";

import fs from "fs";
import path from "path";

export const dynamic = "force-dynamic";

function getFirebaseAdminApp() {
  if (getApps().length > 0) return getApps()[0];
  const projectId = process.env.FIREBASE_PROJECT_ID || "onlygigz-33557";
  const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
  const privateKey = process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, "\n");

  if (clientEmail && privateKey) {
    return initializeApp({ credential: cert({ projectId, clientEmail, privateKey }) });
  }

  // Fallback to local backend serviceAccountKey.json
  const keyPath = path.resolve(process.cwd(), "../../backend/serviceAccountKey.json");
  if (fs.existsSync(keyPath)) {
    try {
      const serviceAccount = JSON.parse(fs.readFileSync(keyPath, "utf8"));
      return initializeApp({ credential: cert(serviceAccount) });
    } catch (e) {
      console.warn("Failed to load serviceAccountKey.json:", e);
    }
  }

  return initializeApp({ projectId });
}

export async function GET(request: NextRequest) {
  try {
    // Get the Authorization header
    const authHeader = request.headers.get("Authorization");
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const token = authHeader.substring(7);
    const app = getFirebaseAdminApp();

    // Verify the token and get user
    const auth = getAuth(app);
    const decodedToken = await auth.verifyIdToken(token);
    const uid = decodedToken.uid;

    // Get admin data from Firestore
    const db = getFirestore(app);
    const adminDoc = await db.collection("admins").doc(uid).get();

    if (!adminDoc.exists) {
      return NextResponse.json({ error: "Admin profile not found" }, { status: 404 });
    }

    const adminData = adminDoc.data();

    return NextResponse.json({
      uid,
      email: decodedToken.email,
      firstName: adminData?.firstName || "",
      lastName: adminData?.lastName || "",
      role: "Admin",
      is2FAEnabled: adminData?.is2FAEnabled || false,
      twoFactorMethod: adminData?.twoFactorMethod || "email",
      phoneNumber: adminData?.phoneNumber || "",
      profileImageUrl: adminData?.profileImageUrl || "",
    });
  } catch (error: any) {
    console.error("Error fetching admin profile:", error);
    return NextResponse.json(
      { error: error.message || "Failed to fetch admin profile" },
      { status: 500 }
    );
  }
}
