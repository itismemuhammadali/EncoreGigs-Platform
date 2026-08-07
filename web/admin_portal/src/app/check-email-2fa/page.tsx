"use client";

import React, { useEffect, useState } from "react";
import Image from "next/image";
import { Loader2, Mail, RotateCcw } from "lucide-react";
import { useRouter } from "next/navigation";
import { apiRequest } from "@/lib/api";

export default function CheckEmail2FAPage() {
  const [email, setEmail] = useState<string>("");
  const [uid, setUid] = useState<string>("");
  const [cooldownSeconds, setCooldownSeconds] = useState(60);
  const [isResending, setIsResending] = useState(false);
  const router = useRouter();

  useEffect(() => {
    // Get email from localStorage (set during login)
    const userStr = localStorage.getItem("admin_user");
    const pendingStr = localStorage.getItem("admin_pending_2fa");
    const emailForSignIn = localStorage.getItem("emailForSignIn");

    if (pendingStr) {
      try {
        const pendingData = JSON.parse(pendingStr);
        setEmail(pendingData.email || emailForSignIn || "");
        setUid(pendingData.localId || "");
      } catch (e) {
        if (emailForSignIn) setEmail(emailForSignIn);
        else router.push("/");
      }
    } else if (userStr) {
      try {
        const userData = JSON.parse(userStr);
        setEmail(userData.email || "");
        setUid(userData.localId || "");
      } catch (e) {
        router.push("/");
      }
    } else if (emailForSignIn) {
      setEmail(emailForSignIn);
    } else {
      router.push("/");
    }
  }, [router]);

  useEffect(() => {
    // Cooldown timer
    let timer: NodeJS.Timeout;
    if (cooldownSeconds > 0) {
      timer = setTimeout(() => setCooldownSeconds(cooldownSeconds - 1), 1000);
    }
    return () => clearTimeout(timer);
  }, [cooldownSeconds]);

  const handleResend = async () => {
    if (cooldownSeconds > 0 || !email) return;

    setIsResending(true);
    try {
      const { sendSignInLinkToEmail } = await import("firebase/auth");
      const { auth } = await import("@/lib/firebase");
      const actionCodeSettings = {
        url: `${window.location.origin}/verify-2fa-link`,
        handleCodeInApp: true,
      };
      await sendSignInLinkToEmail(auth, email, actionCodeSettings);
      setCooldownSeconds(30);
    } catch (err: any) {
      console.warn("Client SDK resend warning, calling backend API:", err);
      try {
        await apiRequest("/auth/send-email-link-2fa", {
          method: "POST",
          body: JSON.stringify({
            email: email,
            uid: uid || "admin",
            userType: "admin",
            continueUrl: `${window.location.origin}/verify-2fa-link`,
          }),
        });
        setCooldownSeconds(30);
      } catch (fallbackErr: any) {
        console.error("Failed to resend email link:", fallbackErr);
      }
    } finally {
      setIsResending(false);
    }
  };

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
          Check Your Email
        </h1>
        <p className="text-body leading-body font-normal text-[#a1a1aa] mb-2">
          We sent a verification link to your email
        </p>
      </div>

      <div className="w-full max-w-[448px] bg-[#18181b] border border-[#27272a] rounded-[16px] p-6 sm:p-10 shadow-2xl">
        <div className="flex flex-col items-center space-y-6">
          {/* Email Icon */}
          <div className="w-16 h-16 rounded-full bg-[#A2F301]/10 border border-[#A2F301]/20 flex items-center justify-center">
            <Mail className="w-8 h-8 text-[#A2F301]" />
          </div>

          {/* Email Display */}
          <div className="w-full bg-[#1A1A1A] rounded-[12px] p-4 border border-[#2A2A2A] text-center">
            <p className="text-[#999999] text-[12px] uppercase tracking-wider mb-1">
              Verification sent to
            </p>
            <p className="text-white font-semibold text-[15px]">{email}</p>
          </div>

          {/* Instructions */}
          <div className="space-y-3 text-center">
            <p className="text-[#a1a1aa] text-[14px] leading-relaxed">
              Click the verification link in the email to complete your sign-in.
            </p>
            <p className="text-[#666666] text-[13px]">
              The link will expire in 24 hours.
            </p>
          </div>

          {/* Resend Button */}
          <button
            onClick={handleResend}
            disabled={cooldownSeconds > 0 || isResending}
            className={`w-full h-[54px] rounded-[8px] font-semibold flex items-center justify-center gap-2 transition-all ${
              cooldownSeconds > 0
                ? "bg-[#2A2A2A] text-[#666666] cursor-not-allowed"
                : "bg-[#A2F301] text-[#0A0A0F] hover:bg-[#8ed601] active:scale-[0.98]"
            }`}
          >
            {isResending ? (
              <Loader2 size={18} className="animate-spin" />
            ) : (
              <RotateCcw size={18} />
            )}
            {cooldownSeconds > 0
              ? `Resend in ${cooldownSeconds}s`
              : "Resend Email"}
          </button>

          {/* Back Button */}
          <button
            onClick={() => {
              localStorage.removeItem("admin_user");
              localStorage.removeItem("admin_token");
              router.push("/");
            }}
            className="w-full h-[48px] bg-transparent border border-[#2A2A2A] rounded-[8px] text-[#a1a1aa] hover:text-white hover:border-[#A2F301]/30 transition-all font-medium"
          >
            Back to Login
          </button>
        </div>
      </div>

      {/* Info Box */}
      <div className="w-full max-w-[448px] mt-6 bg-blue-500/10 border border-blue-500/20 rounded-[12px] p-4">
        <p className="text-blue-400 text-[13px] text-center">
          💡 Didn't receive the email? Check your spam folder or resend below.
        </p>
      </div>
    </main>
  );
}
