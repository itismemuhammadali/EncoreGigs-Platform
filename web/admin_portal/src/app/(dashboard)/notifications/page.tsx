"use client";

import React, { useState } from "react";
import { 
  Bell, 
  Users, 
  Calendar, 
  Send, 
  Search,
  Plus,
  MoreVertical,
  ChevronRight,
  Eye,
  Trash2
} from "lucide-react";
import { Toast } from "@/components/ui/Toast";
import { NotificationDetailsModal } from "@/components/ui/NotificationDetailsModal";

// --- Types & Interfaces ---
interface NotificationHistoryItem {
  id: string;
  title: string;
  targetAudience: string; // e.g., 'All', 'Musicians', 'Organizers'
  sentDate: string; // ISO string or formatted date
  recipients: string; // Formatted number
  status: "sent" | "scheduled" | "draft";
}

// --- Mock Data ---
// BACKEND DEVELOPER: Fetch this from your notifications history endpoint.
const MOCK_HISTORY: NotificationHistoryItem[] = [
  {
    id: "NOT-001",
    title: "Platform Maintenance Notice",
    targetAudience: "All Users",
    sentDate: "2026-02-15 10:00",
    recipients: "1,590",
    status: "sent"
  },
  {
    id: "NOT-002",
    title: "New Feature: Featured Artist Boost",
    targetAudience: "Musicians",
    sentDate: "2026-02-10 14:30",
    recipients: "1,248",
    status: "sent"
  },
  {
    id: "NOT-003",
    title: "Payment Processing Update",
    targetAudience: "Organizers",
    sentDate: "2026-02-08 09:15",
    recipients: "342",
    status: "sent"
  },
  {
    id: "NOT-004",
    title: "Security Update Required",
    targetAudience: "All Users",
    sentDate: "2026-02-05 16:45",
    recipients: "1,590",
    status: "sent"
  }
];

