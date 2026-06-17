"use client";

import React, { useState } from "react";
import Image from "next/image";
import Link from "next/link";
import { Mail, MoveLeft, Loader2 } from "lucide-react";
import { apiRequest } from "@/lib/api";

export default function ForgotPasswordPage() {
  const [email, setEmail] = useState("");
  const [isSubmitted, setIsSubmitted] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setError(null);
    
    try {
      await apiRequest("/auth/forgot-password", {
        method: "POST",
        body: JSON.stringify({ email }),
      });
      setIsSubmitted(true);
    } catch (err: any) {
      setError(err.message || "Failed to send reset link. Please try again.");
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <main className="min-h-screen bg-[#0A0A0F] flex flex-col items-center justify-center p-6 antialiased" suppressHydrationWarning>
      {/* Back to Sign In (Shown in both states) */}
      {/* Back to Sign In (Shown in both states) */}
      <div className="w-[520px] mb-8">
        <Link
          href="/"
          className="inline-flex items-center gap-2 text-[#a1a1aa] hover:text-white transition-colors text-sm font-medium group"
        >
          <MoveLeft className="w-4 h-4 transition-transform group-hover:-translate-x-1" />
          Back to Sign In
        </Link>
      </div>

      {/* Logo Section */}
      <div className="flex flex-col items-center mb-12 text-center">
        <div className="relative mb-8 transition-transform duration-500 hover:scale-105">
          <Image
            src="/logo.png"
            alt="OnlyGigz Logo"
            width={124}
            height={78}
            className="object-contain"
            priority
          />
        </div>

        {!isSubmitted ? (
          <>
            <h1 className="text-heading leading-heading font-bold text-white mb-3">
              Forgot Password?
            </h1>
            <p className="text-body leading-body font-normal text-[#a1a1aa]">
              No worries, we&apos;ll send you reset instructions
            </p>
          </>
        ) : (
          <>
            <h1 className="text-heading leading-heading font-bold text-white mb-3 text-[32px]">
              Check Your Email
            </h1>
            <p className="text-body leading-body font-normal text-[#a1a1aa]">
              We&apos;ve sent a password reset link to
              <br />
              <span className="text-primary-accent font-medium mt-1 inline-block">{email}</span>
            </p>
          </>
        )}
      </div>

      {/* Card */}
      <div className="w-[520px] bg-[#18181b] border border-[#27272a] border-[1.09px] rounded-[8px] p-[32px] shadow-2xl relative overflow-hidden group">
        {error && (
          <div className="mb-6 p-4 bg-red-500/10 border border-red-500/20 rounded-lg text-red-500 text-sm text-center">
            {error}
          </div>
        )}
        {!isSubmitted ? (
          <form onSubmit={handleSubmit} className="flex flex-col gap-[24px] relative z-10">
            {/* Email Field */}
            <div className="space-y-3">
              <label className="text-label leading-label font-medium text-[#a1a1aa] block px-1">
                Email Address
              </label>
              <div className="relative">
                <Mail className="absolute left-4 top-1/2 -translate-y-1/2 w-[18px] h-[18px] text-[#a1a1aa] transition-colors group-focus-within:text-primary-accent" />
                <input
                  required
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="admin@gighub.com"
                  className="w-full h-[50px] bg-[#1a1a1e] border border-[#27272a] rounded-[8px] pl-12 pr-4 text-body leading-none font-normal text-white focus:outline-none focus:border-primary-accent/40 focus:ring-4 focus:ring-primary-accent/5 transition-all placeholder:text-[#a1a1aa]/30"
                />
              </div>
              <p className="text-[13px] font-normal text-[#a1a1aa]/60 px-1 leading-relaxed">
                Enter the email address associated with your account
              </p>
            </div>

            {/* Action Button */}
            <button
              disabled={isLoading}
              className="w-full h-[50px] bg-primary-accent text-black text-body leading-body font-semibold rounded-[8px] hover:brightness-105 active:scale-[0.99] transition-all duration-200 flex items-center justify-center gap-2 shadow-[0_4px_12px_-4px_rgba(179,255,0,0.3)] disabled:opacity-70 disabled:cursor-not-allowed group/btn"
            >
              {isLoading ? (
                <Loader2 className="w-5 h-5 animate-spin" />
              ) : (
                "Send Reset Link"
              )}
            </button>
          </form>
        ) : (
          <div className="flex flex-col gap-[24px] relative z-10 text-center">
            {/* Mail Icon Circle */}
            <div className="flex justify-center">
              <div className="w-[48px] h-[48px] rounded-full bg-[#1e1e21] flex items-center justify-center border border-white/5">
                <Mail className="w-[20px] h-[20px] text-primary-accent" />
              </div>
            </div>

            {/* Content */}
            <div className="flex flex-col gap-[8px]">
              <p className="text-[14px] leading-[22px] font-normal text-[#a1a1aa] max-w-[360px] mx-auto">
                Click the link in the email to reset your password. The link will expire in 24 hours.
              </p>
              <p className="text-[12px] font-normal text-[#a1a1aa]/50">
                Didn&apos;t receive the email? Check your spam folder.
              </p>
            </div>

            {/* Buttons */}
            <div className="flex flex-col gap-[12px]">
              <button
                type="button"
                className="w-full h-[50px] bg-transparent border border-[#27272a] text-white text-[15px] font-semibold rounded-[8px] hover:bg-white/5 transition-all"
              >
                Resend Email
              </button>
              <Link
                href="/"
                className="w-full h-[50px] bg-primary-accent text-black text-[15px] font-semibold rounded-[8px] flex items-center justify-center hover:brightness-105 transition-all shadow-[0_4px_12px_-4px_rgba(179,255,0,0.3)]"
              >
                Back to sign in
              </Link>
            </div>

            {/* Note */}
            <p className="text-[12px] font-medium text-[#a1a1aa]/40 pt-2">
              Set new Password (This button just given to complete design flow)
            </p>
          </div>
        )}
      </div>

      {/* Footer */}
      <footer className="mt-16 text-center">
        <p className="text-[#a1a1aa]/40 text-[12px] font-medium tracking-wide capital">
          © 2026 OnlyGigz. All rights reserved.
        </p>
      </footer>
    </main>
  );
}

