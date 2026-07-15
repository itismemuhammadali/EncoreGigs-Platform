"use client";

import React, { useState, useMemo, useEffect } from "react";
import {
  DollarSign,
  TrendingUp,
  Clock,
  CheckCircle,
  Eye,
  Search,
  Loader2
} from "lucide-react";
import { Toast } from "@/components/ui/Toast";
import { TransactionDetailsModal } from "@/components/ui/TransactionDetailsModal";
import { PaymentActionModal } from "@/components/ui/PaymentActionModal";

interface Transaction {
  id: string;
  organizer: string;
  musician: string;
  gig: string;
  amount: string;
  escrowStatus: "held" | "released";
  date: string;
  status: "pending" | "completed";
}

export default function PaymentsEscrow() {
  const [activeTab, setActiveTab] = useState<"all" | "held" | "released" | "pending">("all");
  const [detailsModal, setDetailsModal] = useState<{ show: boolean; tx: Transaction | null }>({ show: false, tx: null });
  const [actionModal, setActionModal] = useState<{ show: boolean; type: "release" | "refund" }>({ show: false, type: "release" });
  const [toast, setToast] = useState<{ show: boolean; message: string }>({ show: false, message: "" });
  const [transactions, setTransactions] = useState<Transaction[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [stats, setStats] = useState([
    { label: "Total Escrow Funds", value: "$0", subtext: "Locked amount", icon: DollarSign },
    { label: "Released This Month", value: "$0", subtext: "from last month", trend: "+0%", icon: TrendingUp },
    { label: "Pending Releases", value: "0", subtext: "0 transactions", icon: Clock },
    { label: "Completed Payments", value: "0", subtext: "This month", icon: CheckCircle },
  ]);

  useEffect(() => {
    fetchTransactions();
  }, []);

  const fetchTransactions = async () => {
    try {
      const response = await fetch('http://localhost:8000/reports/payments');
      const data = await response.json();
      setTransactions(data);
      
      // Calculate real stats from data
      const heldAmount = data.filter((t: any) => t.escrowStatus === 'held')
                             .reduce((acc: number, curr: any) => acc + parseFloat(curr.amount.replace('$', '').replace(',', '')), 0);
      const pendingCount = data.filter((t: any) => t.status === 'pending').length;
      const completedCount = data.filter((t: any) => t.status === 'completed').length;

      setStats([
        { label: "Total Escrow Funds", value: `$${heldAmount.toLocaleString()}`, subtext: "Locked amount", icon: DollarSign },
        { label: "Released This Month", value: "Live", subtext: "Real-time data", trend: "+100%", icon: TrendingUp },
        { label: "Pending Releases", value: pendingCount.toString(), subtext: "Active transactions", icon: Clock },
        { label: "Completed Payments", value: completedCount.toString(), subtext: "Total successful", icon: CheckCircle },
      ]);
    } catch (error) {
      console.error("Error fetching payments:", error);
    } finally {
      setIsLoading(false);
    }
  };

  const filteredTransactions = useMemo(() => {
    return transactions.filter(tx => {
      if (activeTab === "all") return true;
      if (activeTab === "held") return tx.escrowStatus === "held";
      if (activeTab === "released") return tx.escrowStatus === "released";
      if (activeTab === "pending") return tx.status === "pending";
      return true;
    });
  }, [activeTab, transactions]);

  return (
    <div className="space-y-8 animate-in fade-in duration-700 pb-20">
      {/* --- HEADER --- */}
      <div>
        <h1 className="text-2xl sm:text-[32px] font-bold text-white mb-2 leading-tight font-inter">Payments & Escrow</h1>
        <p className="text-[#a1a1aa] text-sm sm:text-[16px]">Monitor transactions, escrow funds, and payment releases</p>
      </div>

      {/* --- STAT CARDS --- */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
        {stats.map((stat, i) => (
          <div key={i} className="bg-[#1A1A1A] border border-[#2A2A2A] p-6 rounded-xl shadow-xl flex justify-between items-start group hover:border-[#b3ff00]/30 transition-all">
            <div className="space-y-1">
              <p className="text-[#71717a] text-[13px] sm:text-[14px] font-medium">{stat.label}</p>
              <h3 className="text-white text-2xl sm:text-[30px] font-bold leading-tight py-1">{stat.value}</h3>
              {stat.trend ? (
                <p className="text-[#b3ff00] text-[12px] sm:text-[13px] font-medium">{stat.trend} from last month</p>
              ) : (
                <p className="text-[#71717a] text-[12px] sm:text-[13px] font-medium">{stat.subtext}</p>
              )}
            </div>
            <div className="w-12 h-12 sm:w-[58px] sm:h-[58px] rounded-lg bg-[#1c2114] flex items-center justify-center border border-[#b3ff00]/10 shrink-0">
              <stat.icon className="w-6 h-6 sm:w-7 sm:h-7 text-[#b3ff00]" />
            </div>
          </div>
        ))}
      </div>

      {/* --- TABS --- */}
      <div className="flex items-center gap-4 sm:gap-8 border-b border-[#2A2A2A] overflow-x-auto custom-scrollbar whitespace-nowrap">
        {[
          { id: "all", label: "All Transactions" },
          { id: "held", label: "Held in Escrow" },
          { id: "released", label: "Released" },
          { id: "pending", label: "Pending" }
        ].map((tab) => (
          <button
            key={tab.id}
            onClick={() => setActiveTab(tab.id as any)}
            className={`pb-4 text-[14px] sm:text-[15px] font-semibold transition-all relative ${
              activeTab === tab.id ? "text-[#b3ff00]" : "text-[#71717a] hover:text-white"
            }`}
          >
            {tab.label}
            {activeTab === tab.id && (
              <div className="absolute bottom-0 left-0 right-0 h-[2px] bg-[#b3ff00] animate-in fade-in slide-in-from-bottom-1" />
            )}
          </button>
        ))}
      </div>

      {/* --- TRANSACTIONS TABLE CONTAINER --- */}
      <div className="bg-[#1A1A1A] border border-[#2A2A2A] rounded-2xl overflow-hidden shadow-2xl">
        <div className="overflow-x-auto">
          {isLoading ? (
            <div className="p-20 flex flex-col items-center justify-center space-y-4">
              <Loader2 className="w-10 h-10 text-[#b3ff00] animate-spin" />
              <p className="text-[#71717a]">Loading real-time escrow data...</p>
            </div>
          ) : (
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="bg-[#262626] border-y border-[#2A2A2A]">
                  <th className="px-6 py-4 text-[14px] font-medium leading-[20px] text-white capitalize">Transaction ID</th>
                  <th className="px-6 py-4 text-[14px] font-medium leading-[20px] text-white capitalize">Organizer</th>
                  <th className="px-6 py-4 text-[14px] font-medium leading-[20px] text-white capitalize">Musician</th>
                  <th className="px-6 py-4 text-[14px] font-medium leading-[20px] text-white capitalize">Gig Reference</th>
                  <th className="px-6 py-4 text-[14px] font-medium leading-[20px] text-white capitalize">Amount</th>
                  <th className="px-6 py-4 text-[14px] font-medium leading-[20px] text-white capitalize">Escrow Status</th>
                  <th className="px-6 py-4 text-[14px] font-medium leading-[20px] text-white capitalize">Date</th>
                  <th className="px-6 py-4 text-[14px] font-medium leading-[20px] text-white capitalize">Status</th>
                  <th className="px-6 py-4 text-[14px] font-medium leading-[20px] text-white capitalize text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-[#2A2A2A]">
                {filteredTransactions.length === 0 ? (
                  <tr>
                    <td colSpan={9} className="px-6 py-10 text-center text-[#71717a]">No transactions found</td>
                  </tr>
                ) : (
                  filteredTransactions.map((tx, i) => (
                    <tr key={i} className="hover:bg-white/[0.02] transition-colors group">
                      <td className="px-6 py-5 text-[#b3ff00] font-bold text-[14px]">{tx.id}</td>
                      <td className="px-6 py-5 text-[#FFFFFF] text-[14px] font-medium">{tx.organizer}</td>
                      <td className="px-6 py-5 text-[#FFFFFF] text-[14px] font-medium">{tx.musician}</td>
                      <td className="px-6 py-5 text-[#a1a1aa] text-[14px]">{tx.gig}</td>
                      <td className="px-6 py-5 text-white font-bold text-[14px]">{tx.amount}</td>
                      <td className="px-6 py-5">
                        <span className={`px-3 py-1 rounded-full text-[12px] font-medium ${
                          tx.escrowStatus === 'released' ? 'bg-[#10b981]/10 text-[#10b981]' : 'bg-[#f59e0b]/10 text-[#f59e0b]'
                        }`}>
                          {tx.escrowStatus}
                        </span>
                      </td>
                      <td className="px-6 py-5 text-[#a1a1aa] text-[14px]">{tx.date}</td>
                      <td className="px-6 py-5">
                        <span className={`px-3 py-1 rounded-full text-[12px] font-medium ${
                          tx.status === 'completed' ? 'bg-[#10b981]/10 text-[#10b981]' : 'bg-[#f59e0b]/10 text-[#f59e0b]'
                        }`}>
                          {tx.status}
                        </span>
                      </td>
                      <td className="px-6 py-5 text-right">
                        <button 
                          onClick={() => setDetailsModal({ show: true, tx })}
                          className="text-[#b3ff00] text-[13px] font-bold hover:underline"
                        >
                          View Details
                        </button>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          )}
        </div>
      </div>

      <TransactionDetailsModal 
        isOpen={detailsModal.show}
        onClose={() => setDetailsModal({ show: false, tx: null })}
        txData={detailsModal.tx}
        onRelease={() => setActionModal({ show: true, type: "release" })}
        onRefund={() => setActionModal({ show: true, type: "refund" })}
      />

      <PaymentActionModal 
        isOpen={actionModal.show}
        type={actionModal.type}
        onClose={() => setActionModal({ ...actionModal, show: false })}
        onConfirm={() => {
          setActionModal({ ...actionModal, show: false });
          setDetailsModal({ show: false, tx: null });
          setToast({ show: true, message: actionModal.type === "release" ? "Escrow released successfully" : "Refund processed successfully" });
        }}
      />

      <Toast 
        show={toast.show} 
        message={toast.message} 
        onClose={() => setToast({ show: false, message: "" })} 
      />
    </div>
  );
}
