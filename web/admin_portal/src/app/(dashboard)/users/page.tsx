"use client";

import React, { useState, useEffect, useMemo, Suspense } from "react";
import { useSearchParams } from "next/navigation";
import {
  Search,
  Filter,
  Eye,
  Trash2,
  Ban,
  Star,
  UserCheck,
  UserX,
  Loader2,
  X,
  Check
} from "lucide-react";
import { Toast } from "@/components/ui/Toast";
import { ConfirmationModal } from "@/components/ui/ConfirmationModal";
import { UserProfileModal } from "@/components/ui/UserProfileModal";
import { apiRequest } from "@/lib/api";

interface Musician {
  id: string;
  fullName: string;
  email: string;
  status: "active" | "inactive" | "suspended" | "pending" | "approved" | "rejected" | "pending_approval" | "denied" | string;
  bookings?: number;
  rating?: number;
  joinedAt?: string;
  createdAt?: any;
}

interface Organizer {
  id: string;
  name: string;
  email: string;
  status: "active" | "suspended" | "pending" | "approved" | "rejected" | "pending_approval" | "denied" | string;
  totalGigs?: number;
  totalSpent?: string;
  joinedAt?: string;
  createdAt?: any;
}

export default function UserManagement() {
  const searchParams = useSearchParams();
  const [activeTab, setActiveTab] = useState<"musicians" | "organizers">("musicians");
  const [searchQuery, setSearchQuery] = useState("");
  const [musicians, setMusicians] = useState<Musician[]>([]);
  const [organizers, setOrganizers] = useState<Organizer[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  // Status Filter States
  const [isFilterOpen, setIsFilterOpen] = useState(false);
  const [statusFilter, setStatusFilter] = useState<string>("all");

  // Selection & Bulk Action States
  const [selectedUserIds, setSelectedUserIds] = useState<string[]>([]);
  const [bulkActionLoading, setBulkActionLoading] = useState(false);
  const [bulkDeleteModalOpen, setBulkDeleteModalOpen] = useState(false);

  useEffect(() => {
    const q = searchParams.get("q") || searchParams.get("search");
    if (q) setSearchQuery(q);
    const tab = searchParams.get("tab");
    if (tab === "organizers" || tab === "musicians") {
      setActiveTab(tab);
    }
  }, [searchParams]);

  // Notifications & Modals
  const [notification, setNotification] = useState<{ show: boolean; message: string }>({ show: false, message: "" });
  const [suspendModal, setSuspendModal] = useState<{ show: boolean; userId: string | null; userType: "musician" | "organizer" | null }>({ show: false, userId: null, userType: null });
  const [viewModal, setViewModal] = useState<{ show: boolean; userData: any | null }>({ show: false, userData: null });

  const fetchData = async () => {
    setIsLoading(true);
    try {
      const [musiciansData, organizersData] = await Promise.all([
        apiRequest("/auth/musicians"),
        apiRequest("/auth/organizers")
      ]);
      setMusicians(Array.isArray(musiciansData) ? musiciansData : []);
      setOrganizers(Array.isArray(organizersData) ? organizersData : []);
      setSelectedUserIds([]);
    } catch (err: any) {
      showNotification("Failed to fetch users: " + err.message);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, []);

  const showNotification = (message: string) => {
    setNotification({ show: true, message });
  };

  const handleStatusUpdate = async (id: string, newStatus: string, type: "musician" | "organizer", email: string) => {
    try {
      showNotification(`Updating ${type} status to ${newStatus}...`);
      await apiRequest("/auth/user/status", {
        method: "POST",
        body: JSON.stringify({ uid: id, status: newStatus, email })
      });
      
      if (type === "musician") {
        setMusicians(prev => prev.map(m => m.id === id ? { ...m, status: newStatus as any } : m));
      } else {
        setOrganizers(prev => prev.map(o => o.id === id ? { ...o, status: newStatus as any } : o));
      }
      
      const actionText = newStatus === "approved" || newStatus === "active" ? "Approved & Email Sent" : newStatus === "rejected" || newStatus === "denied" ? "Rejected & Email Sent" : "Updated";
      showNotification(`User status ${actionText} successfully`);
    } catch (err: any) {
      showNotification("Failed to update status: " + err.message);
    }
  };

  const handleSuspendConfirm = async () => {
    if (suspendModal.userId && suspendModal.userType) {
      const user = suspendModal.userType === "musician" 
        ? musicians.find(m => m.id === suspendModal.userId)
        : organizers.find(o => o.id === suspendModal.userId);
      const email = user?.email || "";
      await handleStatusUpdate(suspendModal.userId, "suspended", suspendModal.userType, email);
      setSuspendModal({ show: false, userId: null, userType: null });
    }
  };

  // --- FILTERING LOGIC ---
  const matchesStatus = (userStatus: string, filter: string) => {
    if (filter === "all") return true;
    const s = (userStatus || "").toLowerCase();
    if (filter === "approved") return s === "approved" || s === "active";
    if (filter === "pending") return s === "pending" || s === "pending_approval";
    if (filter === "suspended") return s === "suspended";
    if (filter === "rejected") return s === "rejected" || s === "denied";
    return s === filter;
  };

  const filteredMusicians = useMemo(() => {
    return musicians.filter(m => {
      const matchesSearch = (m.fullName || "").toLowerCase().includes(searchQuery.toLowerCase()) || 
        (m.email || "").toLowerCase().includes(searchQuery.toLowerCase());
      const matchesSt = matchesStatus(m.status, statusFilter);
      return matchesSearch && matchesSt;
    });
  }, [musicians, searchQuery, statusFilter]);

  const filteredOrganizers = useMemo(() => {
    return organizers.filter(o => {
      const matchesSearch = (o.name || "").toLowerCase().includes(searchQuery.toLowerCase()) || 
        (o.email || "").toLowerCase().includes(searchQuery.toLowerCase());
      const matchesSt = matchesStatus(o.status, statusFilter);
      return matchesSearch && matchesSt;
    });
  }, [organizers, searchQuery, statusFilter]);

  const currentList = activeTab === "musicians" ? filteredMusicians : filteredOrganizers;

  // --- MULTI-SELECT HANDLERS ---
  const isAllSelected = currentList.length > 0 && currentList.every(u => selectedUserIds.includes(u.id));
  const isPartiallySelected = selectedUserIds.length > 0 && !isAllSelected;

  const handleToggleSelectAll = () => {
    if (isAllSelected) {
      const currentIds = new Set(currentList.map(u => u.id));
      setSelectedUserIds(prev => prev.filter(id => !currentIds.has(id)));
    } else {
      const newIds = Array.from(new Set([...selectedUserIds, ...currentList.map(u => u.id)]));
      setSelectedUserIds(newIds);
    }
  };

  const handleToggleSelect = (id: string) => {
    setSelectedUserIds(prev =>
      prev.includes(id) ? prev.filter(item => item !== id) : [...prev, id]
    );
  };

  // --- BULK ACTIONS ---
  const handleBulkStatus = async (status: string) => {
    if (selectedUserIds.length === 0) return;
    try {
      setBulkActionLoading(true);
      const userType = activeTab === "musicians" ? "musician" : "organizer";
      await apiRequest("/auth/users/bulk-status", {
        method: "POST",
        body: JSON.stringify({
          userIds: selectedUserIds,
          status,
          userType
        })
      });

      if (activeTab === "musicians") {
        setMusicians(prev => prev.map(m => selectedUserIds.includes(m.id) ? { ...m, status: status as any } : m));
      } else {
        setOrganizers(prev => prev.map(o => selectedUserIds.includes(o.id) ? { ...o, status: status as any } : o));
      }

      showNotification(`Updated ${selectedUserIds.length} users to ${status}`);
      setSelectedUserIds([]);
    } catch (err: any) {
      showNotification("Failed to update status: " + err.message);
    } finally {
      setBulkActionLoading(false);
    }
  };

  const handleConfirmBulkDelete = async () => {
    if (selectedUserIds.length === 0) return;
    try {
      setBulkActionLoading(true);
      const userType = activeTab === "musicians" ? "musician" : "organizer";
      const res = await apiRequest("/auth/users/bulk-delete", {
        method: "POST",
        body: JSON.stringify({
          userIds: selectedUserIds,
          userType
        })
      });
      const count = res?.deletedCount ?? selectedUserIds.length;

      if (activeTab === "musicians") {
        setMusicians(prev => prev.filter(m => !selectedUserIds.includes(m.id)));
      } else {
        setOrganizers(prev => prev.filter(o => !selectedUserIds.includes(o.id)));
      }

      showNotification(`Deleted ${count} users successfully`);
      setSelectedUserIds([]);
      setBulkDeleteModalOpen(false);
    } catch (err: any) {
      showNotification("Failed to delete users: " + err.message);
    } finally {
      setBulkActionLoading(false);
    }
  };

  const formatDate = (date: any) => {
    if (!date) return "N/A";
    if (typeof date === 'string') {
      return date.includes('T') ? date.split('T')[0] : date;
    }
    if (typeof date === 'object' && date.seconds) {
      return new Date(date.seconds * 1000).toISOString().split('T')[0];
    }
    return "N/A";
  };

  const hasActiveFilters = statusFilter !== "all";

  return (
    <div className="relative min-h-screen">
      <div className="space-y-8 animate-in fade-in duration-700 pb-20">
        {/* --- HEADER --- */}
        <div>
          <h1 className="text-2xl sm:text-[32px] font-bold text-white mb-2">User Management</h1>
          <p className="text-[#a1a1aa] text-sm sm:text-[16px]">Manage musicians, organizers, approvals, and user accounts</p>
        </div>

        {/* --- TABS --- */}
        <div className="flex gap-4 sm:gap-8 border-b border-[#1a1a1e] overflow-x-auto custom-scrollbar whitespace-nowrap">
          <button 
            onClick={() => {
              setActiveTab("musicians");
              setSelectedUserIds([]);
            }}
            className={`pb-4 text-[14px] sm:text-[15px] font-bold transition-all relative ${
              activeTab === "musicians" ? "text-[#b3ff00]" : "text-[#a1a1aa] hover:text-white"
            }`}
          >
            Musicians ({musicians.length})
            {activeTab === "musicians" && <div className="absolute bottom-0 left-0 w-full h-[2px] bg-[#b3ff00]" />}
          </button>
          <button 
            onClick={() => {
              setActiveTab("organizers");
              setSelectedUserIds([]);
            }}
            className={`pb-4 text-[14px] sm:text-[15px] font-bold transition-all relative ${
              activeTab === "organizers" ? "text-[#b3ff00]" : "text-[#a1a1aa] hover:text-white"
            }`}
          >
            Organizers ({organizers.length})
            {activeTab === "organizers" && <div className="absolute bottom-0 left-0 w-full h-[2px] bg-[#b3ff00]" />}
          </button>
        </div>

        {/* --- FILTERS & SEARCH --- */}
        <div className="flex flex-col sm:flex-row gap-4">
          <div className="flex-1 relative group">
            <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-[#a1a1aa] group-focus-within:text-[#b3ff00] transition-colors" />
            <input 
              type="text" 
              placeholder="Search by name or email..."
              className="w-full bg-[#1A1A1A] border border-[#1a1a1e] rounded-xl py-3.5 pl-11 pr-4 text-[14px] text-white focus:outline-none focus:border-[#b3ff00]/50 transition-all shadow-lg"
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
                  <label className="text-xs font-semibold text-[#a1a1aa] uppercase tracking-wider block mb-2">User Status</label>
                  <div className="space-y-1.5">
                    {[
                      { id: "all", label: "All Users" },
                      { id: "approved", label: "Approved / Active" },
                      { id: "pending", label: "Pending Approval" },
                      { id: "suspended", label: "Suspended" },
                      { id: "rejected", label: "Rejected / Denied" }
                    ].map((opt) => (
                      <button
                        key={opt.id}
                        onClick={() => setStatusFilter(opt.id)}
                        className={`w-full px-3 py-2 rounded-lg text-xs font-medium text-left transition-all flex items-center justify-between ${
                          statusFilter === opt.id ? "bg-[#b3ff00] text-black font-bold" : "bg-[#141414] text-[#a1a1aa] hover:text-white"
                        }`}
                      >
                        <span>{opt.label}</span>
                        {statusFilter === opt.id && <Check className="w-3.5 h-3.5 stroke-[3px]" />}
                      </button>
                    ))}
                  </div>
                </div>

                <div className="flex items-center justify-between pt-2 border-t border-[#2A2A2A]">
                  <button
                    onClick={() => setStatusFilter("all")}
                    className="text-xs text-[#a1a1aa] hover:text-white font-medium"
                  >
                    Reset Filter
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

        {/* --- BULK ACTION TOOLBAR FOR USERS --- */}
        {selectedUserIds.length > 0 && (
          <div className="flex flex-wrap items-center justify-between gap-4 bg-[#1a2110] border border-[#b3ff00]/40 rounded-xl px-5 py-3.5 shadow-2xl animate-in slide-in-from-top-2">
            <div className="flex items-center gap-3">
              <div className="w-8 h-8 rounded-lg bg-[#b3ff00] flex items-center justify-center text-black font-extrabold text-sm shadow">
                {selectedUserIds.length}
              </div>
              <span className="text-white font-medium text-sm">
                {selectedUserIds.length} of {currentList.length} {activeTab} selected
              </span>
              <button
                onClick={handleToggleSelectAll}
                className="text-[#b3ff00] hover:underline text-xs font-bold ml-2"
              >
                {isAllSelected ? "Deselect All" : `Select All (${currentList.length})`}
              </button>
            </div>

            <div className="flex items-center gap-2">
              <button
                onClick={() => handleBulkStatus("approved")}
                disabled={bulkActionLoading}
                className="flex items-center gap-1.5 bg-[#10b981]/20 hover:bg-[#10b981]/30 text-[#10b981] border border-[#10b981]/40 px-3 py-1.5 rounded-lg text-xs font-bold transition-all disabled:opacity-50"
              >
                <UserCheck className="w-3.5 h-3.5" />
                Approve
              </button>
              <button
                onClick={() => handleBulkStatus("suspended")}
                disabled={bulkActionLoading}
                className="flex items-center gap-1.5 bg-[#f59e0b]/20 hover:bg-[#f59e0b]/30 text-[#f59e0b] border border-[#f59e0b]/40 px-3 py-1.5 rounded-lg text-xs font-bold transition-all disabled:opacity-50"
              >
                <Ban className="w-3.5 h-3.5" />
                Suspend
              </button>
              <button
                onClick={() => handleBulkStatus("rejected")}
                disabled={bulkActionLoading}
                className="flex items-center gap-1.5 bg-[#ef4444]/20 hover:bg-[#ef4444]/30 text-[#ef4444] border border-[#ef4444]/40 px-3 py-1.5 rounded-lg text-xs font-bold transition-all disabled:opacity-50"
              >
                <UserX className="w-3.5 h-3.5" />
                Reject
              </button>
              <button
                onClick={() => setBulkDeleteModalOpen(true)}
                disabled={bulkActionLoading}
                className="flex items-center gap-1.5 bg-[#ef4444]/20 hover:bg-[#ef4444]/30 text-[#ef4444] border border-[#ef4444]/40 px-3.5 py-1.5 rounded-lg text-xs font-bold transition-all disabled:opacity-50"
              >
                {bulkActionLoading ? <Loader2 className="w-3.5 h-3.5 animate-spin" /> : <Trash2 className="w-3.5 h-3.5" />}
                Delete Selected ({selectedUserIds.length})
              </button>
              <button
                onClick={() => setSelectedUserIds([])}
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
                      title="Select all visible users"
                    />
                  </th>
                  <th className="px-6 py-5 text-[14px] font-medium text-[#a1a1aa]">Name</th>
                  <th className="px-6 py-5 text-[14px] font-medium text-[#a1a1aa]">Email</th>
                  <th className="px-6 py-5 text-[14px] font-medium text-[#a1a1aa]">Status</th>
                  {activeTab === "musicians" ? (
                    <>
                      <th className="px-6 py-5 text-[14px] font-medium text-[#a1a1aa]">Bookings</th>
                      <th className="px-6 py-5 text-[14px] font-medium text-[#a1a1aa]">Rating</th>
                    </>
                  ) : (
                    <>
                      <th className="px-6 py-5 text-[14px] font-medium text-[#a1a1aa]">Total Gigs</th>
                      <th className="px-6 py-5 text-[14px] font-medium text-[#a1a1aa]">Total Spent</th>
                    </>
                  )}
                  <th className="px-6 py-5 text-[14px] font-medium text-[#a1a1aa]">Joined</th>
                  <th className="px-6 py-5 text-[14px] font-medium text-[#a1a1aa]">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-[#1a1a1e]">
                {activeTab === "musicians" ? (
                  filteredMusicians.length > 0 ? (
                    filteredMusicians.map((musician) => {
                      const isSelected = selectedUserIds.includes(musician.id);
                      return (
                        <tr 
                          key={musician.id} 
                          className={`transition-colors group ${isSelected ? "bg-[#b3ff00]/[0.04]" : "hover:bg-white/[0.02]"}`}
                        >
                          <td className="w-12 px-4 py-5 text-center">
                            <input
                              type="checkbox"
                              checked={isSelected}
                              onChange={() => handleToggleSelect(musician.id)}
                              className="w-4 h-4 rounded border-[#3A3A3A] bg-[#141414] text-[#b3ff00] accent-[#b3ff00] cursor-pointer"
                            />
                          </td>
                          <td className="px-6 py-5">
                            <span className="text-white font-bold text-[15px] group-hover:text-[#b3ff00] transition-colors">{musician.fullName}</span>
                          </td>
                          <td className="px-6 py-5">
                            <span className="text-[#a1a1aa] text-[14px] font-medium">{musician.email}</span>
                          </td>
                          <td className="px-6 py-5">
                            <span className={`px-3 py-1 rounded-full text-[12px] font-bold ${
                              musician.status === 'active' || musician.status === 'approved' ? 'bg-[#10b981]/10 text-[#10b981]' :
                              musician.status === 'pending' || musician.status === 'pending_approval' ? 'bg-[#f59e0b]/10 text-[#f59e0b]' :
                              'bg-[#ef4444]/10 text-[#ef4444]'
                            }`}>
                              {musician.status === 'pending' || musician.status === 'pending_approval' ? 'Pending Approval' : musician.status}
                            </span>
                          </td>
                          <td className="px-6 py-5 text-white text-[14px] font-medium opacity-80">{musician.bookings || 0}</td>
                          <td className="px-6 py-5">
                            <div className="flex items-center gap-1">
                              <Star className="w-3.5 h-3.5 text-[#f59e0b] fill-[#f59e0b]" />
                              <span className="text-white text-[14px] font-bold">{musician.rating || "0.0"}</span>
                            </div>
                          </td>
                          <td className="px-6 py-5 text-[#a1a1aa] text-[14px] font-medium">{formatDate(musician.joinedAt || musician.createdAt)}</td>
                          <td className="px-6 py-5">
                            <div className="flex items-center gap-3">
                              <button onClick={() => setViewModal({ show: true, userData: musician })} title="View Profile" className="text-white/70 hover:text-white hover:scale-110 transition-all"><Eye className="w-[18px] h-[18px]" /></button>
                              
                              <button 
                                onClick={() => handleStatusUpdate(musician.id, "approved", "musician", musician.email)} 
                                title="Approve User & Send Email"
                                className="text-[#10b981] hover:text-[#10b981]/80 hover:scale-110 transition-all"
                              >
                                <UserCheck className="w-[18px] h-[18px]" />
                              </button>

                              <button 
                                onClick={() => handleStatusUpdate(musician.id, "rejected", "musician", musician.email)} 
                                title="Reject User & Send Email"
                                className="text-[#ef4444] hover:text-[#ef4444]/80 hover:scale-110 transition-all"
                              >
                                <UserX className="w-[18px] h-[18px]" />
                              </button>

                              <button onClick={() => setSuspendModal({ show: true, userId: musician.id, userType: "musician" })} title="Suspend User" className="text-[#f59e0b] hover:text-[#f59e0b]/80 hover:scale-110 transition-all"><Ban className="w-[18px] h-[18px]" /></button>
                            </div>
                          </td>
                        </tr>
                      );
                    })
                  ) : !isLoading && (
                    <tr>
                      <td colSpan={8} className="px-6 py-10 text-center text-[#a1a1aa]">No musicians found matching selection</td>
                    </tr>
                  )
                ) : (
                  filteredOrganizers.length > 0 ? (
                    filteredOrganizers.map((organizer) => {
                      const isSelected = selectedUserIds.includes(organizer.id);
                      return (
                        <tr 
                          key={organizer.id} 
                          className={`transition-colors group ${isSelected ? "bg-[#b3ff00]/[0.04]" : "hover:bg-white/[0.02]"}`}
                        >
                          <td className="w-12 px-4 py-5 text-center">
                            <input
                              type="checkbox"
                              checked={isSelected}
                              onChange={() => handleToggleSelect(organizer.id)}
                              className="w-4 h-4 rounded border-[#3A3A3A] bg-[#141414] text-[#b3ff00] accent-[#b3ff00] cursor-pointer"
                            />
                          </td>
                          <td className="px-6 py-5">
                            <span className="text-white font-bold text-[15px] group-hover:text-[#b3ff00] transition-colors">{organizer.name}</span>
                          </td>
                          <td className="px-6 py-5">
                            <span className="text-[#a1a1aa] text-[14px] font-medium">{organizer.email}</span>
                          </td>
                          <td className="px-6 py-5">
                            <span className={`px-3 py-1 rounded-full text-[12px] font-bold ${
                              organizer.status === 'active' || organizer.status === 'approved' ? 'bg-[#10b981]/10 text-[#10b981]' :
                              organizer.status === 'pending' || organizer.status === 'pending_approval' ? 'bg-[#f59e0b]/10 text-[#f59e0b]' :
                              'bg-[#ef4444]/10 text-[#ef4444]'
                            }`}>
                              {organizer.status === 'pending' || organizer.status === 'pending_approval' ? 'Pending Approval' : organizer.status}
                            </span>
                          </td>
                          <td className="px-6 py-5 text-white text-[14px] font-medium opacity-80">{organizer.totalGigs || 0}</td>
                          <td className="px-6 py-5">
                            <span className="text-[#b3ff00] text-[15px] font-bold">{organizer.totalSpent || "$0"}</span>
                          </td>
                          <td className="px-6 py-5 text-[#a1a1aa] text-[14px] font-medium">{formatDate(organizer.joinedAt || organizer.createdAt)}</td>
                          <td className="px-6 py-5">
                            <div className="flex items-center gap-3">
                              <button onClick={() => setViewModal({ show: true, userData: organizer })} title="View Profile" className="text-white/70 hover:text-white hover:scale-110 transition-all"><Eye className="w-[18px] h-[18px]" /></button>
                              
                              <button 
                                onClick={() => handleStatusUpdate(organizer.id, "approved", "organizer", organizer.email)} 
                                title="Approve User & Send Email"
                                className="text-[#10b981] hover:text-[#10b981]/80 hover:scale-110 transition-all"
                              >
                                <UserCheck className="w-[18px] h-[18px]" />
                              </button>

                              <button 
                                onClick={() => handleStatusUpdate(organizer.id, "rejected", "organizer", organizer.email)} 
                                title="Reject User & Send Email"
                                className="text-[#ef4444] hover:text-[#ef4444]/80 hover:scale-110 transition-all"
                              >
                                <UserX className="w-[18px] h-[18px]" />
                              </button>

                              <button onClick={() => setSuspendModal({ show: true, userId: organizer.id, userType: "organizer" })} title="Suspend User" className="text-[#f59e0b] hover:text-[#f59e0b]/80 hover:scale-110 transition-all"><Ban className="w-[18px] h-[18px]" /></button>
                            </div>
                          </td>
                        </tr>
                      );
                    })
                  ) : !isLoading && (
                    <tr>
                      <td colSpan={8} className="px-6 py-10 text-center text-[#a1a1aa]">No organizers found matching selection</td>
                    </tr>
                  )
                )}
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <Toast show={notification.show} message={notification.message} onClose={() => setNotification({ show: false, message: "" })} />
      <UserProfileModal isOpen={viewModal.show} onClose={() => setViewModal({ show: false, userData: null })} userData={viewModal.userData} />
      
      {/* --- SINGLE SUSPEND MODAL --- */}
      <ConfirmationModal 
        isOpen={suspendModal.show}
        onClose={() => setSuspendModal({ show: false, userId: null, userType: null })}
        onConfirm={handleSuspendConfirm}
        title="Suspend User?"
        description="This user will be suspended and unable to access the platform."
        cancelLabel="Cancel"
        confirmLabel="Suspend"
        confirmVariant="warning"
      />

      {/* --- BULK USER DELETE MODAL --- */}
      <ConfirmationModal 
        isOpen={bulkDeleteModalOpen}
        onClose={() => setBulkDeleteModalOpen(false)}
        onConfirm={handleConfirmBulkDelete}
        title={`Delete ${selectedUserIds.length} Selected Users?`}
        description={`Are you sure you want to permanently delete these ${selectedUserIds.length} user accounts? Their profile data and records will be deleted. This cannot be undone.`}
        cancelLabel="Cancel"
        confirmLabel={`Delete ${selectedUserIds.length} Users`}
        confirmVariant="danger"
      />
    </div>
  );
}
