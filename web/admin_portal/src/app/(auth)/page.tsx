"use client";

import React, { useState } from "react";
import Image from "next/image";
import Link from "next/link";
import { Mail, Lock, Eye, EyeOff, Loader2, Check } from "lucide-react";
import { useRouter } from "next/navigation";
import { apiRequest } from "@/lib/api";

export default function LoginPage() {
  const [showPassword, setShowPassword] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const router = useRouter();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setError(null);
    
    try {
      const data = await apiRequest("/auth/signin", {
        method: "POST",
        body: JSON.stringify({ email, password }),
      });

      if (data.role !== "admin") {
        throw new Error("Unauthorized: Only admins can access this portal.");
      }

      // Store token/user info in localStorage or cookie
      localStorage.setItem("admin_token", data.idToken);
      localStorage.setItem("admin_user", JSON.stringify(data));
      
      router.push("/dashboard");
    } catch (err: any) {
      setError(err.message || "Failed to sign in. Please check your credentials.");
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <main className="min-h-screen bg-[#0A0A0F] flex flex-col items-center justify-center p-6 antialiased" suppressHydrationWarning>
      {/* Logo & Title Section */}
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
          OnlyGigz Admin
        </h1>
        <p className="text-body leading-body font-normal text-[#a1a1aa] mb-2">
          Sign in to access the dashboard
        </p>
      </div>

      {/* Login Card */}
      <div className="w-full max-w-[448px] bg-[#18181b] border border-[#27272a] rounded-[16px] p-6 sm:p-10 shadow-2xl relative overflow-hidden group">
        {error && (
          <div className="mb-6 p-4 bg-red-500/10 border border-red-500/20 rounded-lg text-red-500 text-sm text-center">
            {error}
          </div>
        )}
        <form onSubmit={handleSubmit} className="space-y-8 relative z-10">
          {/* Email Field */}
          <div className="space-y-2.5">
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
                className="w-full h-[56px] bg-[#1a1a1e] border border-[#27272a] rounded-[10px] pl-12 pr-4 text-body leading-none font-normal text-white focus:outline-none focus:border-primary-accent/40 focus:ring-4 focus:ring-primary-accent/5 transition-all placeholder:text-[#a1a1aa]/30"
              />
            </div>
          </div>

          {/* Password Field */}
          <div className="space-y-2.5">
            <label className="text-label leading-label font-medium text-[#a1a1aa] block px-1">
              Password
            </label>
            <div className="relative">
              <Lock className="absolute left-4 top-1/2 -translate-y-1/2 w-[18px] h-[18px] text-[#a1a1aa] transition-colors group-focus-within:text-primary-accent" />
              <input
                required
                type={showPassword ? "text" : "password"}
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••"
                className="w-full h-[56px] bg-[#1a1a1e] border border-[#27272a] rounded-[10px] pl-12 pr-12 text-body leading-none font-normal text-white focus:outline-none focus:border-primary-accent/40 focus:ring-4 focus:ring-primary-accent/5 transition-all placeholder:text-[#a1a1aa]/30"
              />
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                className="absolute right-4 top-1/2 -translate-y-1/2 text-[#a1a1aa] hover:text-white transition-colors p-1"
              >
                {showPassword ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
              </button>
            </div>
          </div>

          {/* Remember & Forgot */}
          <div className="flex items-center justify-between gap-4 flex-wrap">
            <label className="flex items-center gap-2.5 cursor-pointer group/check">
              <div className="relative flex items-center justify-center w-[20px] h-[20px]">
                <input
                  type="checkbox"
                  className="peer appearance-none w-full h-full border border-[#27272a] rounded-[4px] checked:bg-primary-accent checked:border-primary-accent transition-all cursor-pointer bg-[#0e0e11]"
                />
                <Check className="absolute w-3.5 h-3.5 text-black opacity-0 peer-checked:opacity-100 pointer-events-none transition-opacity stroke-[4px]" />
              </div>
              <span className="text-[14px] font-medium text-[#a1a1aa] group-hover/check:text-white transition-colors">Remember me</span>
            </label>
            <Link
              href="/forgot-password"
              className="text-primary-accent font-medium hover:brightness-110 transition-all text-[14px]"
            >
              Forgot password?
            </Link>

          </div>

          {/* Sign In Button */}
          <button
            disabled={isLoading}
            className="w-full h-[56px] bg-primary-accent text-black text-body leading-body font-semibold rounded-[10px] hover:brightness-105 active:scale-[0.99] transition-all duration-200 flex items-center justify-center gap-2 shadow-[0_4px_12px_-4px_rgba(179,255,0,0.3)] disabled:opacity-70 disabled:cursor-not-allowed group/btn"
          >
            {isLoading ? (
              <Loader2 className="w-5 h-5 animate-spin" />
            ) : (
              "Sign In"
            )}
          </button>

          {/* Sign Up Link */}
          <p className="text-center text-[#a1a1aa] text-[14px]">
            Don't have an account?{" "}
            <Link href="/signup" className="text-primary-accent font-medium hover:underline">
              Sign Up
            </Link>
          </p>
        </form>
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


function ZapIcon() {
  return (
    <svg viewBox="0 0 24 24" fill="currentColor" className="w-4 h-4">
      <path d="M13 2L3 14h9l-1 8 10-12h-9l1-8z" />
    </svg>
  );
}
