"use client";

import React, { useState, useEffect, useCallback } from "react";
import {
  Search,
  Filter,
  Eye,
  Edit3,
  Flag,
  Trash2,
  CheckCircle2,
  XCircle,
  Briefcase,
  Check,
  X,
  AlertCircle,
  Loader2
} from "lucide-react";
import { Toast } from "@/components/ui/Toast";
import { ConfirmationModal } from "@/components/ui/ConfirmationModal";
import { GigDetailsModal } from "@/components/ui/GigDetailsModal";
import { EditGigModal } from "@/components/ui/EditGigModal";
import { apiRequest } from "@/lib/api";

interface Gig {
  id: string;
  title: string;
  type: "manual" | "scraped";
  venue: string;
  location?: string;
  date: string;
  budget: string | number;
  applicants: number;
  status: "active" | "pending" | "flagged";
  description?: string;
  requirements?: string;
  createdAt?: any;
}

export default function GigManagement() {
  const [gigs, setGigs] = useState<Gig[]>([]);
  const [activeTab, setActiveTab] = useState<"all" | "manual" | "scraped" | "flagged">("all");
  const [searchQuery, setSearchQuery] = useState("");
  const [isLoading, setIsLoading] = useState(true);

  // Modal & Toast States
  const [toast, setToast] = useState<{ show: boolean; message: string }>({ show: false, message: "" });
  const [deleteModal, setDeleteModal] = useState<{ show: boolean; gigId: string | null }>({ show: false, gigId: null });
  const [rejectModal, setRejectModal] = useState<{ show: boolean; gigId: string | null }>({ show: false, gigId: null });
  const [viewModal, setViewModal] = useState<{ show: boolean; gig: Gig | null }>({ show: false, gig: null });
  const [editModal, setEditModal] = useState<{ show: boolean; gig: Gig | null }>({ show: false, gig: null });

  const fetchGigs = useCallback(async () => {
    setIsLoading(true);
    try {
      const data = await apiRequest("/gigs/list");
      // Map backend data to frontend model if necessary
      const mappedGigs = data.map((g: any) => ({
        ...g,
        id: g.id || g.uid,
        type: g.type || "manual", // Default to manual if not specified
        status: g.status || "active",
        applicants: g.applicantsCount || 0,
        budget: g.budget || g.fee || "N/A",
        venue: g.location || g.venue || "N/A", // Map location to venue column per request
        location: g.location || g.venue
      }));
      setGigs(mappedGigs);
    } catch (err: any) {
      showToast("Failed to fetch gigs: " + err.message);
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchGigs();
  }, [fetchGigs]);

  // --- ACTIONS ---
  const showToast = (message: string) => {
    setToast({ show: true, message });
  };

  const handleApprove = async (id: string) => {
    try {
      // For now update locally
      setGigs(prev => prev.map(g => g.id === id ? { ...g, status: "active" } : g));
      showToast("Gig approved successfully");
      // Re-fetch to sync counts
      fetchGigs();
    } catch (err: any) {
      showToast("Error: " + err.message);
    }
  };

  const handleFlag = async (id: string) => {
    try {
      setGigs(prev => prev.map(g => g.id === id ? { ...g, status: "flagged" } : g));
      showToast("Gig flagged");
      fetchGigs();
    } catch (err: any) {
      showToast("Error: " + err.message);
    }
  };

  const confirmDelete = async () => {
    if (deleteModal.gigId) {
      try {
        setGigs(prev => prev.filter(g => g.id !== deleteModal.gigId));
        setDeleteModal({ show: false, gigId: null });
        showToast("Gig deleted successfully");
        fetchGigs();
      } catch (err: any) {
        showToast("Error: " + err.message);
      }
    }
  };

  const confirmReject = async () => {
    if (rejectModal.gigId) {
      try {
        setGigs(prev => prev.filter(g => g.id !== rejectModal.gigId));
        setRejectModal({ show: false, gigId: null });
        showToast("Gig rejected successfully");
        fetchGigs();
      } catch (err: any) {
        showToast("Error: " + err.message);
      }
    }
  };

  const handleSaveEdit = async (formData: any) => {
    if (editModal.gig) {
      try {
        setGigs(prev => prev.map(g => g.id === editModal.gig?.id ? { ...g, ...formData } : g));
        setEditModal({ show: false, gig: null });
        showToast("Gig updated successfully");
      } catch (err: any) {
        showToast("Error: " + err.message);
      }
    }
  };

  // --- FILTERING LOGIC ---
  const filteredGigs = gigs.filter(gig => {
    const venueText = gig.location || gig.venue || "";
    const matchesSearch = gig.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
      venueText.toLowerCase().includes(searchQuery.toLowerCase());

    const matchesTab = activeTab === "all" ||
      (activeTab === "manual" && gig.type === "manual") ||
      (activeTab === "scraped" && gig.type === "scraped") ||
      (activeTab === "flagged" && gig.status === "flagged");

    return matchesSearch && matchesTab;
  });

  const counts = {
    all: gigs.length,
    manual: gigs.filter(g => g.type === "manual").length,
    scraped: gigs.filter(g => g.type === "scraped").length,
    flagged: gigs.filter(g => g.status === "flagged").length,
  };

  return (
    <div className="relative min-h-screen">
      <div className="space-y-8 animate-in fade-in duration-700 pb-20">
        {/* --- HEADER --- */}
        <div>
          <h1 className="text-2xl sm:text-[32px] font-bold text-white mb-2">Gig Management</h1>
          <p className="text-[#a1a1aa] text-sm sm:text-[16px]">Manage all gigs including manual posts and scraped listings</p>
        </div>

        {/* --- TABS --- */}
        <div className="flex gap-4 sm:gap-8 border-b border-[#1a1a1e] overflow-x-auto custom-scrollbar whitespace-nowrap">
          {[
            { id: "all", label: "All Gigs", count: counts.all },
            { id: "manual", label: "Manual Posts", count: counts.manual },
            { id: "scraped", label: "Scraped Gigs", count: counts.scraped },
            { id: "flagged", label: "Flagged", count: counts.flagged },
          ].map((tab) => (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id as any)}
              className={`pb-4 text-[14px] sm:text-[15px] font-bold transition-all relative ${activeTab === tab.id ? "text-[#b3ff00]" : "text-[#a1a1aa] hover:text-white"
                }`}
            >
              {tab.label} ({tab.count})
              {activeTab === tab.id && (
                <div className="absolute bottom-0 left-0 w-full h-[2px] bg-[#b3ff00]" />
              )}
            </button>
          ))}
        </div>

        {/* --- FILTERS --- */}
        <div className="flex flex-col sm:flex-row gap-4">
          <div className="flex-1 relative group">
            <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-[#a1a1aa] group-focus-within:text-[#b3ff00] transition-colors" />
            <input
              type="text"
              placeholder="Search gigs by title, venue, or organizer..."
              className="w-full bg-[#1A1A1A] border border-[#1a1a1e] rounded-xl py-3.5 pl-11 pr-4 text-[14px] text-white placeholder:text-[#52525b] focus:outline-none focus:border-[#b3ff00]/50 transition-all shadow-lg"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
            />
          </div>
          <button className="flex items-center justify-center gap-2 bg-[#1A1A1A] border border-[#1a1a1e] px-6 py-3.5 rounded-xl text-white font-medium hover:border-[#b3ff00]/50 transition-all shadow-lg text-[14px]">
            <Filter className="w-4 h-4" />
            Filter
          </button>
        </div>

        {/* --- DATA TABLE --- */}
        <div className="bg-[#1A1A1A] border border-[#1a1a1e] rounded-2xl overflow-hidden shadow-2xl relative min-h-[400px]">
          {isLoading && (
            <div className="absolute inset-0 bg-black/20 backdrop-blur-[2px] z-20 flex items-center justify-center">
              <Loader2 className="w-8 h-8 text-[#b3ff00] animate-spin" />
            </div>
          )}
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="bg-[#1F1F1F] border-b border-[#1a1a1e]">
                  <th className="px-6 py-5 text-[14px] font-medium text-[#a1a1aa]">Title</th>
                  <th className="px-6 py-5 text-[14px] font-medium text-[#a1a1aa]">Type</th>
                  <th className="px-6 py-5 text-[14px] font-medium text-[#a1a1aa]">Venue</th>
                  <th className="px-6 py-5 text-[14px] font-medium text-[#a1a1aa]">Date</th>
                  <th className="px-6 py-5 text-[14px] font-medium text-[#a1a1aa]">Budget</th>
                  <th className="px-6 py-5 text-[14px] font-medium text-[#a1a1aa]">Applicants</th>
                  <th className="px-6 py-5 text-[14px] font-medium text-[#a1a1aa]">Status</th>
                  <th className="px-6 py-5 text-[14px] font-medium text-[#a1a1aa]">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-[#1a1a1e]">
                {filteredGigs.map((gig) => (
                  <tr key={gig.id} className="hover:bg-white/[0.02] transition-colors group">
                    <td className="px-6 py-5 max-w-[280px]">
                      <span className="text-white font-bold text-[15px] group-hover:text-[#b3ff00] transition-colors truncate block">{gig.title}</span>
                    </td>
                    <td className="px-6 py-5">
                      <span className={`px-3 py-1 rounded-full text-[12px] font-medium lowercase ${gig.type === 'manual'
                        ? 'bg-[#b3ff00]/10 text-[#b3ff00]'
                        : 'bg-[#3b82f6]/10 text-[#3b82f6]'
                        }`}>
                        {gig.type}
                      </span>
                    </td>
                    <td className="px-6 py-5 text-[#a1a1aa] text-[14px] font-medium">{gig.venue}</td>
                    <td className="px-6 py-5 text-white text-[14px] font-medium opacity-80">{gig.date}</td>
                    <td className="px-6 py-5 text-[#b3ff00] text-[16px] font">{gig.budget}</td>
                    <td className="px-6 py-5 text-white text-[14px] font-medium">{gig.applicants}</td>
                    <td className="px-6 py-5">
                      <span className={`px-3 py-1 rounded-full text-[12px] font-bold ${gig.status === 'active'
                        ? 'bg-[#10b981]/10 text-[#10b981]'
                        : gig.status === 'pending'
                          ? 'bg-[#f59e0b]/10 text-[#f59e0b]'
                          : 'bg-[#ef4444]/10 text-[#ef4444]'
                        }`}>
                        {gig.status}
                      </span>
                    </td>
                    <td className="px-6 py-5">
                      <div className="flex items-center gap-4">
                        <button 
                          onClick={() => setViewModal({ show: true, gig })}
                          className="text-[#a1a1aa] hover:text-white hover:scale-110 transition-all" 
                          title="View Details"
                        >
                          <Eye className="w-[18px] h-[18px]" />
                        </button>
                        <button 
                          onClick={() => setEditModal({ show: true, gig })}
                          className="text-[#a1a1aa] hover:text-[#3b82f6] hover:scale-110 transition-all" 
                          title="Edit Gig"
                        >
                          <Edit3 className="w-[18px] h-[18px]" />
                        </button>

                        {gig.status === "pending" && (
                          <>
                            <button
                              onClick={() => handleApprove(gig.id)}
                              className="text-[#10b981] hover:scale-110 transition-all"
                              title="Approve"
                            >
                              <CheckCircle2 className="w-[18px] h-[18px]" />
                            </button>
                            <button
                              onClick={() => setRejectModal({ show: true, gigId: gig.id })}
                              className="text-[#ef4444] hover:scale-110 transition-all"
                              title="Reject"
                            >
                              <XCircle className="w-[18px] h-[18px]" />
                            </button>
                          </>
                        )}

                        <button
                          onClick={() => handleFlag(gig.id)}
                          className="text-[#a1a1aa] hover:text-[#f59e0b] hover:scale-110 transition-all"
                          title="Flag Gig"
                        >
                          <Flag className="w-[18px] h-[18px]" />
                        </button>
                        <button
                          onClick={() => setDeleteModal({ show: true, gigId: gig.id })}
                          className="text-[#a1a1aa] hover:text-[#ef4444] hover:scale-110 transition-all"
                          title="Delete Gig"
                        >
                          <Trash2 className="w-[18px] h-[18px]" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>

            {filteredGigs.length === 0 && (
              <div className="p-16 text-center">
                <div className="w-16 h-16 bg-[#1a1a1e] rounded-full flex items-center justify-center mx-auto mb-4">
                  <Briefcase className="w-8 h-8 text-[#52525b]" />
                </div>
                <p className="text-[#a1a1aa] text-[16px] font-medium">No gigs found matching your selection.</p>
              </div>
            )}
          </div>
        </div>
      </div>

      {/* --- TOAST NOTIFICATION --- */}
      <Toast
        show={toast.show}
        message={toast.message}
        onClose={() => setToast(prev => ({ ...prev, show: false }))}
      />

      {/* --- GIG DETAILS MODAL --- */}
      <GigDetailsModal 
        isOpen={viewModal.show}
        onClose={() => setViewModal({ show: false, gig: null })}
        gig={viewModal.gig ? { ...viewModal.gig, budget: String(viewModal.gig.budget) } : null}
      />

      {/* --- EDIT GIG MODAL --- */}
      <EditGigModal 
        isOpen={editModal.show}
        onClose={() => setEditModal({ show: false, gig: null })}
        onSave={handleSaveEdit}
        gig={editModal.gig as any}
      />

      {/* --- CONFIRMATION MODALS --- */}
      <ConfirmationModal 
        isOpen={deleteModal.show}
        onClose={() => setDeleteModal({ show: false, gigId: null })}
        onConfirm={confirmDelete}
        title="Delete Gig?"
        description="This action cannot be undone. The gig will be permanently deleted from the platform."
        cancelLabel="Cancel"
        confirmLabel="Delete Gig"
      />

      <ConfirmationModal 
        isOpen={rejectModal.show}
        onClose={() => setRejectModal({ show: false, gigId: null })}
        onConfirm={confirmReject}
        title="Reject Gig?"
        description="This gig will be rejected and removed from the active listings. This action is final."
        cancelLabel="Cancel"
        confirmLabel="Reject Gig"
      />
    </div>
  );
}
