"use client";

import React, { useState, useEffect } from "react";
import { User, LogOut } from "lucide-react";
import Link from "next/link";
import { useRouter } from "next/navigation";

interface ProfileDropdownProps {
  isOpen: boolean;
  onClose: () => void;
}

export function ProfileDropdown({ isOpen, onClose }: ProfileDropdownProps) {
  const router = useRouter();
  const [adminUser, setAdminUser] = useState<{ displayName?: string; email?: string; profileImageUrl?: string } | null>(null);

  useEffect(() => {
    const loadUser = () => {
      const userStr = localStorage.getItem("admin_user");
      if (userStr) {
        try {
          setAdminUser(JSON.parse(userStr));
        } catch (e) {
          console.error("Failed to parse admin_user", e);
        }
      }
    };

    loadUser();
    window.addEventListener("storage", loadUser);
    window.addEventListener("admin_user_updated", loadUser);

    return () => {
      window.removeEventListener("storage", loadUser);
      window.removeEventListener("admin_user_updated", loadUser);
    };
  }, []);

  if (!isOpen) return null;

  const handleLogout = () => {
    localStorage.removeItem("admin_token");
    localStorage.removeItem("admin_user");
    onClose();
    router.push("/");
  };

  return (
    <>
      {/* Overlay to close dropdown when clicking outside */}
      <div 
        className="fixed inset-0 z-40 bg-transparent" 
        onClick={onClose}
      />
      
      <div className="absolute top-[70px] right-0 w-[280px] bg-[#1A1A1A] border border-[#2A2A2A] rounded-[8px] shadow-[0_20px_50px_rgba(0,0,0,0.5)] z-50 overflow-hidden animate-in fade-in slide-in-from-top-2 duration-200">
        {/* User Info Section */}
        <div className="p-6 flex items-center gap-4 border-b border-[#2A2A2A]">
          <div className="w-[50px] h-[50px] rounded-full overflow-hidden bg-[#A2F301] flex items-center justify-center flex-shrink-0">
            {adminUser?.profileImageUrl ? (
              <img src={adminUser.profileImageUrl} alt="Admin" className="w-full h-full object-cover" />
            ) : (
              <User className="w-6 h-6 text-black" />
            )}
          </div>
          <div className="overflow-hidden">
            <h3 className="text-white font-bold text-[16px] truncate">
              {adminUser?.displayName || "Admin User"}
            </h3>
            <p className="text-[#999999] text-[13px] truncate">
              {adminUser?.email || "admin@onlygigz.com"}
            </p>
          </div>
        </div>

        {/* Menu Items */}
        <div className="p-2">
          <Link 
            href="/settings" 
            onClick={onClose}
            className="flex items-center gap-3 px-4 py-3 rounded-[6px] text-[#D1D1D1] hover:bg-white/5 hover:text-white transition-all group"
          >
            <div className="w-8 h-8 rounded-full bg-white/5 flex items-center justify-center group-hover:bg-[#A2F301]/10 transition-colors">
              <User size={18} className="group-hover:text-[#A2F301]" />
            </div>
            <span className="text-[14px] font-medium">My Profile</span>
          </Link>

          <button 
            onClick={handleLogout}
            className="w-full flex items-center gap-3 px-4 py-3 rounded-[6px] text-[#EF4444] hover:bg-[#EF4444]/5 transition-all group mt-1"
          >
            <div className="w-8 h-8 rounded-full bg-[#EF4444]/5 flex items-center justify-center group-hover:bg-[#EF4444]/10 transition-colors">
              <LogOut size={18} />
            </div>
            <span className="text-[14px] font-medium">Logout</span>
          </button>
        </div>
      </div>
    </>
  );
}
