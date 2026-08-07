"use client";

import React, { useState, useMemo, useEffect } from "react";
import { 
  AlertCircle, 
  CheckCircle2, 
  Flag, 
  UserX, 
  CheckCircle,
  Clock,
  Paperclip,
  ShieldAlert,
  Loader2
} from "lucide-react";
import { Toast } from "@/components/ui/Toast";
import { SendWarningModal } from "@/components/ui/SendWarningModal";
import { SuspendUserModal } from "@/components/ui/SuspendUserModal";
import { apiRequest } from "@/lib/api";

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
  attachments?: string[];
  description: string;
  resolutionAction?: string;
  resolutionNotes?: string;
}

export default function DisputesPage() {
  const [disputes, setDisputes] = useState<Dispute[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [activeTab, setActiveTab] = useState<"open" | "resolved">("open");
  const [toast, setToast] = useState({ show: false, message: "" });
  
  const [isWarningModalOpen, setIsWarningModalOpen] = useState(false);
  const [isSuspendModalOpen, setIsSuspendModalOpen] = useState(false);
  const [selectedDisputeId, setSelectedDisputeId] = useState<string | null>(null);
  
  // Resolution Modal State
  const [isResolveModalOpen, setIsResolveModalOpen] = useState(false);
  const [resolveAction, setResolveAction] = useState<"refund_organizer" | "pay_musician" | "split">("refund_organizer");
  const [resolveNotes, setResolveNotes] = useState("");
  const [isResolving, setIsResolving] = useState(false);

  useEffect(() => {
    fetchDisputes();
  }, []);

  const fetchDisputes = async () => {
    setIsLoading(true);
    try {
      const data = await apiRequest("/disputes/list");
      setDisputes(data);
    } catch (error) {
      console.error("Failed to fetch disputes:", error);
      setToast({ show: true, message: "Failed to load disputes from database." });
    } finally {
      setIsLoading(false);
    }
  };

  // --- Handlers ---
  const handleAction = async (id: string, action: string) => {
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

    if (action === "Close Dispute") {
      setSelectedDisputeId(id);
      setIsResolveModalOpen(true);
    }
  };

  const confirmResolution = async () => {
    if (!selectedDisputeId) return;
    setIsResolving(true);
    try {
      await apiRequest(`/disputes/${selectedDisputeId}/resolve`, {
        method: "POST",
        body: JSON.stringify({
          resolutionAction: resolveAction,
          resolutionNotes: resolveNotes
        })
      });
      setToast({ show: true, message: `Dispute resolved successfully (${resolveAction.replace('_', ' ')}).` });
      setIsResolveModalOpen(false);
      setSelectedDisputeId(null);
      setResolveNotes("");
      fetchDisputes();
    } catch (error) {
      console.error("Failed to resolve dispute:", error);
      setToast({ show: true, message: "Error resolving dispute." });
    } finally {
      setIsResolving(false);
    }
  };

  const confirmWarning = () => {
    // In a real app, this would be an API call
    setToast({ show: true, message: `Warning sent for Dispute ${selectedDisputeId}.` });
    setIsWarningModalOpen(false);
    setSelectedDisputeId(null);
  };

  const confirmSuspend = () => {
    // In a real app, this would be an API call
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
    rate: disputes.length > 0 
      ? `${Math.round((disputes.filter(d => d.status === "resolved").length / disputes.length) * 100)}%`
      : "0%"
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
      <div className="mb-8 flex justify-between items-center">
        <div>
          <h1 className="text-2xl sm:text-[30px] font-bold text-white leading-tight mb-1">Dispute Resolution</h1>
          <p className="text-[#999999] text-sm sm:text-[16px]">Manage and resolve disputes between musicians and organizers</p>
        </div>
        <button 
          onClick={fetchDisputes}
          className="h-[40px] px-4 rounded-[8px] bg-white/5 hover:bg-white/10 text-white text-xs font-semibold flex items-center gap-2 border border-white/10 transition-all"
        >
          Refresh List
        </button>
      </div>

      {/* Stats Overview */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
        {statCards.map((card, index) => {
          const Icon = card.icon;
          return (
            <div key={index} className={`p-5 rounded-[8px] bg-[#1A1A1A] border ${card.border} flex items-center justify-between`}>
              <div>
                <p className="text-[#999999] text-xs font-medium mb-1">{card.label}</p>
                <h3 className="text-2xl font-bold text-white">{card.value}</h3>
              </div>
              <div className={`p-3 rounded-[8px] ${card.bg} ${card.color}`}>
                <Icon size={20} />
              </div>
            </div>
          );
        })}
      </div>

      {/* Tabs */}
      <div className="flex border-b border-[#2A2A2A] mb-8">
        {[
          { id: "open", label: `Open Disputes (${stats.open})` },
          { id: "resolved", label: `Resolved (${stats.resolved})` },
        ].map((tab) => (
          <button
            key={tab.id}
            onClick={() => setActiveTab(tab.id as any)}
            className={`pb-4 px-6 text-sm font-semibold border-b-2 transition-all ${
              activeTab === tab.id
                ? "border-[#A2F301] text-[#A2F301]"
                : "border-transparent text-[#999999] hover:text-white"
            }`}
          >
            {tab.label}
          </button>
        ))}
      </div>

      {/* Disputes List */}
      <div className="space-y-6">
        {isLoading ? (
          <div className="flex justify-center items-center py-20">
            <Loader2 className="animate-spin text-[#A2F301]" size={32} />
          </div>
        ) : (
          <>
            {filteredDisputes.map((dispute) => (
              <div key={dispute.id} className="bg-[#1A1A1A] border border-[#2A2A2A] rounded-[8px] p-6 sm:p-8 animate-in fade-in duration-500 shadow-2xl">
                {/* Card Header */}
                <div className="flex flex-wrap items-center gap-2 sm:gap-3 mb-2">
                  <h2 className="text-white text-[18px] sm:text-[20px] font-bold">#{dispute.id.substring(0, 8).toUpperCase()}</h2>
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
                    <p className="text-[#52525b] text-[11px] uppercase tracking-wider font-bold mb-1">Evidence Files</p>
                    {dispute.attachments && dispute.attachments.length > 0 ? (
                      <div className="flex flex-wrap gap-2 mt-1">
                        {dispute.attachments.map((url, idx) => (
                          <a
                            key={idx}
                            href={url}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-[6px] bg-[#2A2A2A] text-[#A2F301] text-xs font-medium hover:bg-[#3A3A3A] transition-all border border-[#3A3A3A]"
                          >
                            <Paperclip size={12} />
                            <span>Evidence #{idx + 1}</span>
                          </a>
                        ))}
                      </div>
                    ) : (
                      <p className="text-[#999999] text-sm">No files uploaded</p>
                    )}
                  </div>
                </div>

                {/* Description */}
                <div className="mb-8 sm:mb-10">
                  <p className="text-[#52525b] text-[11px] uppercase tracking-wider font-bold mb-2">Description</p>
                  <p className="text-white/80 text-[14px] sm:text-[15px] leading-relaxed max-w-[800px]">
                    {dispute.description}
                  </p>
                </div>

                {/* Resolution Notes if Resolved */}
                {dispute.status === "resolved" && dispute.resolutionAction && (
                  <div className="mb-8 p-4 rounded-[8px] bg-[#10B981]/10 border border-[#10B981]/20">
                    <p className="text-[#10B981] text-[12px] uppercase font-bold tracking-wider mb-1">Resolution Outcome</p>
                    <p className="text-white text-sm font-semibold capitalize mb-1">
                      Action: {dispute.resolutionAction.replace('_', ' ')}
                    </p>
                    {dispute.resolutionNotes && (
                      <p className="text-[#999999] text-xs leading-relaxed">
                        Notes: {dispute.resolutionNotes}
                      </p>
                    )}
                  </div>
                )}

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
                      className="h-[44px] px-6 rounded-[8px] bg-[#A2F301] text-black text-[14px] font-bold flex items-center justify-center sm:justify-start gap-2 hover:bg-[#8EE000] transition-all sm:ml-auto shadow-lg"
                    >
                      <CheckCircle2 size={18} />
                      Resolve & Decision
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
          </>
        )}
      </div>

      {/* Resolution Decision Modal */}
      {isResolveModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/80 p-4">
          <div className="bg-[#1A1A1A] border border-[#2A2A2A] rounded-[16px] p-6 max-w-md w-full shadow-2xl">
            <h3 className="text-xl font-bold text-white mb-2">Resolve Dispute #{selectedDisputeId?.substring(0, 8).toUpperCase()}</h3>
            <p className="text-sm text-[#999999] mb-6">Select a financial resolution outcome for this gig dispute.</p>
            
            <div className="space-y-3 mb-6">
              <label 
                className={`flex items-center justify-between p-4 rounded-[10px] border cursor-pointer transition-all ${
                  resolveAction === "refund_organizer" 
                    ? "bg-[#A2F301]/10 border-[#A2F301] text-white" 
                    : "bg-[#262626] border-[#333333] text-[#999999]"
                }`}
                onClick={() => setResolveAction("refund_organizer")}
              >
                <div>
                  <p className="font-bold text-sm text-white">Full Refund to Organizer</p>
                  <p className="text-xs text-[#999999]">Cancel booking & return escrowed funds</p>
                </div>
                <input type="radio" checked={resolveAction === "refund_organizer"} onChange={() => {}} className="accent-[#A2F301]" />
              </label>

              <label 
                className={`flex items-center justify-between p-4 rounded-[10px] border cursor-pointer transition-all ${
                  resolveAction === "pay_musician" 
                    ? "bg-[#A2F301]/10 border-[#A2F301] text-white" 
                    : "bg-[#262626] border-[#333333] text-[#999999]"
                }`}
                onClick={() => setResolveAction("pay_musician")}
              >
                <div>
                  <p className="font-bold text-sm text-white">Full Payout to Musician</p>
                  <p className="text-xs text-[#999999]">Complete booking & release escrowed funds</p>
                </div>
                <input type="radio" checked={resolveAction === "pay_musician"} onChange={() => {}} className="accent-[#A2F301]" />
              </label>

              <label 
                className={`flex items-center justify-between p-4 rounded-[10px] border cursor-pointer transition-all ${
                  resolveAction === "split" 
                    ? "bg-[#A2F301]/10 border-[#A2F301] text-white" 
                    : "bg-[#262626] border-[#333333] text-[#999999]"
                }`}
                onClick={() => setResolveAction("split")}
              >
                <div>
                  <p className="font-bold text-sm text-white">Split Payout (50 / 50)</p>
                  <p className="text-xs text-[#999999]">Partial refund & partial musician payout</p>
                </div>
                <input type="radio" checked={resolveAction === "split"} onChange={() => {}} className="accent-[#A2F301]" />
              </label>
            </div>

            <div className="mb-6">
              <label className="block text-xs font-bold text-[#999999] uppercase mb-2">Admin Resolution Notes</label>
              <textarea
                value={resolveNotes}
                onChange={(e) => setResolveNotes(e.target.value)}
                placeholder="Explain the rationale behind this decision..."
                className="w-full bg-[#262626] border border-[#333333] rounded-[8px] p-3 text-sm text-white focus:outline-none focus:border-[#A2F301] h-24 resize-none"
              />
            </div>

            <div className="flex gap-3">
              <button
                onClick={() => setIsResolveModalOpen(false)}
                className="flex-1 h-[44px] rounded-[8px] bg-white/10 hover:bg-white/20 text-white text-sm font-bold transition-all"
              >
                Cancel
              </button>
              <button
                onClick={confirmResolution}
                disabled={isResolving}
                className="flex-1 h-[44px] rounded-[8px] bg-[#A2F301] hover:bg-[#8EE000] text-black text-sm font-bold flex items-center justify-center gap-2 transition-all disabled:opacity-50"
              >
                {isResolving && <Loader2 className="animate-spin" size={16} />}
                Confirm & Resolve
              </button>
            </div>
          </div>
        </div>
      )}

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