export default function NotificationsPage() {
  // BACKEND DEVELOPER: Initialize this with data from your API.
  const [history, setHistory] = useState<NotificationHistoryItem[]>(MOCK_HISTORY);
  const [toast, setToast] = useState({ show: false, message: "" });
  
  const [isDetailsModalOpen, setIsDetailsModalOpen] = useState(false);
  const [selectedNotification, setSelectedNotification] = useState<NotificationHistoryItem | null>(null);

  // Form State
  const [title, setTitle] = useState("");
  const [message, setMessage] = useState("");
  const [audience, setAudience] = useState("All User");
  const [schedule, setSchedule] = useState("");

  // --- Handlers ---
  const handleSend = (e: React.FormEvent) => {
    e.preventDefault();
    if (!title || !message) {
      setToast({ show: true, message: "Please fill in title and message." });
      return;
    }
    // BACKEND DEVELOPER: Implement notification sending via API.
    // e.g., await api.post('/notifications/broadcast', { title, message, audience, schedule });
    setToast({ show: true, message: "Notification sent successfully!" });
    
    const newNotif: NotificationHistoryItem = {
      id: `NOT-00${history.length + 1}`,
      title,
      targetAudience: audience,
      sentDate: new Date().toISOString().replace('T', ' ').slice(0, 16),
      recipients: audience === "All User" ? "1,590" : "Varies",
      status: "sent"
    };
    
    setHistory([newNotif, ...history]);
    setTitle("");
    setMessage("");
  };

  // --- UI Configuration Arrays ---
  const statCards = [
    { label: "Notifications Sent", value: "4", icon: Bell, color: "text-[#A2F301]", bg: "bg-[#A2F301]/10", border: "border-[#A2F301]/20" },
    { label: "Total Reach", value: "4,770", icon: Users, color: "text-[#10B981]", bg: "bg-[#10B981]/10", border: "border-[#10B981]/20" },
    { label: "Scheduled", value: "0", icon: Calendar, color: "text-[#3B82F6]", bg: "bg-[#3B82F6]/10", border: "border-[#3B82F6]/20" },
    { label: "Avg. Open Rate", value: "68%", icon: Send, color: "text-[#F59E0B]", bg: "bg-[#F59E0B]/10", border: "border-[#F59E0B]/20" }
  ];

  return (
    <div className="w-full pb-20">
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-2xl sm:text-[32px] font-bold mb-2 leading-tight">Notifications Management</h1>
        <p className="text-[#999999] text-sm sm:text-[16px]">Send system-wide announcements and manage notification history</p>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 sm:gap-6 mb-8">
        {statCards.map((stat, idx) => (
          <div key={idx} className="bg-[#1A1A1A] border border-[#2A2A2A] rounded-[8px] p-4 sm:p-6 flex items-center gap-4 shadow-xl">
            <div className={`w-12 h-12 sm:w-[48px] sm:h-[48px] rounded-[8px] ${stat.bg} flex items-center justify-center shrink-0`}>
              <stat.icon className={stat.color} size={24} />
            </div>
            <div>
              <p className="text-[#999999] text-[13px] sm:text-[14px]">{stat.label}</p>
              <h3 className="text-[20px] sm:text-[24px] font-bold">{stat.value}</h3>
            </div>
          </div>
        ))}
      </div>

      {/* Send New Notification Form */}
      <div className="bg-[#1A1A1A] border border-[#2A2A2A] rounded-[8px] p-6 sm:p-8 mb-8 shadow-2xl">
        <h2 className="text-[18px] sm:text-[20px] font-bold mb-6">Send New Notification</h2>
        <form onSubmit={handleSend} className="space-y-6">
          <div>
            <label className="block text-[#999999] text-[13px] sm:text-[14px] mb-2 font-medium">Notification Title</label>
            <input 
              type="text"
              placeholder="Enter notification title..."
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              className="w-full h-[48px] bg-[#1A1A1A] border border-white/10 rounded-[8px] px-4 text-white focus:border-[#A2F301] transition-all outline-none"
            />
          </div>

          <div>
            <label className="block text-[#999999] text-[13px] sm:text-[14px] mb-2 font-medium">Message</label>
            <textarea 
              placeholder="Enter your message..."
              value={message}
              onChange={(e) => setMessage(e.target.value)}
              className="w-full h-[120px] bg-[#1A1A1A] border border-white/10 rounded-[8px] p-4 text-white focus:border-[#A2F301] transition-all outline-none resize-none"
            />
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-6">
            <div>
              <label className="block text-[#999999] text-[13px] sm:text-[14px] mb-2 font-medium">Target Audience</label>
              <div className="relative">
                <select 
                  value={audience}
                  onChange={(e) => setAudience(e.target.value)}
                  className="w-full h-[48px] bg-[#1A1A1A] border border-white/10 rounded-[8px] px-4 text-white focus:border-[#A2F301] transition-all outline-none appearance-none"
                >
                  <option>All User</option>
                  <option>Musicians</option>
                  <option>Organizers</option>
                </select>
              </div>
            </div>
            <div>
              <label className="block text-[#999999] text-[13px] sm:text-[14px] mb-2 font-medium">Schedule (Optional)</label>
              <input 
                type="datetime-local"
                value={schedule}
                onChange={(e) => setSchedule(e.target.value)}
                className="w-full h-[48px] bg-[#1A1A1A] border border-white/10 rounded-[8px] px-4 text-[#999999] focus:border-[#A2F301] transition-all outline-none"
              />
            </div>
          </div>

          <div className="flex flex-col sm:flex-row gap-3 sm:gap-4 pt-2">
            <button 
              type="submit"
              className="h-[48px] px-8 bg-[#A2F301] text-black font-bold rounded-[8px] flex items-center justify-center gap-2 hover:bg-[#8ed601] transition-all w-full sm:w-auto"
            >
              <Send size={18} />
              Send Now
            </button>
            <button 
              type="button"
              className="h-[48px] px-8 bg-white/5 text-white font-bold rounded-[8px] hover:bg-white/10 transition-all w-full sm:w-auto"
            >
              Save as Draft
            </button>
          </div>
        </form>
      </div>

      {/* Notification History */}
      <div className="bg-[#1A1A1A] border border-[#2A2A2A] rounded-[8px] overflow-hidden">
        <div className="p-6 border-b border-[#2A2A2A]">
          <h2 className="text-[20px] font-bold">Notification History</h2>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-left">
            <thead>
              <tr className="bg-[#262626] text-white border-b border-[#2A2A2A]">
                <th className="px-6 py-4 text-[14px] font-medium leading-[20px]">Title</th>
                <th className="px-6 py-4 text-[14px] font-medium leading-[20px]">Target Audience</th>
                <th className="px-6 py-4 text-[14px] font-medium leading-[20px]">Sent Date</th>
                <th className="px-6 py-4 text-[14px] font-medium leading-[20px]">Recipients</th>
                <th className="px-6 py-4 text-[14px] font-medium leading-[20px]">Status</th>
                <th className="px-6 py-4 text-[14px] font-medium leading-[20px]">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#2A2A2A]">
              {history.map((item) => (
                <tr key={item.id} className="hover:bg-white/5 transition-all text-[14px]">
                  <td className="px-6 py-4 text-white font-medium">{item.title}</td>
                  <td className="px-6 py-4 text-[#999999]">{item.targetAudience}</td>
                  <td className="px-6 py-4 text-[#999999]">{item.sentDate}</td>
                  <td className="px-6 py-4 text-white font-bold">{item.recipients}</td>
                  <td className="px-6 py-4">
                    <span className="px-3 py-1 bg-[#10B981]/10 text-[#10B981] rounded-full text-[12px] font-bold">
                      {item.status}
                    </span>
                  </td>
                  <td className="px-6 py-4">
                    <button 
                      onClick={() => {
                        setSelectedNotification(item);
                        setIsDetailsModalOpen(true);
                      }}
                      className="text-[#A2F301] font-bold hover:underline"
                    >
                      View Details
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      <NotificationDetailsModal 
        isOpen={isDetailsModalOpen}
        onClose={() => setIsDetailsModalOpen(false)}
        notification={selectedNotification}
      />

      <Toast 
        show={toast.show}
        message={toast.message}
        onClose={() => setToast({ ...toast, show: false })}
      />
    </div>
  );
}
