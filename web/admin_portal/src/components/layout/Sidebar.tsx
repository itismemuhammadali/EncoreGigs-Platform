"use client";

import React from "react";
import Link from "next/link";
import Image from "next/image";
import { usePathname, useRouter } from "next/navigation";
import {
  LayoutDashboard,
  Users,
  Briefcase,
  SearchCode,
  CreditCard,
  FileText,
  MessageSquare,
  Star,
  ShieldAlert,
  Bell,
  BarChart3,
  Settings,
  LogOut,
  X
} from "lucide-react";

const menuItems = [
  { name: "Dashboard", href: "/dashboard", icon: LayoutDashboard },
  { name: "Users Management", href: "/users", icon: Users },
  { name: "Gig Management", href: "/gigs", icon: Briefcase },
  { name: "Scraper Module", href: "/scraper", icon: SearchCode },
  { name: "Payments & Escrow", href: "/payments", icon: CreditCard },
  { name: "Contracts", href: "/contracts", icon: FileText },
  { name: "Reviews Management", href: "/reviews", icon: MessageSquare },
  { name: "Featured Artists", href: "/featured", icon: Star },
  { name: "Disputes", href: "/disputes", icon: ShieldAlert },
  { name: "Notifications", href: "/notifications", icon: Bell },
  { name: "Reports & Analytics", href: "/reports", icon: BarChart3 },
  { name: "Settings", href: "/settings", icon: Settings },
];

interface SidebarProps {
  isOpen: boolean;
  onClose: () => void;
}

export function Sidebar({ isOpen, onClose }: SidebarProps) {
  const pathname = usePathname();
  const router = useRouter();
  const [mounted, setMounted] = React.useState(false);

  React.useEffect(() => {
    setMounted(true);
  }, []);

  const handleLogout = () => {
    // BACKEND DEVELOPER: Clear session, tokens, or cookies here
    onClose();
    router.push("/");
  };

  return (
    <aside className={`w-[280px] h-screen bg-[#0F0F0F] border-r border-[#1a1a1e] fixed left-0 top-0 flex flex-col z-50 transition-transform duration-300 transform ${
      isOpen ? "translate-x-0" : "-translate-x-full xl:translate-x-0"
    }`}>
      {/* Header / Logo */}
      <div className="p-8 pb-10 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="relative w-10 h-10">
            <Image
              src="/logo.png"
              alt="OnlyGigz Logo"
              fill
              sizes="40px"
              className="object-contain"
            />
          </div>
          <div>
            <h2 className="text-white font-bold text-[18px] leading-tight">
              OnlyGigz Admin
            </h2>
            <p className="text-[#a1a1aa] text-[11px] font-medium tracking-wide">
              Admin Panel
            </p>
          </div>
        </div>
        
        {/* Mobile Close Button */}
        <button 
          onClick={onClose}
          className="xl:hidden p-2 text-[#a1a1aa] hover:text-white transition-colors"
        >
          <X size={20} />
        </button>
      </div>

      {/* Navigation */}
      <nav className="flex-1 px-4 overflow-y-auto space-y-2 custom-scrollbar pb-10 pt-2">
        {menuItems.map((item) => {
          const isActive = mounted && pathname === item.href;
          const Icon = item.icon;

          return (
            <Link
              key={item.name}
              href={item.href}
              onClick={() => {
                if (window.innerWidth < 1280) onClose();
              }}
              className={`flex items-center gap-3.5 px-5 py-3.5 rounded-[10px] transition-all duration-200 group border ${isActive
                ? "bg-[#b3ff00] border-[#b3ff00] text-black font-bold shadow-[0_0_20px_-5px_rgba(179,255,0,0.3)]"
                : "bg-transparent border-[#1a1a1e] text-white hover:border-[#27272a] hover:bg-white/5"
                }`}
            >
              <Icon
                className={`w-[20px] h-[20px] transition-colors ${isActive ? "text-black" : "text-white group-hover:text-[#b3ff00]"
                  }`}
              />
              <span className="text-[14px] font-medium">{item.name}</span>
            </Link>
          );
        })}
      </nav>

      {/* Logout at Bottom */}
      <div className="p-4.5 border-t border-[#1a1a1e]">
        <button 
          onClick={handleLogout}
          className="flex items-center gap-3.5 px-5 py-3.5 w-full rounded-[10px] border border-[#1a1a1e] text-[#ef4444] hover:bg-[#ef4444]/10 hover:border-[#ef4444]/20 transition-all group"
        >
          <LogOut className="w-[20px] h-[20px]" />
          <span className="text-[14px] font-bold">Logout</span>
        </button>
      </div>
    </aside>
  );
}
