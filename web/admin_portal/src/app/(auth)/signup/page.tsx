"use client";

import React, { useState } from "react";
import Image from "next/image";
import Link from "next/link";
import { Mail, Lock, User, Eye, EyeOff, Loader2 } from "lucide-react";
import { useRouter } from "next/navigation";
import { apiRequest } from "@/lib/api";

export default function SignupPage() {
  const [showPassword, setShowPassword] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [firstName, setFirstName] = useState("");
  const [lastName, setLastName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const router = useRouter();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setError(null);
    
    try {
      await apiRequest("/auth/signup/admin", {
        method: "POST",
        body: JSON.stringify({ firstName, lastName, email, password }),
      });

      // After successful signup, redirect to login
      router.push("/");
    } catch (err: any) {
      setError(err.message || "Failed to sign up. Please try again.");
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
          Create Admin Account
        </h1>
        <p className="text-body leading-body font-normal text-[#a1a1aa] mb-2">
          Sign up to access the admin dashboard
        </p>
      </div>

      {/* Signup Card */}
      <div className="w-full max-w-[448px] bg-[#18181b] border border-[#27272a] rounded-[16px] p-6 sm:p-10 shadow-2xl relative overflow-hidden group">
        {error && (
          <div className="mb-6 p-4 bg-red-500/10 border border-red-500/20 rounded-lg text-red-500 text-sm text-center">
            {error}
          </div>
        )}
        <form onSubmit={handleSubmit} className="space-y-6 relative z-10">
          {/* Name Fields */}
          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2.5">
              <label className="text-label leading-label font-medium text-[#a1a1aa] block px-1">
                First Name
              </label>
              <div className="relative">
                <User className="absolute left-4 top-1/2 -translate-y-1/2 w-[18px] h-[18px] text-[#a1a1aa] transition-colors group-focus-within:text-primary-accent" />
                <input
                  required
                  type="text"
                  value={firstName}
                  onChange={(e) => setFirstName(e.target.value)}
                  placeholder="John"
                  className="w-full h-[56px] bg-[#1a1a1e] border border-[#27272a] rounded-[10px] pl-12 pr-4 text-body leading-none font-normal text-white focus:outline-none focus:border-primary-accent/40 focus:ring-4 focus:ring-primary-accent/5 transition-all placeholder:text-[#a1a1aa]/30"
                />
              </div>
            </div>
            <div className="space-y-2.5">
              <label className="text-label leading-label font-medium text-[#a1a1aa] block px-1">
                Last Name
              </label>
              <div className="relative">
                <User className="absolute left-4 top-1/2 -translate-y-1/2 w-[18px] h-[18px] text-[#a1a1aa] transition-colors group-focus-within:text-primary-accent" />
                <input
                  required
                  type="text"
                  value={lastName}
                  onChange={(e) => setLastName(e.target.value)}
                  placeholder="Doe"
                  className="w-full h-[56px] bg-[#1a1a1e] border border-[#27272a] rounded-[10px] pl-12 pr-4 text-body leading-none font-normal text-white focus:outline-none focus:border-primary-accent/40 focus:ring-4 focus:ring-primary-accent/5 transition-all placeholder:text-[#a1a1aa]/30"
                />
              </div>
            </div>
          </div>

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

          {/* Sign Up Button */}
          <button
            disabled={isLoading}
            className="w-full h-[56px] bg-primary-accent text-black text-body leading-body font-semibold rounded-[10px] hover:brightness-105 active:scale-[0.99] transition-all duration-200 flex items-center justify-center gap-2 shadow-[0_4px_12px_-4px_rgba(179,255,0,0.3)] disabled:opacity-70 disabled:cursor-not-allowed group/btn"
          >
            {isLoading ? (
              <Loader2 className="w-5 h-5 animate-spin" />
            ) : (
              "Sign Up"
            )}
          </button>

          {/* Sign In Link */}
          <p className="text-center text-[#a1a1aa] text-[14px]">
            Already have an account?{" "}
            <Link href="/" className="text-primary-accent font-medium hover:underline">
              Sign In
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
