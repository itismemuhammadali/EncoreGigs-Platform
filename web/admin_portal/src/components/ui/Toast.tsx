"use client";

import React, { useEffect } from "react";
import { Check } from "lucide-react";

interface ToastProps {
  show: boolean;
  message: string;
  onClose: () => void;
  duration?: number;
}

export function Toast({ show, message, onClose, duration = 3000 }: ToastProps) {
  useEffect(() => {
    if (show) {
      const timer = setTimeout(() => {
        onClose();
      }, duration);
      return () => clearTimeout(timer);
    }
  }, [show, duration, onClose]);

  if (!show) return null;

  return (
    <div className="fixed top-[96px] right-10 z-[100] animate-in fade-in slide-in-from-top-5 duration-300">
      <div className="bg-[#1A1A1A] border border-white/[0.03] rounded-2xl px-6 py-4 shadow-[0_8px_30px_rgba(0,0,0,0.5)] flex items-center gap-3.5 min-w-[320px]">
        <div className="w-6 h-6 rounded-full bg-white flex items-center justify-center">
          <Check className="w-4 h-4 text-black stroke-[3px]" />
        </div>
        <span className="text-white text-[15px] font-medium tracking-tight">{message}</span>
      </div>
    </div>
  );
}
