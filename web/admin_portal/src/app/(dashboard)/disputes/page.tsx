"use client";

import React, { useState, useMemo } from "react";
import { 
  AlertCircle, 
  CheckCircle2, 
  Flag, 
  UserX, 
  CheckCircle,
  Clock,
  Paperclip,
  ShieldAlert
} from "lucide-react";
import { Toast } from "@/components/ui/Toast";
import { SendWarningModal } from "@/components/ui/SendWarningModal";
import { SuspendUserModal } from "@/components/ui/SuspendUserModal";

// --- Types & Interfaces ---
interface Dispute {
  id: string;
  priority: "high" | "critical" | "medium" | "low";
  status: "open" | "resolved";
  gigReference: string;
  filedDate: string;
  organizer: string;
  musician: string;
  reason: string;
  evidenceLink: string;
  description: string;
}

// --- Mock Data ---
// BACKEND DEVELOPER: Replace this mock array with a fetch call to your disputes endpoint.
const MOCK_DISPUTES: Dispute[] = [
  {
    id: "DSP-001",
    priority: "high",
    status: "open",
    gigReference: "Jazz Night at Blue Note",
    filedDate: "2026-02-16",
    organizer: "Metro Events LLC",
    musician: "Sarah Johnson",
    reason: "Payment delay",
    evidenceLink: "Contract_proof.pdf",
    description: "Payment was not released 24 hours after gig completion as agreed."
  },
  {
    id: "DSP-002",
    priority: "critical",
    status: "open",
    gigReference: "Rock Concert",
    filedDate: "2026-02-15",
    organizer: "Blue Note Jazz Club",
    musician: "Mike Peterson",
    reason: "No show",
    evidenceLink: "Venue_confirmation.jpg",
    description: "Musician did not show up to the venue on the scheduled date."
  },
  {
    id: "DSP-003",
    priority: "medium",
    status: "resolved",
    gigReference: "Wedding Reception",
    filedDate: "2026-02-10",
    organizer: "City Sound Productions",
    musician: "Lisa Anderson",
    reason: "Quality of service",
    evidenceLink: "Video_recording.mp4",
    description: "Performance quality was below expectations based on profile."
  },
  {
    id: "DSP-004",
    priority: "high",
    status: "resolved",
    gigReference: "Corporate Event",
    filedDate: "2026-02-08",
    organizer: "Metro Events LLC",
    musician: "David Chen",
    reason: "Contract breach",
    evidenceLink: "Email_thread.pdf",
    description: "Organizer changed gig details without mutual agreement."
  }
];

