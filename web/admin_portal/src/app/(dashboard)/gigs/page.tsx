"use client";

import React, { useState, useEffect, useCallback, useMemo } from "react";
import { useSearchParams } from "next/navigation";
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
  status: "active" | "open" | "pending" | "flagged" | "expired" | "rejected";
  description?: string;
  requirements?: string;
  createdAt?: any;
}

export default function GigManagement() {
  const searchParams = useSearchParams();
  const [gigs, setGigs] = useState<Gig[]>([]);
  const [activeTab, setActiveTab] = useState<"all" | "manual" | "scraped" | "flagged">("all");
  const [searchQuery, setSearchQuery] = useState("");
  const [isLoading, setIsLoading] = useState(true);

  // Filter Dropdown States
  const [isFilterOpen, setIsFilterOpen] = useState(false);
  const [statusFilter, setStatusFilter] = useState<string>("all");
  const [typeFilter, setTypeFilter] = useState<string>("all");

  // Selection States
  const [selectedGigIds, setSelectedGigIds] = useState<string[]>([]);
  const [bulkActionLoading, setBulkActionLoading] = useState(false);
  const [bulkDeleteModalOpen, setBulkDeleteModalOpen] = useState(false);

  useEffect(() => {
    const q = searchParams.get("q") || searchParams.get("search");
    if (q) setSearchQuery(q);
  }, [searchParams]);

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
      const mappedGigs = (Array.isArray(data) ? data : []).map((g: any) => {
        const isScraped = Boolean(
          g.isScraped === true ||
          g.type === "scraped" ||
          Boolean(g.sourceType) ||
          Boolean(g.sourceUrl) ||
          g.organizerId === "scraped"
        );
        return {
          ...g,
          id: g.id || g.uid,
          type: (isScraped ? "scraped" : "manual") as "manual" | "scraped",
          status: (g.status || "open") as any,
          applicants: g.applicantsCount || 0,
          budget: g.budget || g.fee || "N/A",
          venue: g.location || g.venue || "N/A",
          location: g.location || g.venue
        };
      });
      setGigs(mappedGigs);
      setSelectedGigIds([]);
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
      await apiRequest(`/gigs/${id}/status?status=open`, {
        method: "POST"
      });
      setGigs(prev => prev.map(g => g.id === id ? { ...g, status: "open" } : g));
      showToast("Gig approved successfully");
    } catch (err: any) {
      showToast("Error: " + err.message);
    }
  };

  const handleFlag = async (id: string) => {
    try {
      await apiRequest(`/gigs/${id}/status?status=flagged`, {
        method: "POST"
      });
      setGigs(prev => prev.map(g => g.id === id ? { ...g, status: "flagged" } : g));
      showToast("Gig flagged");
    } catch (err: any) {
      showToast("Error: " + err.message);
    }
  };

  const confirmDelete = async () => {
    if (deleteModal.gigId) {
      try {
        await apiRequest(`/gigs/${deleteModal.gigId}`, {
          method: "DELETE"
        });
        setGigs(prev => prev.filter(g => g.id !== deleteModal.gigId));
        setSelectedGigIds(prev => prev.filter(id => id !== deleteModal.gigId));
        setDeleteModal({ show: false, gigId: null });
        showToast("Gig deleted successfully");
      } catch (err: any) {
        showToast("Error deleting gig: " + err.message);
      }
    }
  };

  const confirmReject = async () => {
    if (rejectModal.gigId) {
      try {
        await apiRequest(`/gigs/${rejectModal.gigId}/status?status=rejected`, {
          method: "POST"
        });
        setGigs(prev => prev.map(g => g.id === rejectModal.gigId ? { ...g, status: "rejected" } : g));
        setRejectModal({ show: false, gigId: null });
        showToast("Gig rejected successfully");
      } catch (err: any) {
        showToast("Error: " + err.message);
      }
    }
  };

  const handleSaveEdit = async (formData: any) => {
    if (editModal.gig) {
      try {
        await apiRequest(`/gigs/${editModal.gig.id}`, {
          method: "PUT",
          body: JSON.stringify(formData)
        });
        setGigs(prev => prev.map(g => g.id === editModal.gig?.id ? { ...g, ...formData } : g));
        setEditModal({ show: false, gig: null });
        showToast("Gig updated successfully");
      } catch (err: any) {
        showToast("Error: " + err.message);
      }
    }
  };

  // --- FILTERING LOGIC ---
  const filteredGigs = useMemo(() => {
    return gigs.filter(gig => {
      const venueText = gig.location || gig.venue || "";
      const matchesSearch = gig.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
        venueText.toLowerCase().includes(searchQuery.toLowerCase());

      const matchesTab = activeTab === "all" ||
        (activeTab === "manual" && gig.type === "manual") ||
        (activeTab === "scraped" && gig.type === "scraped") ||
        (activeTab === "flagged" && gig.status === "flagged");

      const matchesStatusFilter = statusFilter === "all" || gig.status === statusFilter;
      const matchesTypeFilter = typeFilter === "all" || gig.type === typeFilter;

      return matchesSearch && matchesTab && matchesStatusFilter && matchesTypeFilter;
    });
  }, [gigs, searchQuery, activeTab, statusFilter, typeFilter]);

  const counts = {
    all: gigs.length,
    manual: gigs.filter(g => g.type === "manual").length,
    scraped: gigs.filter(g => g.type === "scraped").length,
    flagged: gigs.filter(g => g.status === "flagged").length,
  };

  // --- MULTI-SELECT HANDLERS ---
  const isAllSelected = filteredGigs.length > 0 && filteredGigs.every(g => selectedGigIds.includes(g.id));
  const isPartiallySelected = selectedGigIds.length > 0 && !isAllSelected;

  const handleToggleSelectAll = () => {
    if (isAllSelected) {
      const filteredIds = new Set(filteredGigs.map(g => g.id));
      setSelectedGigIds(prev => prev.filter(id => !filteredIds.has(id)));
    } else {
      const newIds = Array.from(new Set([...selectedGigIds, ...filteredGigs.map(g => g.id)]));
      setSelectedGigIds(newIds);
    }
  };

  const handleToggleSelect = (id: string) => {
    setSelectedGigIds(prev => 
      prev.includes(id) ? prev.filter(item => item !== id) : [...prev, id]
    );
  };

  // --- BULK ACTIONS ---
  const handleBulkStatus = async (status: string) => {
    if (selectedGigIds.length === 0) return;
    try {
      setBulkActionLoading(true);
      await apiRequest("/gigs/bulk-status", {
        method: "POST",
        body: JSON.stringify({ gigIds: selectedGigIds, status })
      });
      setGigs(prev => prev.map(g => selectedGigIds.includes(g.id) ? { ...g, status: status as any } : g));
      showToast(`Updated ${selectedGigIds.length} gigs to ${status}`);
      setSelectedGigIds([]);
    } catch (err: any) {
      showToast("Error updating gigs: " + err.message);
    } finally {
      setBulkActionLoading(false);
    }
  };

  const handleConfirmBulkDelete = async () => {
    if (selectedGigIds.length === 0) return;
    try {
      setBulkActionLoading(true);
      const res = await apiRequest("/gigs/bulk-delete", {
        method: "POST",
        body: JSON.stringify({ gigIds: selectedGigIds })
      });
      const deletedCount = res?.deletedCount ?? selectedGigIds.length;
      setGigs(prev => prev.filter(g => !selectedGigIds.includes(g.id)));
      showToast(`Deleted ${deletedCount} gigs successfully`);
      setSelectedGigIds([]);
      setBulkDeleteModalOpen(false);
    } catch (err: any) {
      showToast("Error deleting gigs: " + err.message);
    } finally {
      setBulkActionLoading(false);
    }
  };

  const hasActiveFilters = statusFilter !== "all" || typeFilter !== "all";

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
              onClick={() => {
                setActiveTab(tab.id as any);
                setSelectedGigIds([]);
              }}
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

        {/* --- FILTERS & SEARCH --- */}
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

          <div className="relative">
            <button 
              onClick={() => setIsFilterOpen(!isFilterOpen)}
              className={`flex items-center justify-center gap-2 bg-[#1A1A1A] border px-6 py-3.5 rounded-xl text-white font-medium hover:border-[#b3ff00]/50 transition-all shadow-lg text-[14px] ${
                hasActiveFilters ? "border-[#b3ff00] text-[#b3ff00]" : "border-[#1a1a1e]"
              }`}
            >
              <Filter className="w-4 h-4" />
              Filter
              {hasActiveFilters && (
                <span className="w-2 h-2 rounded-full bg-[#b3ff00] ml-1" />
              )}
            </button>

            {isFilterOpen && (
              <div className="absolute right-0 top-full mt-2 w-72 bg-[#1F1F1F] border border-[#2A2A2A] rounded-2xl shadow-2xl p-4 z-40 space-y-4 animate-in fade-in zoom-in-95">
                <div>
                  <label className="text-xs font-semibold text-[#a1a1aa] uppercase tracking-wider block mb-2">Status</label>
                  <div className="grid grid-cols-2 gap-1.5">
                    {["all", "open", "pending", "flagged", "expired", "rejected"].map((st) => (
                      <button
                        key={st}
                        onClick={() => setStatusFilter(st)}
                        className={`px-2.5 py-1.5 rounded-lg text-xs font-medium capitalize text-left transition-all ${
                          statusFilter === st ? "bg-[#b3ff00] text-black font-bold" : "bg-[#141414] text-[#a1a1aa] hover:text-white"
                        }`}
                      >
                        {st}
                      </button>
                    ))}
                  </div>
                </div>

                <div>
                  <label className="text-xs font-semibold text-[#a1a1aa] uppercase tracking-wider block mb-2">Type</label>
                  <div className="grid grid-cols-3 gap-1.5">
                    {["all", "manual", "scraped"].map((tp) => (
                      <button
                        key={tp}
                        onClick={() => setTypeFilter(tp)}
                        className={`px-2.5 py-1.5 rounded-lg text-xs font-medium capitalize text-center transition-all ${
                          typeFilter === tp ? "bg-[#b3ff00] text-black font-bold" : "bg-[#141414] text-[#a1a1aa] hover:text-white"
                        }`}
                      >
                        {tp}
                      </button>
                    ))}
                  </div>
                </div>

                <div className="flex items-center justify-between pt-2 border-t border-[#2A2A2A]">
                  <button
                    onClick={() => { setStatusFilter("all"); setTypeFilter("all"); }}
                    className="text-xs text-[#a1a1aa] hover:text-white"
                  >
                    Reset All
                  </button>
                  <button
                    onClick={() => setIsFilterOpen(false)}
                    className="bg-[#b3ff00] text-black px-3.5 py-1 rounded-lg text-xs font-bold hover:bg-[#a2e600]"
                  >
                    Apply
                  </button>
                </div>
              </div>
            )}
          </div>
        </div>

        {/* --- BULK ACTION TOOLBAR --- */}
        {selectedGigIds.length > 0 && (
          <div className="flex flex-wrap items-center justify-between gap-4 bg-[#1a2110] border border-[#b3ff00]/40 rounded-xl px-5 py-3.5 shadow-2xl animate-in slide-in-from-top-2">
            <div className="flex items-center gap-3">
              <div className="w-8 h-8 rounded-lg bg-[#b3ff00] flex items-center justify-center text-black font-extrabold text-sm shadow">
                {selectedGigIds.length}
              </div>
              <span className="text-white font-medium text-sm">
                {selectedGigIds.length} of {filteredGigs.length} gig{selectedGigIds.length > 1 ? "s" : ""} selected
              </span>
              <button
                onClick={handleToggleSelectAll}
                className="text-[#b3ff00] hover:underline text-xs font-bold ml-2"
              >
                {isAllSelected ? "Deselect All" : `Select All (${filteredGigs.length})`}
              </button>
            </div>

            <div className="flex items-center gap-2">
              <button
                onClick={() => handleBulkStatus("open")}
                disabled={bulkActionLoading}
                className="flex items-center gap-1.5 bg-[#10b981]/20 hover:bg-[#10b981]/30 text-[#10b981] border border-[#10b981]/40 px-3 py-1.5 rounded-lg text-xs font-bold transition-all disabled:opacity-50"
              >
                <CheckCircle2 className="w-3.5 h-3.5" />
                Approve
              </button>
              <button
                onClick={() => handleBulkStatus("flagged")}
                disabled={bulkActionLoading}
                className="flex items-center gap-1.5 bg-[#f59e0b]/20 hover:bg-[#f59e0b]/30 text-[#f59e0b] border border-[#f59e0b]/40 px-3 py-1.5 rounded-lg text-xs font-bold transition-all disabled:opacity-50"
              >
                <Flag className="w-3.5 h-3.5" />
                Flag
              </button>
              <button
                onClick={() => setBulkDeleteModalOpen(true)}
                disabled={bulkActionLoading}
                className="flex items-center gap-1.5 bg-[#ef4444]/20 hover:bg-[#ef4444]/30 text-[#ef4444] border border-[#ef4444]/40 px-3.5 py-1.5 rounded-lg text-xs font-bold transition-all disabled:opacity-50"
              >
                {bulkActionLoading ? <Loader2 className="w-3.5 h-3.5 animate-spin" /> : <Trash2 className="w-3.5 h-3.5" />}
                Delete Selected ({selectedGigIds.length})
              </button>
              <button
                onClick={() => setSelectedGigIds([])}
                className="text-[#a1a1aa] hover:text-white p-1.5 rounded-lg hover:bg-white/5 transition-all ml-1"
                title="Clear Selection"
              >
                <X className="w-4 h-4" />
              </button>
            </div>
          </div>
        )}

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
                  <th className="w-12 px-4 py-5 text-center">
                    <input
                      type="checkbox"
                      checked={isAllSelected}
                      ref={input => {
                        if (input) input.indeterminate = isPartiallySelected;
                      }}
                      onChange={handleToggleSelectAll}
                      className="w-4 h-4 rounded border-[#3A3A3A] bg-[#141414] text-[#b3ff00] accent-[#b3ff00] cursor-pointer"
                      title="Select all gigs"
                    />
                  </th>
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
                {filteredGigs.map((gig) => {
                  const isSelected = selectedGigIds.includes(gig.id);
                  return (
                    <tr 
                      key={gig.id} 
                      className={`transition-colors group ${isSelected ? "bg-[#b3ff00]/[0.04]" : "hover:bg-white/[0.02]"}`}
                    >
                      <td className="w-12 px-4 py-5 text-center">
                        <input
                          type="checkbox"
                          checked={isSelected}
                          onChange={() => handleToggleSelect(gig.id)}
                          className="w-4 h-4 rounded border-[#3A3A3A] bg-[#141414] text-[#b3ff00] accent-[#b3ff00] cursor-pointer"
                        />
                      </td>
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
                        <span className={`px-3 py-1 rounded-full text-[12px] font-bold ${
                          gig.status === 'active' || gig.status === 'open'
                            ? 'bg-[#10b981]/10 text-[#10b981]'
                            : gig.status === 'pending'
                              ? 'bg-[#f59e0b]/10 text-[#f59e0b]'
                              : gig.status === 'expired'
                                ? 'bg-white/5 text-[#a1a1aa]'
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
                  );
                })}
              </tbody>
            </table>

            {filteredGigs.length === 0 && (
              <div className="p-16 text-center">
                <div className="w-16 h-16 bg-[#1a1a1e] rounded-full flex items-center justify-center mx-auto mb-4">
                  <Briefcase className="w-8 h-8 text-[#52525b]" />
                </div>
                <p className="text-[#a1a1aa] text-[16px] font-medium">No gigs found matching your selection.</p>
                {hasActiveFilters && (
                  <button
                    onClick={() => { setStatusFilter("all"); setTypeFilter("all"); setSearchQuery(""); }}
                    className="mt-3 text-[#b3ff00] text-sm hover:underline font-semibold"
                  >
                    Clear All Filters
                  </button>
                )}
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

      {/* --- SINGLE GIG DELETE MODAL --- */}
      <ConfirmationModal 
        isOpen={deleteModal.show}
        onClose={() => setDeleteModal({ show: false, gigId: null })}
        onConfirm={confirmDelete}
        title="Delete Gig?"
        description="This action cannot be undone. The gig will be permanently deleted from the platform."
        cancelLabel="Cancel"
        confirmLabel="Delete Gig"
      />

      {/* --- BULK GIG DELETE MODAL --- */}
      <ConfirmationModal 
        isOpen={bulkDeleteModalOpen}
        onClose={() => setBulkDeleteModalOpen(false)}
        onConfirm={handleConfirmBulkDelete}
        title={`Delete ${selectedGigIds.length} Selected Gigs?`}
        description={`Are you sure you want to permanently delete these ${selectedGigIds.length} gigs? All associated applications and data will be removed. This action cannot be undone.`}
        cancelLabel="Cancel"
        confirmLabel={`Delete ${selectedGigIds.length} Gigs`}
        confirmVariant="danger"
      />

      {/* --- REJECT GIG MODAL --- */}
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
