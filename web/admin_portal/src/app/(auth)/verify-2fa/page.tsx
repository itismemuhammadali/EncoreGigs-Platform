"use client";

import React, { useEffect, useState, Suspense } from "react";
import Image from "next/image";
import { Loader2 } from "lucide-react";
import { useRouter, useSearchParams } from "next/navigation";
import { getAuth, isSignInWithEmailLink, signInWithEmailLink } from "firebase/auth";
import { app } from "@/lib/firebase";

function Verify2FAContent() {
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [verificationComplete, setVerificationComplete] = useState(false);
  const router = useRouter();
  const searchParams = useSearchParams();

  useEffect(() => {
    const handleEmailLinkVerification = async () => {
      try {
        const auth = getAuth(app);

        // Check if this is a sign-in with email link
        if (!isSignInWithEmailLink(auth, window.location.href)) {
          setError("Invalid or expired verification link.");
          setIsLoading(false);
          return;
        }

        // Get the email from localStorage (should be set before they clicked the link)
        let email = window.localStorage.getItem("emailForSignIn");
        if (!email) {
          setError("Email not found. Please try signing in again.");
          setIsLoading(false);
          return;
        }

        // Complete the sign-in process with the email link
        const result = await signInWithEmailLink(auth, email, window.location.href);
        const user = result.user;

        // Get the ID token
        const idToken = await user.getIdToken();

        // Clear the email from localStorage
        window.localStorage.removeItem("emailForSignIn");

        // Fetch admin user data from backend (if available)
        try {
          const response = await fetch("/api/auth/admin-profile", {
            headers: {
              Authorization: `Bearer ${idToken}`,
            },
          });

          if (response.ok) {
            const userData = await response.json();
            // Store tokens and user data
            localStorage.setItem("admin_token", idToken);
            localStorage.setItem("admin_user", JSON.stringify({
              ...userData,
              idToken,
              localId: user.uid,
              email: user.email,
            }));
          }
        } catch (err) {
          // If backend fetch fails, still sign in with basic data
          localStorage.setItem("admin_token", idToken);
          localStorage.setItem("admin_user", JSON.stringify({
            idToken,
            localId: user.uid,
            email: user.email,
          }));
        }

        // Clear any pending 2FA data
        localStorage.removeItem("admin_pending_2fa");

        setVerificationComplete(true);
        setIsLoading(false);

        // Redirect to dashboard after a short delay
        setTimeout(() => {
          router.push("/dashboard");
        }, 1500);
      } catch (err: any) {
        console.error("Email link verification error:", err);
        setError(err.message || "Failed to verify email link. Please try signing in again.");
        setIsLoading(false);
      }
    };

    handleEmailLinkVerification();
  }, [router]);

  return (
    <main className="min-h-screen bg-[#0A0A0F] flex flex-col items-center justify-center p-6 antialiased" suppressHydrationWarning>
      <div className="flex flex-col items-center mb-12 text-center">
        <div className="relative mb-8 group transition-transform duration-500 hover:scale-105">
          <Image
            src="/logo.png"
            alt="OnlyGigz Logo"
            width={124}
            height={78}
            className="object-contain"
            priority
          />
        </div>
        <h1 className="text-heading leading-heading font-bold text-white mb-2">
          {isLoading ? "Verifying Email" : verificationComplete ? "Verification Complete" : "Verification Failed"}
        </h1>
        <p className="text-body leading-body font-normal text-[#a1a1aa] mb-2">
          {isLoading ? "Please wait while we verify your email link..." : error ? "There was an issue" : "You're all set!"}
        </p>
      </div>

      <div className="w-full max-w-[448px] bg-[#18181b] border border-[#27272a] rounded-[16px] p-6 sm:p-10 shadow-2xl relative overflow-hidden">
        <div className="flex flex-col items-center justify-center py-12 space-y-4">
          {isLoading && (
            <>
              <Loader2 className="w-12 h-12 text-[#A2F301] animate-spin" />
              <p className="text-[#a1a1aa] text-center">Verifying your email link...</p>
            </>
          )}

          {error && (
            <>
              <div className="w-12 h-12 rounded-full bg-red-500/10 border border-red-500/20 flex items-center justify-center">
                <span className="text-2xl">✗</span>
              </div>
              <div className="text-center space-y-3 mt-4">
                <p className="text-red-500 font-medium">{error}</p>
                <button
                  onClick={() => router.push("/")}
                  className="w-full h-[48px] bg-[#A2F301] hover:bg-[#8ed601] text-[#0A0A0F] font-semibold rounded-[10px] transition-all duration-300"
                >
                  Back to Login
                </button>
              </div>
            </>
          )}

          {verificationComplete && !isLoading && (
            <>
              <div className="w-12 h-12 rounded-full bg-green-500/10 border border-green-500/20 flex items-center justify-center">
                <span className="text-2xl">✓</span>
              </div>
              <p className="text-green-500 font-medium">Verification successful! Redirecting to dashboard...</p>
            </>
          )}
        </div>
      </div>
    </main>
  );
}

export default function Verify2FAPage() {
  return (
    <Suspense fallback={<div className="min-h-screen bg-[#0A0A0F] flex items-center justify-center text-white">Loading...</div>}>
      <Verify2FAContent />
    </Suspense>
  );
}