export default function DisputesPage() {
  // BACKEND DEVELOPER: Initialize this with data from your API.
  // Consider using React Query or a similar library for data fetching.
  const [disputes, setDisputes] = useState<Dispute[]>(MOCK_DISPUTES);
  const [activeTab, setActiveTab] = useState<"open" | "resolved">("open");
  const [toast, setToast] = useState({ show: false, message: "" });
  
  const [isWarningModalOpen, setIsWarningModalOpen] = useState(false);
  const [isSuspendModalOpen, setIsSuspendModalOpen] = useState(false);
  const [selectedDisputeId, setSelectedDisputeId] = useState<string | null>(null);

  // --- Handlers ---
  const handleAction = (id: string, action: string) => {
    if (action === "Send Warning") {
      setSelectedDisputeId(id);
      setIsWarningModalOpen(true);
      return;
    }

    if (action === "Suspend User") {
      setSelectedDisputeId(id);
      setIsSuspendModalOpen(true);
      return;
    }

    // BACKEND DEVELOPER: Implement dispute actions via API.
    // e.g., await api.post(`/disputes/${id}/action`, { actionType: action });
    setToast({ show: true, message: `Dispute ${id} closed successfully.` });
    
    if (action === "Close Dispute") {
      setDisputes(prev => prev.map(d => 
        d.id === id ? { ...d, status: "resolved" } : d
      ));
    }
  };

  const confirmWarning = () => {
    // BACKEND DEVELOPER: Implement warning logic via API.
    setToast({ show: true, message: `Warning sent for Dispute ${selectedDisputeId}.` });
    setIsWarningModalOpen(false);
    setSelectedDisputeId(null);
  };

  const confirmSuspend = () => {
    // BACKEND DEVELOPER: Implement suspension logic via API.
    setToast({ show: true, message: `User suspended for Dispute ${selectedDisputeId}.` });
    setIsSuspendModalOpen(false);
    setSelectedDisputeId(null);
  };

  // --- Filtering Logic ---
  const filteredDisputes = useMemo(() => {
    return disputes.filter(d => d.status === activeTab);
  }, [activeTab, disputes]);

  // --- Stats Calculation ---
  const stats = {
    open: disputes.filter(d => d.status === "open").length,
    resolved: disputes.filter(d => d.status === "resolved").length,
    critical: disputes.filter(d => d.priority === "critical" && d.status === "open").length,
    rate: "87%"
  };

  // --- UI Configuration Arrays ---
  const statCards = [
    { label: "Open Disputes", value: stats.open, icon: Clock, color: "text-[#F59E0B]", bg: "bg-[#F59E0B]/10", border: "border-[#F59E0B]/20" },
    { label: "Resolved", value: stats.resolved, icon: CheckCircle2, color: "text-[#10B981]", bg: "bg-[#10B981]/10", border: "border-[#10B981]/20" },
    { label: "Critical Priority", value: stats.critical, icon: ShieldAlert, color: "text-[#EF4444]", bg: "bg-[#EF4444]/10", border: "border-[#EF4444]/20" },
    { label: "Resolution Rate", value: stats.rate, icon: CheckCircle, color: "text-[#A2F301]", bg: "bg-[#A2F301]/10", border: "border-[#A2F301]/20" }
  ];

  const getPriorityStyles = (priority: string) => {
    switch (priority) {
      case "critical": return "bg-[#EF4444]/10 text-[#EF4444] border-[#EF4444]/20";
      case "high": return "bg-[#F59E0B]/10 text-[#F59E0B] border-[#F59E0B]/20";
      case "medium": return "bg-[#3B82F6]/10 text-[#3B82F6] border-[#3B82F6]/20";
      default: return "bg-white/5 text-[#999999] border-white/10";
    }
  };

  const getStatusStyles = (status: string) => {
    switch (status) {
      case "resolved": return "bg-[#10B981]/10 text-[#10B981] border-[#10B981]/20";
      case "open": return "bg-[#F59E0B]/10 text-[#F59E0B] border-[#F59E0B]/20";
      default: return "bg-white/5 text-[#999999] border-white/10";
    }
  };

  return (
    <div className="w-full pb-20">
      {/* Header Section */}
      <div className="mb-8">
        <h1 className="text-2xl sm:text-[30px] font-bold text-white leading-tight mb-1">Dispute Resolution</h1>
        <p className="text-[#999999] text-sm sm:text-[16px]">Manage and resolve disputes between musicians and organizers</p>
      </div>

      {/* Stats Cards Grid */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 sm:gap-6 mb-10">
        {statCards.map((card, i) => (
          <div key={i} className="bg-[#1A1A1A] border border-[#2A2A2A] rounded-[8px] p-4 sm:p-6 flex items-center gap-4 hover:border-white/10 transition-all group shadow-xl">
            <div className={`w-12 h-12 sm:w-[48px] sm:h-[48px] ${card.bg} ${card.border} border rounded-[8px] flex items-center justify-center shrink-0`}>
              <card.icon className={`w-5 h-5 sm:w-6 sm:h-6 ${card.color}`} />
            </div>
            <div>
              <p className="text-[#999999] text-[12px] sm:text-[14px] font-medium mb-0.5">{card.label}</p>
              <p className="text-white text-2xl sm:text-[28px] font-bold leading-none">{card.value}</p>
            </div>
          </div>
        ))}
      </div>

      {/* Tabs */}
      <div className="flex gap-4 sm:gap-8 mb-8 border-b border-[#2A2A2A] overflow-x-auto custom-scrollbar whitespace-nowrap">
        {[
          { id: "open", label: `Open Disputes (${stats.open})` },
          { id: "resolved", label: `Resolved (${stats.resolved})` }
        ].map((tab) => (
          <button
            key={tab.id}
            onClick={() => setActiveTab(tab.id as any)}
            className={`pb-4 text-[14px] font-bold transition-all relative shrink-0 ${
              activeTab === tab.id ? "text-[#A2F301]" : "text-[#999999] hover:text-white"
            }`}
          >
            {tab.label}
            {activeTab === tab.id && (
              <div className="absolute bottom-0 left-0 w-full h-[2px] bg-[#A2F301] shadow-[0_0_10px_rgba(162,243,1,0.5)]" />
            )}
          </button>
        ))}
      </div>

      {/* Disputes List */}
      <div className="flex flex-col gap-6">
        {filteredDisputes.map((dispute) => (
          <div key={dispute.id} className="bg-[#1A1A1A] border border-[#2A2A2A] rounded-[8px] p-6 sm:p-8 animate-in fade-in duration-500 shadow-2xl">
            {/* Card Header */}
            <div className="flex flex-wrap items-center gap-2 sm:gap-3 mb-2">
              <h2 className="text-white text-[18px] sm:text-[20px] font-bold">{dispute.id}</h2>
              <div className={`px-2 py-0.5 rounded-[4px] text-[10px] sm:text-[11px] font-bold border ${getPriorityStyles(dispute.priority)}`}>
                {dispute.priority} priority
              </div>
              <div className={`px-2 py-0.5 rounded-[4px] text-[10px] sm:text-[11px] font-bold border ${getStatusStyles(dispute.status)}`}>
                {dispute.status}
              </div>
            </div>
            
            <p className="text-[#999999] text-[13px] sm:text-[14px] mb-6 sm:mb-8">
              Gig: {dispute.gigReference} <br className="sm:hidden" /> <span className="hidden sm:inline">•</span> Filed on {dispute.filedDate}
            </p>

            {/* Details Grid */}
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-y-6 sm:gap-x-12 mb-8">
              <div>
                <p className="text-[#52525b] text-[11px] uppercase tracking-wider font-bold mb-1">Organizer</p>
                <p className="text-white text-[14px] sm:text-[15px] font-semibold">{dispute.organizer}</p>
              </div>
              <div>
                <p className="text-[#52525b] text-[11px] uppercase tracking-wider font-bold mb-1">Musician</p>
                <p className="text-white text-[14px] sm:text-[15px] font-semibold">{dispute.musician}</p>
              </div>
              <div>
                <p className="text-[#52525b] text-[11px] uppercase tracking-wider font-bold mb-1">Reason</p>
                <p className="text-white text-[14px] sm:text-[15px] font-semibold">{dispute.reason}</p>
              </div>
              <div>
                <p className="text-[#52525b] text-[11px] uppercase tracking-wider font-bold mb-1">Evidence Attached</p>
                <div className="flex items-center gap-2 text-[#A2F301] text-[14px] sm:text-[15px] font-semibold cursor-pointer hover:underline">
                  <Paperclip size={14} className="shrink-0" />
                  <span className="truncate">{dispute.evidenceLink}</span>
                </div>
              </div>
            </div>

            {/* Description */}
            <div className="mb-8 sm:mb-10">
              <p className="text-[#52525b] text-[11px] uppercase tracking-wider font-bold mb-2">Description</p>
              <p className="text-white/80 text-[14px] sm:text-[15px] leading-relaxed max-w-[800px]">
                {dispute.description}
              </p>
            </div>

            {/* Actions */}
            {dispute.status === "open" && (
              <div className="flex flex-col sm:flex-row gap-3 sm:gap-4">
                <button 
                  onClick={() => handleAction(dispute.id, "Send Warning")}
                  className="h-[44px] px-6 rounded-[8px] bg-[#F59E0B]/10 text-[#F59E0B] text-[14px] font-bold flex items-center justify-center sm:justify-start gap-2 hover:bg-[#F59E0B]/20 transition-all"
                >
                  <Flag size={18} />
                  Send Warning
                </button>
                <button 
                  onClick={() => handleAction(dispute.id, "Suspend User")}
                  className="h-[44px] px-6 rounded-[8px] bg-[#EF4444]/10 text-[#EF4444] text-[14px] font-bold flex items-center justify-center sm:justify-start gap-2 hover:bg-[#EF4444]/20 transition-all"
                >
                  <UserX size={18} />
                  Suspend User
                </button>
                <button 
                  onClick={() => handleAction(dispute.id, "Close Dispute")}
                  className="h-[44px] px-6 rounded-[8px] bg-[#10B981]/10 text-[#10B981] text-[14px] font-bold flex items-center justify-center sm:justify-start gap-2 hover:bg-[#10B981]/20 transition-all sm:ml-auto"
                >
                  <CheckCircle2 size={18} />
                  Close Dispute
                </button>
              </div>
            )}
          </div>
        ))}

        {filteredDisputes.length === 0 && (
          <div className="bg-[#1A1A1A] border border-[#2A2A2A] border-dashed rounded-[8px] py-20 flex flex-col items-center justify-center">
            <CheckCircle2 size={48} className="text-[#52525b] mb-4" />
            <p className="text-[#999999] text-[16px]">No {activeTab} disputes to display.</p>
          </div>
        )}
      </div>

      {/* Notifications */}
      <SendWarningModal 
        isOpen={isWarningModalOpen}
        onClose={() => setIsWarningModalOpen(false)}
        onConfirm={confirmWarning}
        disputeId={selectedDisputeId || ""}
      />

      <SuspendUserModal 
        isOpen={isSuspendModalOpen}
        onClose={() => setIsSuspendModalOpen(false)}
        onConfirm={confirmSuspend}
      />

      <Toast 
        show={toast.show}
        message={toast.message}
        onClose={() => setToast({ ...toast, show: false })}
      />
    </div>
  );
}
