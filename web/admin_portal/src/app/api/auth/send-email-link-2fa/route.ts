import { NextRequest, NextResponse } from "next/server";
import { getAuth } from "firebase-admin/auth";
import { initializeApp, cert, getApps } from "firebase-admin/app";
import fetch from "node-fetch";

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

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { email, uid } = body;

    if (!email || !uid) {
      return NextResponse.json(
        { error: "Email and UID are required" },
        { status: 400 }
      );
    }

    // Generate email sign-in link using Firebase REST API
    const apiKey = process.env.FIREBASE_API_KEY;
    const response = await fetch(
      `https://identitytoolkit.googleapis.com/v1/accounts:sendSignInLink?key=${apiKey}`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          email: email,
          actionCodeSettings: {
            url: `${process.env.NEXT_PUBLIC_APP_URL || "http://localhost:3000"}/verify-2fa-link`,
            handleCodeInApp: true,
          },
        }),
      }
    );

    if (!response.ok) {
      const errorData = (await response.json()) as any;
      throw new Error(errorData.error?.message || "Failed to send email link");
    }

    return NextResponse.json({
      success: true,
      message: "Email verification link sent successfully",
    });
  } catch (error: any) {
    console.error("Error sending email link 2FA:", error);
    return NextResponse.json(
      { error: error.message || "Failed to send email link" },
      { status: 500 }
    );
  }
}
