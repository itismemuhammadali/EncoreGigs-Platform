"use client";

import { useState, useEffect } from "react";
import { Search, Bell, ChevronDown, User, LogOut, Menu } from "lucide-react";
import { NotificationPanel } from "./NotificationPanel";
import { ProfileDropdown } from "./ProfileDropdown";

interface HeaderProps {
  onMenuClick: () => void;
}

export function Header({ onMenuClick }: HeaderProps) {
  const [isNotificationsOpen, setIsNotificationsOpen] = useState(false);
  const [isProfileOpen, setIsProfileOpen] = useState(false);
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

    // Listen for storage changes to sync across components
    window.addEventListener("storage", loadUser);
    
    // Custom event for same-window updates
    window.addEventListener("admin_user_updated", loadUser);

    return () => {
      window.removeEventListener("storage", loadUser);
      window.removeEventListener("admin_user_updated", loadUser);
    };
  }, []);

  return (
    <header className="h-[80px] bg-[#0F0F0F] border-b border-[#1a1a1e] fixed top-0 right-0 left-0 xl:left-[280px] z-40 flex items-center justify-between px-4 sm:px-10 transition-all duration-300">
      {/* Mobile Menu Button & Search */}
      <div className="flex items-center gap-4 flex-1">
        <button 
          onClick={onMenuClick}
          className="xl:hidden p-2 text-[#a1a1aa] hover:text-white transition-colors"
        >
          <Menu size={24} />
        </button>

        {/* Search Bar - Responsive width */}
        <div className="relative w-full max-w-[280px] group hidden sm:block">
          <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-[18px] h-[18px] text-[#52525b] group-focus-within:text-[#b3ff00] transition-colors" />
          <input
            type="text"
            placeholder="Search..."
            className="w-full h-[42px] bg-[#1A1A1A] border border-[#27272a] rounded-xl pl-11 pr-4 text-[14px] text-white focus:outline-none focus:border-[#b3ff00]/40 transition-all placeholder:text-[#52525b]"
          />
        </div>
      </div>

      {/* Right Side Actions */}
      <div className="flex items-center gap-4 sm:gap-8 relative">
        {/* Notifications */}
        <button 
          onClick={() => {
            setIsNotificationsOpen(!isNotificationsOpen);
            if (isProfileOpen) setIsProfileOpen(false);
          }}
          className={`relative p-2 transition-colors ${isNotificationsOpen ? "text-[#b3ff00]" : "text-[#a1a1aa] hover:text-white"}`}
        >
          <Bell className="w-[22px] h-[22px]" />
          <span className="absolute -top-0.5 -right-0.5 w-[18px] h-[18px] bg-[#A2F301] text-black text-[10px] font-bold flex items-center justify-center rounded-full border-2 border-[#0A0A0A]">
            2
          </span>
        </button>

        <NotificationPanel 
          isOpen={isNotificationsOpen} 
          onClose={() => setIsNotificationsOpen(false)} 
        />

        {/* User Profile */}
        <div 
          onClick={() => {
            setIsProfileOpen(!isProfileOpen);
            if (isNotificationsOpen) setIsNotificationsOpen(false);
          }}
          className="flex items-center gap-2 sm:gap-4 cursor-pointer group relative"
        >
          <div className="text-right flex flex-col justify-center hidden sm:flex">
            <p className="text-[14px] font-bold text-white leading-none mb-1 group-hover:text-[#b3ff00] transition-colors">
              {adminUser?.displayName || "Admin User"}
            </p>
            <p className="text-[11px] text-[#52525b] font-medium leading-none">Super Admin</p>
          </div>
          <div className={`w-[36px] h-[36px] sm:w-[40px] sm:h-[40px] rounded-full overflow-hidden bg-[#b3ff00] flex items-center justify-center border border-white/10 shadow-lg transition-all ${isProfileOpen ? "ring-2 ring-[#b3ff00]/50" : "group-hover:scale-105"}`}>
            {adminUser?.profileImageUrl ? (
              <img src={adminUser.profileImageUrl} alt="Admin" className="w-full h-full object-cover" />
            ) : (
              <User className="w-4 h-4 sm:w-5 sm:h-5 text-black" />
            )}
          </div>
          <ChevronDown className={`w-3.5 h-3.5 sm:w-4 sm:h-4 text-[#52525b] transition-all duration-300 ${isProfileOpen ? "rotate-180 text-white" : "group-hover:text-white"}`} />
          
          <ProfileDropdown 
            isOpen={isProfileOpen} 
            onClose={() => setIsProfileOpen(false)} 
          />
        </div>
      </div>
    </header>
  );
}
