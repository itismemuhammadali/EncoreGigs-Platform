"use client";

import React, { useState, useEffect, useMemo } from "react";
import { 
  Eye, 
  FileText, 
  Download,
  FileCheck,
  Clock,
  Loader2
} from "lucide-react";
import { ViewContractModal } from "@/components/ui/ViewContractModal";
import { ContractHistoryModal } from "@/components/ui/ContractHistoryModal";
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
  const [isViewModalOpen, setIsViewModalOpen] = useState(false);
  const [isHistoryModalOpen, setIsHistoryModalOpen] = useState(false);
  const [selectedContract, setSelectedContract] = useState<Contract | null>(null);
  const [toast, setToast] = useState({ show: false, message: "" });
  const [isLoading, setIsLoading] = useState(true);
  const [contracts, setContracts] = useState<Contract[]>([]);

  useEffect(() => {
    const fetchContracts = async () => {
      setIsLoading(true);
      try {
        const data = await apiRequest("/bookings/list");
        const mappedContracts: Contract[] = data.map((item: any) => {
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
      } catch (err) {
        console.error("Failed to fetch contracts", err);
        setToast({ show: true, message: "Failed to load contracts" });
      } finally {
        setIsLoading(false);
      }
    };

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

  // --- Filtering Logic ---
  const filteredContracts = useMemo(() => {
    if (activeTab === "all") return contracts;
    return contracts.filter(contract => contract.status === activeTab);
  }, [activeTab, contracts]);

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

  const tableHeaders = [
    "Contract ID", "Gig Reference", "Organizer", "Musician", 
    "Contract Date", "Signatures", "Status", "Actions"
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
      <div className="flex gap-4 sm:gap-8 border-b border-[#2A2A2A] mb-8 overflow-x-auto custom-scrollbar whitespace-nowrap">
        {tabConfigs.map((tab) => (
          <button
            key={tab.id}
            onClick={() => setActiveTab(tab.id)}
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

      {/* Contracts Table Container */}
      <div className="bg-[#1A1A1A] border border-[#2A2A2A] rounded-[8px] overflow-hidden mb-8 shadow-2xl">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="border-b border-[#2A2A2A] bg-[#262626]">
                {tableHeaders.map((header, i) => (
                  <th key={i} className="px-6 py-5 text-[14px] font-semibold text-[#999999] whitespace-nowrap">
                    {header}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-[#2A2A2A]">
              {filteredContracts.map((contract, index) => (
                <tr key={index} className="hover:bg-white/[0.02] transition-all group animate-in fade-in duration-300">
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
                    </div>
                  </td>
                </tr>
              ))}
              {filteredContracts.length === 0 && (
                <tr>
                  <td colSpan={8} className="px-6 py-12 text-center text-[#999999]">
                    No contracts found in this category.
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

      <Toast 
        show={toast.show}
        message={toast.message}
        onClose={() => setToast({ ...toast, show: false })}
      />
    </div>
  );
}
