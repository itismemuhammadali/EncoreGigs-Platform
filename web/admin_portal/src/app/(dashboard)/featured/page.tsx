"use client";

import React, { useState, useEffect } from "react";
import { 
  Star, 
  DollarSign, 
  Eye, 
  TrendingUp,
  XCircle,
  Clock,
  Calendar
} from "lucide-react";
import { Toast } from "@/components/ui/Toast";
import { RevokePlacementModal } from "@/components/ui/RevokePlacementModal";
import { apiRequest } from "@/lib/api";

// --- Types & Interfaces ---
interface FeaturedArtist {
  id: string;
  musicianId?: string;
  name: string;
  genre: string;
  boostDuration: string;
  startDate: string;
  expiryDate: string;
  amountPaid: string;
  views: string;
  status: "active" | "expired";
}

export default function FeaturedArtistsPage() {
  const [featured, setFeatured] = useState<FeaturedArtist[]>([]);
  const [loading, setLoading] = useState(true);
  const [toast, setToast] = useState({ show: false, message: "" });
  const [isRevokeModalOpen, setIsRevokeModalOpen] = useState(false);
  const [selectedArtistId, setSelectedArtistId] = useState<string | null>(null);

  const fetchFeaturedArtists = async () => {
    try {
      setLoading(true);
      const data = await apiRequest("/featured/artists");
      if (Array.isArray(data)) {
        setFeatured(data);
      }
    } catch (err: any) {
      console.error("Failed to fetch featured artists:", err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchFeaturedArtists();
  }, []);

  // --- Handlers ---
  const confirmRevoke = async () => {
    if (selectedArtistId) {
      try {
        await apiRequest(`/featured/${selectedArtistId}/revoke`, { method: "POST" });
        setFeatured(prev => prev.map(item => 
          item.id === selectedArtistId || item.musicianId === selectedArtistId 
            ? { ...item, status: "expired" } 
            : item
        ));
        setToast({ show: true, message: `Featured placement for ${selectedArtistId} revoked.` });
      } catch (err: any) {
        setToast({ show: true, message: err.message || "Failed to revoke placement." });
      } finally {
        setIsRevokeModalOpen(false);
        setSelectedArtistId(null);
      }
    }
  };

  const handleRevokeClick = (id: string) => {
    setSelectedArtistId(id);
    setIsRevokeModalOpen(true);
  };

  // --- UI Configuration Arrays ---
  // BACKEND DEVELOPER: These summary stats should ideally be returned by the backend 
  // in a single dashboard stats call.
  const activeCount = featured.filter(f => f.status === "active").length;
  const totalRev = featured.reduce((sum, f) => {
    const num = parseFloat((f.amountPaid || "").replace(/[^0-9.]/g, "")) || 0;
    return sum + num;
  }, 0);

  const stats = [
    { 
      label: "Active Featured", 
      value: String(activeCount), 
      icon: Star, 
      bg: "bg-[#A2F301]/10", 
      iconColor: "text-[#A2F301]",
      border: "border-[#A2F301]/20"
    },
    { 
      label: "Revenue This Month", 
      value: `$${totalRev.toFixed(0)}`, 
      icon: DollarSign, 
      bg: "bg-[#10B981]/10", 
      iconColor: "text-[#10B981]",
      border: "border-[#10B981]/20"
    },
    { 
      label: "Total Featured Artists", 
      value: String(featured.length), 
      icon: Eye, 
      bg: "bg-blue-500/10", 
      iconColor: "text-blue-500",
      border: "border-blue-500/20"
    },
    { 
      label: "Avg. Revenue / Artist", 
      value: `$${featured.length ? (totalRev / featured.length).toFixed(0) : "0"}`, 
      icon: TrendingUp, 
      bg: "bg-amber-500/10", 
      iconColor: "text-amber-500",
      border: "border-amber-500/20"
    }
  ];

  const packages = [
    { 
      duration: "24 Hours Boost", 
      price: "$29", 
      desc: "Perfect for quick visibility",
      isBestValue: false 
    },
    { 
      duration: "7 Days Boost", 
      price: "$79", 
      desc: "Most popular choice",
      isBestValue: false 
    },
    { 
      duration: "30 Days Boost", 
      price: "$299", 
      desc: "Maximum exposure & reach",
      isBestValue: true 
    }
  ];

  const tableHeaders = [
    "Artist Name", "Genre", "Boost Duration", "Start Date", 
    "Expiry Date", "Amount Paid", "Views", "Status", "Actions"
  ];

  return (
    <div className="w-full pb-20">
      {/* Header Section */}
      <div className="mb-8">
        <h1 className="text-2xl sm:text-[30px] font-bold text-white leading-tight mb-1">Featured Artist Management</h1>
        <p className="text-[#999999] text-sm sm:text-[16px]">Manage featured artist placements and boost durations</p>
      </div>

      {/* Stats Cards Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 sm:gap-6 mb-10">
        {stats.map((stat, i) => (
          <div key={i} className="bg-[#1A1A1A] border border-[#2A2A2A] rounded-[8px] p-4 sm:p-6 flex items-center gap-4 group hover:border-[#A2F301]/30 transition-all shadow-xl">
            <div className={`w-12 h-12 sm:w-[48px] sm:h-[48px] ${stat.bg} ${stat.border} border rounded-[8px] flex items-center justify-center shrink-0`}>
              <stat.icon className={`w-5 h-5 sm:w-6 sm:h-6 ${stat.iconColor}`} />
            </div>
            <div>
              <p className="text-[#999999] text-[13px] sm:text-[14px] font-medium mb-0.5">{stat.label}</p>
              <p className="text-white text-2xl sm:text-[28px] font-bold leading-none">{stat.value}</p>
            </div>
          </div>
        ))}
      </div>

      {/* Table Section */}
      <div className="bg-[#1A1A1A] border border-[#2A2A2A] rounded-[8px] overflow-hidden mb-10 shadow-2xl">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="border-b border-[#2A2A2A] bg-[#262626]">
                {tableHeaders.map((header, i) => (
                  <th key={i} className="px-6 py-5 text-[12px] sm:text-[13px] font-semibold text-[#999999] uppercase tracking-wider whitespace-nowrap">
                    {header}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-[#2A2A2A]">
              {featured.map((artist) => (
                <tr key={artist.id} className="hover:bg-white/[0.02] transition-all group animate-in fade-in duration-300">
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-3">
                      <div className="w-8 h-8 rounded-full bg-[#A2F301]/10 flex items-center justify-center border border-[#A2F301]/20 shrink-0">
                        <Star className="w-4 h-4 text-[#A2F301]" />
                      </div>
                      <span className="text-white text-[14px] font-medium whitespace-nowrap">{artist.name}</span>
                    </div>
                  </td>
                  <td className="px-6 py-4 text-[#999999] text-[14px]">{artist.genre}</td>
                  <td className="px-6 py-4">
                    <div className="inline-flex items-center px-3 py-1 bg-[#A2F301]/10 rounded-full border border-[#A2F301]/20 whitespace-nowrap">
                      <span className="text-[#A2F301] text-[12px] font-bold">{artist.boostDuration}</span>
                    </div>
                  </td>
                  <td className="px-6 py-4 text-[#999999] text-[14px] whitespace-nowrap">{artist.startDate}</td>
                  <td className="px-6 py-4 text-[#999999] text-[14px] whitespace-nowrap">{artist.expiryDate}</td>
                  <td className="px-6 py-4">
                    <span className="text-[#A2F301] text-[14px] font-bold">{artist.amountPaid}</span>
                  </td>
                  <td className="px-6 py-4 text-white text-[14px] font-bold">{artist.views}</td>
                  <td className="px-6 py-4">
                    <div className={`inline-flex items-center px-2 py-0.5 rounded-[4px] text-[11px] font-bold uppercase tracking-wider ${
                      artist.status === "active" 
                        ? "bg-[#10B981]/10 text-[#10B981]" 
                        : "bg-white/5 text-[#52525b]"
                    }`}>
                      {artist.status}
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <button 
                      onClick={() => handleRevokeClick(artist.id)}
                      className="text-[#EF4444] hover:text-[#f87171] text-[14px] font-medium flex items-center gap-1.5 transition-all group/btn"
                    >
                      <XCircle size={16} className="group-hover/btn:scale-110 transition-transform" />
                      Revoke
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* Boost Packages Section */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
        {packages.map((pkg, i) => (
          <div 
            key={i} 
            className={`bg-[#1A1A1A] border rounded-[8px] p-6 sm:p-8 relative transition-all group hover:-translate-y-1 ${
              pkg.isBestValue ? "border-[#A2F301] ring-1 ring-[#A2F301]/20 shadow-[0_0_30px_-10px_rgba(162,243,1,0.2)]" : "border-[#2A2A2A] hover:border-white/10"
            }`}
          >
            {pkg.isBestValue && (
              <div className="absolute -top-3 right-4 bg-[#A2F301] text-black text-[10px] sm:text-[11px] font-bold px-3 py-1 rounded-full uppercase tracking-widest">
                Best Value
              </div>
            )}
            <div className="flex justify-between items-start mb-4 gap-4">
              <h3 className="text-white text-[16px] sm:text-[18px] font-bold leading-tight">{pkg.duration}</h3>
              <p className="text-[#A2F301] text-2xl sm:text-[28px] font-bold leading-none">{pkg.price}</p>
            </div>
            <p className="text-[#999999] text-[14px] sm:text-[15px] leading-relaxed">
              {pkg.desc}
            </p>
          </div>
        ))}
      </div>

      {/* --- Modals & Notifications --- */}
      <RevokePlacementModal 
        isOpen={isRevokeModalOpen}
        onClose={() => setIsRevokeModalOpen(false)}
        onConfirm={confirmRevoke}
      />

      <Toast 
        show={toast.show}
        message={toast.message}
        onClose={() => setToast({ ...toast, show: false })}
      />
    </div>
  );
}
