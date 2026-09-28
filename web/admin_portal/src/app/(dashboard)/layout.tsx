"use client";

import { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import { Sidebar } from "@/components/layout/Sidebar";
import { Header } from "@/components/layout/Header";

export default function DashboardLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  const [isSidebarOpen, setIsSidebarOpen] = useState(false);
  const [mounted, setMounted] = useState(false);
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const router = useRouter();

  useEffect(() => {
    setMounted(true);
    const token = localStorage.getItem("admin_token");
    const userStr = localStorage.getItem("admin_user");
    if (!token || !userStr) {
      router.replace("/");
    } else {
      setIsAuthenticated(true);
    }
  }, [router]);

  if (!mounted || !isAuthenticated) {
    return (
      <div className="min-h-screen bg-[#0A0A0F] flex items-center justify-center">
        <div className="w-8 h-8 border-2 border-[#A1F301] border-t-transparent rounded-full animate-spin" />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-[#0A0A0F]" suppressHydrationWarning>
      <Sidebar isOpen={isSidebarOpen} onClose={() => setIsSidebarOpen(false)} />
      
      {/* Mobile Overlay */}
      {isSidebarOpen && (
        <div 
          className="fixed inset-0 bg-black/60 backdrop-blur-sm z-40 xl:hidden transition-all duration-300"
          onClick={() => setIsSidebarOpen(false)}
        />
      )}

      <div className={`flex flex-col min-h-screen transition-all duration-300 ${
        "xl:pl-[280px]"
      }`}>
        <Header onMenuClick={() => setIsSidebarOpen(true)} />
        <main className="mt-[80px] flex-1 p-4 sm:p-6 lg:p-10" suppressHydrationWarning>
          {children}
        </main>
      </div>
    </div>
  );
}
