"use client";

import React, { useState, useEffect, useMemo } from "react";
import { 
  Eye, 
  FileText, 
  Download,
  FileCheck,
  Clock,
  Loader2,
  Trash2,
  Search,
  X
} from "lucide-react";
import { ViewContractModal } from "@/components/ui/ViewContractModal";
import { ContractHistoryModal } from "@/components/ui/ContractHistoryModal";
import { ConfirmationModal } from "@/components/ui/ConfirmationModal";
import { Toast } from "@/components/ui/Toast";
import { apiRequest, BASE_URL } from "@/lib/api";

// --- Types & Interfaces ---
interface Contract {
  id: string;
  realId: string;
  gigReference: string;
  organizer: string;
  musician: string;
  date: string;
  signatures: string;
  status: "signed" | "pending";
}

export default function ContractsPage() {
  const [activeTab, setActiveTab] = useState("all");
  const [searchQuery, setSearchQuery] = useState("");
  const [isViewModalOpen, setIsViewModalOpen] = useState(false);
  const [isHistoryModalOpen, setIsHistoryModalOpen] = useState(false);
  const [selectedContract, setSelectedContract] = useState<Contract | null>(null);
  const [toast, setToast] = useState({ show: false, message: "" });
  const [isLoading, setIsLoading] = useState(true);
  const [contracts, setContracts] = useState<Contract[]>([]);

  // Selection & Delete States
  const [selectedContractIds, setSelectedContractIds] = useState<string[]>([]);
  const [singleDeleteModal, setSingleDeleteModal] = useState<{ show: boolean; contractId: string | null }>({ show: false, contractId: null });
  const [bulkDeleteModalOpen, setBulkDeleteModalOpen] = useState(false);
  const [actionLoading, setActionLoading] = useState(false);

  const fetchContracts = async () => {
    setIsLoading(true);
    try {
      const data = await apiRequest("/bookings/list");
      const mappedContracts: Contract[] = (Array.isArray(data) ? data : []).map((item: any) => {
        const musicianSigned = !!item.musicianSignedAt;
        const organizerSigned = !!item.organizerSignedAt;
        const signaturesCount = (musicianSigned ? 1 : 0) + (organizerSigned ? 1 : 0);
        
        return {
          id: item.id.substring(0, 8).toUpperCase(),
          realId: item.id,
          gigReference: item.gigTitle || "Untitled Gig",
          organizer: item.organizerName || "Unknown Organizer",
          musician: item.musicianName || "Unknown Musician",
          date: item.createdAt ? new Date(item.createdAt).toLocaleDateString() : "N/A",
          signatures: `${signaturesCount}/2`,
          status: signaturesCount === 2 ? "signed" : "pending"
        };
      });
      setContracts(mappedContracts);
      setSelectedContractIds([]);
    } catch (err) {
      console.error("Failed to fetch contracts", err);
      setToast({ show: true, message: "Failed to load contracts" });
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchContracts();
  }, []);

  // --- Handlers ---
  const handleViewContract = (contract: Contract) => {
    setSelectedContract(contract);
    setIsViewModalOpen(true);
  };

  const handleViewHistory = (contract: Contract) => {
    setSelectedContract(contract);
    setIsHistoryModalOpen(true);
  };

  const handleDownload = async (contractId: string) => {
    const contract = contracts.find(c => c.id === contractId);
    if (!contract) return;

    setToast({ show: true, message: `Generating PDF for ${contractId}...` });
    
    try {
      const downloadUrl = `${BASE_URL}/bookings/${contract.realId}/download-contract`;
      window.open(downloadUrl, '_blank');
      setToast({ show: true, message: "Download started" });
    } catch (err) {
      console.error("Download failed", err);
      setToast({ show: true, message: "Download failed" });
    }
  };

  // --- Delete Handlers ---
  const handleConfirmSingleDelete = async () => {
    if (singleDeleteModal.contractId) {
      try {
        setActionLoading(true);
        await apiRequest(`/bookings/${singleDeleteModal.contractId}`, { method: "DELETE" });
        setContracts(prev => prev.filter(c => c.realId !== singleDeleteModal.contractId));
        setSelectedContractIds(prev => prev.filter(id => id !== singleDeleteModal.contractId));
        setSingleDeleteModal({ show: false, contractId: null });
        setToast({ show: true, message: "Contract deleted successfully" });
      } catch (err: any) {
        setToast({ show: true, message: "Error deleting contract: " + err.message });
      } finally {
        setActionLoading(false);
      }
    }
  };

  const handleConfirmBulkDelete = async () => {
    if (selectedContractIds.length === 0) return;
    try {
      setActionLoading(true);
      const res = await apiRequest("/bookings/bulk-delete", {
        method: "POST",
        body: JSON.stringify({ bookingIds: selectedContractIds })
      });
      const count = res?.deletedCount ?? selectedContractIds.length;
      setContracts(prev => prev.filter(c => !selectedContractIds.includes(c.realId)));
      setSelectedContractIds([]);
      setBulkDeleteModalOpen(false);
      setToast({ show: true, message: `Deleted ${count} contracts successfully` });
    } catch (err: any) {
      setToast({ show: true, message: "Error deleting contracts: " + err.message });
    } finally {
      setActionLoading(false);
    }
  };

  // --- Filtering Logic ---
  const filteredContracts = useMemo(() => {
    return contracts.filter(contract => {
      const matchesTab = activeTab === "all" || contract.status === activeTab;
      const q = searchQuery.toLowerCase();
      const matchesSearch = !q ||
        contract.gigReference.toLowerCase().includes(q) ||
        contract.organizer.toLowerCase().includes(q) ||
        contract.musician.toLowerCase().includes(q) ||
        contract.id.toLowerCase().includes(q);
      return matchesTab && matchesSearch;
    });
  }, [activeTab, contracts, searchQuery]);

  // --- Selection Logic ---
  const isAllSelected = filteredContracts.length > 0 && filteredContracts.every(c => selectedContractIds.includes(c.realId));
  const isPartiallySelected = selectedContractIds.length > 0 && !isAllSelected;

  const handleToggleSelectAll = () => {
    if (isAllSelected) {
      const currentIds = new Set(filteredContracts.map(c => c.realId));
      setSelectedContractIds(prev => prev.filter(id => !currentIds.has(id)));
    } else {
      const newIds = Array.from(new Set([...selectedContractIds, ...filteredContracts.map(c => c.realId)]));
      setSelectedContractIds(newIds);
    }
  };

  const handleToggleSelect = (realId: string) => {
    setSelectedContractIds(prev =>
      prev.includes(realId) ? prev.filter(id => id !== realId) : [...prev, realId]
    );
  };

  // --- Stats Calculation ---
  const stats = useMemo(() => ({
    all: contracts.length,
    signed: contracts.filter(c => c.status === "signed").length,
    pending: contracts.filter(c => c.status === "pending").length
  }), [contracts]);

  // --- UI Configuration Arrays ---
  const tabConfigs = [
    { id: "all", label: "All Contracts", count: stats.all },
    { id: "signed", label: "Signed", count: stats.signed },
    { id: "pending", label: "Pending Signatures", count: stats.pending }
  ];

  const statCards = [
    { 
      label: "Total Contracts", 
      value: stats.all, 
      icon: FileText, 
      color: "emerald",
      bg: "bg-emerald-950/30",
      border: "border-emerald-900/30",
      iconColor: "text-emerald-500"
    },
    { 
      label: "Fully Signed", 
      value: stats.signed, 
      icon: FileCheck, 
      color: "neon",
      bg: "bg-[#A2F301]/10",
      border: "border-[#A2F301]/20",
      iconColor: "text-[#A2F301]"
    },
    { 
      label: "Awaiting Signature", 
      value: stats.pending, 
      icon: Clock, 
      color: "amber",
      bg: "bg-[#F59E0B]/10",
      border: "border-[#F59E0B]/20",
      iconColor: "text-[#F59E0B]"
    }
  ];

  return (
    <div className="w-full pb-20 relative">
      {isLoading && (
        <div className="fixed inset-0 bg-black/20 backdrop-blur-[2px] z-50 flex items-center justify-center pointer-events-none">
          <Loader2 className="w-10 h-10 text-[#A2F301] animate-spin" />
        </div>
      )}
      {/* Header Section */}
      <div className="mb-8">
        <h1 className="text-2xl sm:text-[30px] font-bold text-white leading-tight mb-1">Contract Management</h1>
        <p className="text-[#999999] text-sm sm:text-[16px]">View and manage gig contracts and e-signatures</p>
      </div>

      {/* Tabs Section */}
      <div className="flex gap-4 sm:gap-8 border-b border-[#2A2A2A] mb-6 overflow-x-auto custom-scrollbar whitespace-nowrap">
        {tabConfigs.map((tab) => (
          <button
            key={tab.id}
            onClick={() => {
              setActiveTab(tab.id);
              setSelectedContractIds([]);
            }}
            className={`pb-4 text-[14px] font-medium transition-all relative ${
              activeTab === tab.id ? "text-[#A2F301]" : "text-[#999999] hover:text-white"
            }`}
          >
            {tab.label} ({tab.count})
            {activeTab === tab.id && (
              <div className="absolute bottom-0 left-0 right-0 h-[2px] bg-[#A2F301]" />
            )}
          </button>
        ))}
      </div>

      {/* Search Bar */}
      <div className="mb-6 max-w-md relative group">
        <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-[#a1a1aa] group-focus-within:text-[#A2F301] transition-colors" />
        <input 
          type="text" 
          placeholder="Search contracts by gig, organizer, musician..."
          className="w-full bg-[#1A1A1A] border border-[#2A2A2A] rounded-xl py-3 pl-11 pr-4 text-[14px] text-white focus:outline-none focus:border-[#A2F301]/50 transition-all shadow-lg"
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
        />
      </div>

      {/* Bulk Action Bar */}
      {selectedContractIds.length > 0 && (
        <div className="mb-6 flex flex-wrap items-center justify-between gap-4 bg-[#1a2110] border border-[#A2F301]/40 rounded-xl px-5 py-3.5 shadow-2xl animate-in slide-in-from-top-2">
          <div className="flex items-center gap-3">
            <div className="w-8 h-8 rounded-lg bg-[#A2F301] flex items-center justify-center text-black font-extrabold text-sm shadow">
              {selectedContractIds.length}
            </div>
            <span className="text-white font-medium text-sm">
              {selectedContractIds.length} of {filteredContracts.length} contracts selected
            </span>
            <button
              onClick={handleToggleSelectAll}
              className="text-[#A2F301] hover:underline text-xs font-bold ml-2"
            >
              {isAllSelected ? "Deselect All" : `Select All (${filteredContracts.length})`}
            </button>
          </div>

          <div className="flex items-center gap-2">
            <button
              onClick={() => setBulkDeleteModalOpen(true)}
              disabled={actionLoading}
              className="flex items-center gap-1.5 bg-[#ef4444]/20 hover:bg-[#ef4444]/30 text-[#ef4444] border border-[#ef4444]/40 px-3.5 py-1.5 rounded-lg text-xs font-bold transition-all disabled:opacity-50"
            >
              {actionLoading ? <Loader2 className="w-3.5 h-3.5 animate-spin" /> : <Trash2 className="w-3.5 h-3.5" />}
              Delete Selected ({selectedContractIds.length})
            </button>
            <button
              onClick={() => setSelectedContractIds([])}
              className="text-[#a1a1aa] hover:text-white p-1.5 rounded-lg hover:bg-white/5 transition-all ml-1"
              title="Clear Selection"
            >
              <X className="w-4 h-4" />
            </button>
          </div>
        </div>
      )}

      {/* Contracts Table Container */}
      <div className="bg-[#1A1A1A] border border-[#2A2A2A] rounded-[8px] overflow-hidden mb-8 shadow-2xl">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="border-b border-[#2A2A2A] bg-[#262626]">
                <th className="w-12 px-4 py-5 text-center">
                  <input
                    type="checkbox"
                    checked={isAllSelected}
                    ref={input => {
                      if (input) input.indeterminate = isPartiallySelected;
                    }}
                    onChange={handleToggleSelectAll}
                    className="w-4 h-4 rounded border-[#3A3A3A] bg-[#141414] text-[#A2F301] accent-[#A2F301] cursor-pointer"
                    title="Select all contracts"
                  />
                </th>
                <th className="px-6 py-5 text-[14px] font-semibold text-[#999999] whitespace-nowrap">Contract ID</th>
                <th className="px-6 py-5 text-[14px] font-semibold text-[#999999] whitespace-nowrap">Gig Reference</th>
                <th className="px-6 py-5 text-[14px] font-semibold text-[#999999] whitespace-nowrap">Organizer</th>
                <th className="px-6 py-5 text-[14px] font-semibold text-[#999999] whitespace-nowrap">Musician</th>
                <th className="px-6 py-5 text-[14px] font-semibold text-[#999999] whitespace-nowrap">Contract Date</th>
                <th className="px-6 py-5 text-[14px] font-semibold text-[#999999] whitespace-nowrap">Signatures</th>
                <th className="px-6 py-5 text-[14px] font-semibold text-[#999999] whitespace-nowrap">Status</th>
                <th className="px-6 py-5 text-[14px] font-semibold text-[#999999] whitespace-nowrap">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#2A2A2A]">
              {filteredContracts.map((contract) => {
                const isSelected = selectedContractIds.includes(contract.realId);
                return (
                  <tr 
                    key={contract.realId} 
                    className={`transition-all group animate-in fade-in duration-300 ${isSelected ? "bg-[#A2F301]/[0.04]" : "hover:bg-white/[0.02]"}`}
                  >
                    <td className="w-12 px-4 py-4 text-center">
                      <input
                        type="checkbox"
                        checked={isSelected}
                        onChange={() => handleToggleSelect(contract.realId)}
                        className="w-4 h-4 rounded border-[#3A3A3A] bg-[#141414] text-[#A2F301] accent-[#A2F301] cursor-pointer"
                      />
                    </td>
                    <td className="px-6 py-4">
                      <span className="text-[#A2F301] text-[14px] font-medium">{contract.id}</span>
                    </td>
                    <td className="px-6 py-4">
                      <span className="text-white text-[14px]">{contract.gigReference}</span>
                    </td>
                    <td className="px-6 py-4 text-[#999999] text-[14px]">{contract.organizer}</td>
                    <td className="px-6 py-4 text-[#999999] text-[14px]">{contract.musician}</td>
                    <td className="px-6 py-4 text-[#999999] text-[14px]">{contract.date}</td>
                    <td className="px-6 py-4">
                      <span className="text-white text-[14px] font-bold">{contract.signatures}</span>
                    </td>
                    <td className="px-6 py-4">
                      <div className={`inline-flex items-center px-2 py-0.5 rounded-[4px] text-[12px] font-medium lowercase ${
                        contract.status === "signed" 
                          ? "bg-[#10B981]/10 text-[#10B981]" 
                          : "bg-[#F59E0B]/10 text-[#F59E0B]"
                      }`}>
                        {contract.status}
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-3">
                        <button 
                          onClick={() => handleViewContract(contract)}
                          className="text-[#999999] hover:text-white transition-all p-1 hover:bg-white/5 rounded-md" 
                          title="View Details"
                        >
                          <Eye className="w-[18px] h-[18px]" />
                        </button>
                        <button 
                          onClick={() => handleDownload(contract.id)}
                          className="text-[#999999] hover:text-white transition-all p-1 hover:bg-white/5 rounded-md" 
                          title="Download Contract"
                        >
                          <Download className="w-[18px] h-[18px]" />
                        </button>
                        <button 
                          onClick={() => handleViewHistory(contract)}
                          className="text-[#999999] hover:text-white transition-all p-1 hover:bg-white/5 rounded-md" 
                          title="View History"
                        >
                          <FileText className="w-[18px] h-[18px]" />
                        </button>
                        <button 
                          onClick={() => setSingleDeleteModal({ show: true, contractId: contract.realId })}
                          className="text-[#999999] hover:text-[#ef4444] transition-all p-1 hover:bg-white/5 rounded-md" 
                          title="Delete Contract"
                        >
                          <Trash2 className="w-[18px] h-[18px]" />
                        </button>
                      </div>
                    </td>
                  </tr>
                );
              })}
              {filteredContracts.length === 0 && (
                <tr>
                  <td colSpan={9} className="px-6 py-12 text-center text-[#999999]">
                    No contracts found matching your selection.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Summary Statistics Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
        {statCards.map((card, i) => (
          <div key={i} className="bg-[#1A1A1A] border border-[#2A2A2A] rounded-[8px] p-6 flex items-center gap-4 hover:border-[#A2F301]/30 transition-all cursor-default group shadow-xl">
            <div className={`w-[48px] h-[48px] ${card.bg} rounded-[8px] flex items-center justify-center border ${card.border} group-hover:border-[#A2F301]/50 transition-all shrink-0`}>
              <card.icon className={`w-6 h-6 ${card.iconColor}`} />
            </div>
            <div>
              <p className="text-[#999999] text-[13px] sm:text-[14px] font-medium mb-0.5">{card.label}</p>
              <p className="text-white text-2xl sm:text-[28px] font-bold leading-none">{card.value}</p>
            </div>
          </div>
        ))}
      </div>

      {/* --- Modals & Notifications --- */}
      <ViewContractModal 
        isOpen={isViewModalOpen}
        onClose={() => setIsViewModalOpen(false)}
        contract={selectedContract}
        onDownload={handleDownload}
      />
      
      <ContractHistoryModal 
        isOpen={isHistoryModalOpen}
        onClose={() => setIsHistoryModalOpen(false)}
        contract={selectedContract}
      />

      <ConfirmationModal 
        isOpen={singleDeleteModal.show}
        onClose={() => setSingleDeleteModal({ show: false, contractId: null })}
        onConfirm={handleConfirmSingleDelete}
        title="Delete Contract?"
        description="Are you sure you want to permanently delete this contract booking? This action cannot be undone."
        cancelLabel="Cancel"
        confirmLabel="Delete Contract"
        confirmVariant="danger"
      />

      <ConfirmationModal 
        isOpen={bulkDeleteModalOpen}
        onClose={() => setBulkDeleteModalOpen(false)}
        onConfirm={handleConfirmBulkDelete}
        title={`Delete ${selectedContractIds.length} Selected Contracts?`}
        description={`Are you sure you want to permanently delete these ${selectedContractIds.length} contracts? All booking agreements and signatures will be removed. This cannot be undone.`}
        cancelLabel="Cancel"
        confirmLabel={`Delete ${selectedContractIds.length} Contracts`}
        confirmVariant="danger"
      />

      <Toast 
        show={toast.show}
        message={toast.message}
        onClose={() => setToast({ ...toast, show: false })}
      />
    </div>
  );
}
