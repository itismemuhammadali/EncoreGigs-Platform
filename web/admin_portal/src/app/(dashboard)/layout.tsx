"use client";

import { useState } from "react";
import { Sidebar } from "@/components/layout/Sidebar";
import { Header } from "@/components/layout/Header";

export default function DashboardLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  const [isSidebarOpen, setIsSidebarOpen] = useState(false);

  return (
    <div className="min-h-screen bg-[#0A0A0F]">
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
        <main className="mt-[80px] flex-1 p-4 sm:p-6 lg:p-10">
          {children}
        </main>
      </div>
    </div>
  );
}
