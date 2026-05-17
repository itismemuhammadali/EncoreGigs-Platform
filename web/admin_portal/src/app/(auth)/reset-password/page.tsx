"use client";

import React, { useState, useEffect } from "react";
import Image from "next/image";
import Link from "next/link";
import { Lock, Eye, EyeOff, MoveLeft, Loader2, Check, Circle } from "lucide-react";

export default function ResetPasswordPage() {
  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [showNewPassword, setShowNewPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [isSuccess, setIsSuccess] = useState(false);

  const requirements = [
    { id: 1, label: "At least 8 characters", met: newPassword.length >= 8 },
    { id: 2, label: "Contains uppercase letter", met: /[A-Z]/.test(newPassword) },
    { id: 3, label: "Contains lowercase letter", met: /[a-z]/.test(newPassword) },
    { id: 4, label: "Contains number", met: /[0-9]/.test(newPassword) },
  ];

  const canSubmit = requirements.every(req => req.met) && newPassword === confirmPassword && confirmPassword !== "";

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!canSubmit) return;
    
    setIsLoading(true);
    // Simulate password reset
    setTimeout(() => {
      setIsLoading(false);
      setIsSuccess(true);
    }, 1500);
  };

  return (
    <main className="min-h-screen bg-[#0A0A0F] flex flex-col items-center justify-center p-6 antialiased">
      {/* Back to Sign In */}
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
      <div className="flex flex-col items-center mb-8 text-center">
        <div className="relative w-[110px] h-[70px] mb-6 transition-transform duration-500 hover:scale-105">
          <Image
            src="/logo.png"
            alt="OnlyGigz Logo"
            fill
            sizes="110px"
            className="object-contain"
            priority
          />
        </div>

        <h1 className="text-heading leading-heading font-bold text-white mb-2 text-[28px]">
          Set New Password
        </h1>
        <p className="text-[15px] font-normal text-[#a1a1aa]">
          Create a strong password for your account
        </p>
      </div>

      {/* Card */}
      <div className="w-[520px] bg-[#18181b] border border-[#27272a] border-[1.09px] rounded-[8px] p-[40px] shadow-[0_20px_50px_rgba(0,0,0,0.5)] relative overflow-hidden group">
        {!isSuccess ? (
          <form onSubmit={handleSubmit} className="flex flex-col relative z-10">
            {/* New Password */}
            <div className="space-y-3 mb-6">
              <label className="text-[14px] font-medium text-white block px-1">
                New Password
              </label>
              <div className="relative">
                <Lock className="absolute left-4 top-1/2 -translate-y-1/2 w-[18px] h-[18px] text-[#a1a1aa] stroke-[1.5px]" />
                <input
                  required
                  type={showNewPassword ? "text" : "password"}
                  value={newPassword}
                  onChange={(e) => setNewPassword(e.target.value)}
                  placeholder="••••••••"
                  className="w-full h-[56px] bg-[#1a1a1e] border border-[#27272a] rounded-[8px] pl-12 pr-12 text-[16px] font-normal text-white focus:outline-none focus:border-primary-accent/40 focus:ring-4 focus:ring-primary-accent/5 transition-all placeholder:text-[#a1a1aa]/60"
                />
                <button
                  type="button"
                  onClick={() => setShowNewPassword(!showNewPassword)}
                  className="absolute right-4 top-1/2 -translate-y-1/2 text-[#a1a1aa] hover:text-white transition-colors"
                >
                  {showNewPassword ? <EyeOff className="w-[18px] h-[18px] stroke-[1.5px]" /> : <Eye className="w-[18px] h-[18px] stroke-[1.5px]" />}
                </button>
              </div>
            </div>

            {/* Confirm Password */}
            <div className="space-y-3 mb-8">
              <label className="text-[14px] font-medium text-white block px-1">
                Confirm Password
              </label>
              <div className="relative">
                <Lock className="absolute left-4 top-1/2 -translate-y-1/2 w-[18px] h-[18px] text-[#a1a1aa] stroke-[1.5px]" />
                <input
                  required
                  type={showConfirmPassword ? "text" : "password"}
                  value={confirmPassword}
                  onChange={(e) => setConfirmPassword(e.target.value)}
                  placeholder="••••••••"
                  className="w-full h-[56px] bg-[#1a1a1e] border border-[#27272a] rounded-[8px] pl-12 pr-12 text-[16px] font-normal text-white focus:outline-none focus:border-primary-accent/40 focus:ring-4 focus:ring-primary-accent/5 transition-all placeholder:text-[#a1a1aa]/60"
                />
                <button
                  type="button"
                  onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                  className="absolute right-4 top-1/2 -translate-y-1/2 text-[#a1a1aa] hover:text-white transition-colors"
                >
                  {showConfirmPassword ? <EyeOff className="w-[18px] h-[18px] stroke-[1.5px]" /> : <Eye className="w-[18px] h-[18px] stroke-[1.5px]" />}
                </button>
              </div>
            </div>

            {/* Password Requirements */}
            <div className="bg-transparent border border-white/5 rounded-[8px] p-[20px] flex flex-col gap-4 mb-8">
              <h3 className="text-[14px] font-medium text-white">Password Requirements:</h3>
              <ul className="flex flex-col gap-3">
                {requirements.map((req) => (
                  <li key={req.id} className="flex items-center gap-3 text-[13px]">
                    <div className={`w-[16px] h-[16px] rounded-full border transition-all flex items-center justify-center ${
                      req.met 
                        ? "bg-primary-accent border-primary-accent" 
                        : "border-[#3f3f46] bg-transparent"
                    }`}>
                      {req.met && <Check className="w-[10px] h-[10px] text-black stroke-[3px]" />}
                    </div>
                    <span className={`transition-colors ${req.met ? "text-white" : "text-[#a1a1aa]"}`}>
                      {req.label}
                    </span>
                  </li>
                ))}
              </ul>
            </div>

            {/* Action Button */}
            <button
              disabled={isLoading || !canSubmit}
              className="w-full h-[56px] bg-primary-accent text-black text-[16px] font-bold rounded-[8px] hover:brightness-105 active:scale-[0.99] transition-all duration-200 flex items-center justify-center gap-2 shadow-[0_4px_20px_-4px_rgba(179,255,0,0.4)] disabled:opacity-50 disabled:cursor-not-allowed group/btn"
            >
              {isLoading ? (
                <Loader2 className="w-5 h-5 animate-spin" />
              ) : (
                "Reset Password"
              )}
            </button>
          </form>
        ) : (
          <div className="flex flex-col gap-[24px] relative z-10 text-center py-4">
             <div className="flex justify-center">
              <div className="w-[64px] h-[64px] rounded-full bg-primary-accent/10 flex items-center justify-center border border-primary-accent/20">
                <Check className="w-[32px] h-[32px] text-primary-accent" />
              </div>
            </div>
            
            <div className="flex flex-col gap-[8px]">
              <h2 className="text-[24px] font-bold text-white">Password Updated!</h2>
              <p className="text-[15px] font-normal text-[#a1a1aa]">
                Your password has been successfully reset. You can now sign in with your new password.
              </p>
            </div>

            <Link
              href="/"
              className="w-full h-[56px] bg-primary-accent text-black text-[16px] font-bold rounded-[8px] flex items-center justify-center hover:brightness-105 transition-all"
            >
              Back to sign in
            </Link>
          </div>
        )}
      </div>

      {/* Footer */}
      <footer className="mt-8 text-center">
        <p className="text-[#a1a1aa]/40 text-[12px] font-medium tracking-wide capital">
          © 2026 OnlyGigz. All rights reserved.
        </p>
      </footer>
    </main>
  );
}
