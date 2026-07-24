"use client";

import React, { useState, useEffect } from "react";
import { 
  Bell, 
  Users, 
  Calendar, 
  Send,
  Loader2
} from "lucide-react";
import { Toast } from "@/components/ui/Toast";
import { NotificationDetailsModal } from "@/components/ui/NotificationDetailsModal";
import { apiRequest } from "@/lib/api";

interface NotificationHistoryItem {
  id: string;
  title: string;
  targetAudience: string;
  sentDate: string;
  recipients: string;
  status: "sent" | "scheduled" | "draft";
}

export default function NotificationsPage() {
  const [history, setHistory] = useState<NotificationHistoryItem[]>([]);
  const [toast, setToast] = useState({ show: false, message: "", type: "success" as "success" | "error" });
  const [sending, setSending] = useState(false);
  const [loading, setLoading] = useState(true);
  
  const [isDetailsModalOpen, setIsDetailsModalOpen] = useState(false);
  const [selectedNotification, setSelectedNotification] = useState<NotificationHistoryItem | null>(null);

  const [title, setTitle] = useState("");
  const [message, setMessage] = useState("");
  const [audience, setAudience] = useState("All Users");
  const [schedule, setSchedule] = useState("");

  useEffect(() => {
    fetchHistory();
  }, []);

  const fetchHistory = async () => {
    try {
      setLoading(true);
      const data = await apiRequest("/notifications/history");
      const mapped: NotificationHistoryItem[] = data.map((item: any) => ({
        id: item.id,
        title: item.title,
        targetAudience: item.audience,
        sentDate: item.createdAt ? new Date(item.createdAt).toISOString().replace("T", " ").slice(0, 16) : "N/A",
        recipients: String(item.recipients || 0),
        status: item.status || "sent",
      }));
      setHistory(mapped);
    } catch (error) {
      console.error("Failed to fetch notification history:", error);
    } finally {
      setLoading(false);
    }
  };

  const handleSend = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!title || !message) {
      setToast({ show: true, message: "Please fill in title and message.", type: "error" });
      return;
    }

    setSending(true);
    try {
      const result = await apiRequest("/notifications/broadcast", {
        method: "POST",
        body: JSON.stringify({ title, message, audience, schedule: schedule || null }),
      });
      setToast({ show: true, message: `Notification sent to ${result.success} users`, type: "success" });
      setTitle("");
      setMessage("");
      setSchedule("");
      fetchHistory();
    } catch (error) {
      setToast({ show: true, message: "Failed to send notification", type: "error" });
    } finally {
      setSending(false);
    }
  };

  const totalSent = history.reduce((sum, h) => sum + parseInt(h.recipients) || 0, 0);

  const statCards = [
    { label: "Notifications Sent", value: String(history.length), icon: Bell, color: "text-[#A2F301]", bg: "bg-[#A2F301]/10", border: "border-[#A2F301]/20" },
    { label: "Total Reach", value: totalSent.toLocaleString(), icon: Users, color: "text-[#10B981]", bg: "bg-[#10B981]/10", border: "border-[#10B981]/20" },
    { label: "Scheduled", value: "0", icon: Calendar, color: "text-[#3B82F6]", bg: "bg-[#3B82F6]/10", border: "border-[#3B82F6]/20" },
    { label: "Avg. Open Rate", value: "—", icon: Send, color: "text-[#F59E0B]", bg: "bg-[#F59E0B]/10", border: "border-[#F59E0B]/20" }
  ];

  return (
    <div className="w-full pb-20">
      <div className="mb-8">
        <h1 className="text-2xl sm:text-[32px] font-bold mb-2 leading-tight">Notifications Management</h1>
        <p className="text-[#999999] text-sm sm:text-[16px]">Send system-wide announcements and manage notification history</p>
      </div>

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
                  <option>All Users</option>
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
              disabled={sending}
              className="h-[48px] px-8 bg-[#A2F301] text-black font-bold rounded-[8px] flex items-center justify-center gap-2 hover:bg-[#8ed601] transition-all w-full sm:w-auto disabled:opacity-50"
            >
              {sending ? <Loader2 className="w-5 h-5 animate-spin" /> : <Send size={18} />}
              {sending ? "Sending..." : "Send Now"}
            </button>
          </div>
        </form>
      </div>

      <div className="bg-[#1A1A1A] border border-[#2A2A2A] rounded-[8px] overflow-hidden">
        <div className="p-6 border-b border-[#2A2A2A]">
          <h2 className="text-[20px] font-bold">Notification History</h2>
        </div>
        <div className="overflow-x-auto">
          {loading ? (
            <div className="p-10 text-center">
              <Loader2 className="w-6 h-6 text-[#A2F301] animate-spin mx-auto" />
            </div>
          ) : (
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
                {history.length === 0 && (
                  <tr>
                    <td colSpan={6} className="px-6 py-10 text-center text-[#71717a]">No notifications sent yet</td>
                  </tr>
                )}
              </tbody>
            </table>
          )}
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
