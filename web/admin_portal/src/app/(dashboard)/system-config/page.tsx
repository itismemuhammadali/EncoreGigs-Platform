"use client";

import { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import { RefreshCw, ShieldAlert } from "lucide-react";
import { SystemConfigSection } from "@/components/settings/SystemConfigSection";

export default function SystemConfigPage() {
  const router = useRouter();
  const [isSuperAdmin, setIsSuperAdmin] = useState<boolean | null>(null);

  useEffect(() => {
    const token = localStorage.getItem("admin_token");
    const userStr = localStorage.getItem("admin_user");
    if (!token || !userStr) {
      router.replace("/");
      return;
    }

    try {
      const user = JSON.parse(userStr);
      const role = (user.role || "").toLowerCase().trim();
      if (role === "super_admin" || role === "superadmin") {
        setIsSuperAdmin(true);
      } else {
        setIsSuperAdmin(false);
      }
    } catch {
      router.replace("/");
    }
  }, [router]);

  if (isSuperAdmin === null) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[60vh] gap-3 text-white">
        <RefreshCw className="w-8 h-8 text-[#A1F301] animate-spin" />
        <p className="text-[#999999] text-[14px]">Verifying administrator privileges...</p>
      </div>
    );
  }

  if (!isSuperAdmin) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[60vh] p-6 text-center max-w-lg mx-auto">
        <div className="w-16 h-16 rounded-full bg-red-500/10 border border-red-500/30 flex items-center justify-center mb-4 text-red-500">
          <ShieldAlert className="w-8 h-8" />
        </div>
        <h2 className="text-white text-2xl font-bold mb-2">Access Restricted</h2>
        <p className="text-[#999999] text-sm leading-relaxed mb-6">
          This section contains sensitive system credentials, scrapers, and email relays. Access is strictly restricted to <b>Super Administrators</b>.
        </p>
        <button
          onClick={() => router.push("/dashboard")}
          className="px-6 py-2.5 bg-[#A1F301] hover:bg-[#8ee600] text-black font-semibold text-sm rounded-lg transition-all"
        >
          Return to Dashboard
        </button>
      </div>
    );
  }

  return (
    <div className="max-w-6xl mx-auto">
      <SystemConfigSection />
    </div>
  );
}
