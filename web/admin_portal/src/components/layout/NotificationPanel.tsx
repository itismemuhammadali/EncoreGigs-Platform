"use client";

import React, { useState, useEffect } from "react";
import { apiRequest } from "@/lib/api";
import { Loader2 } from "lucide-react";

interface Notification {
  id: string;
  title: string;
  body: string;
  category: string;
  isRead: boolean;
  createdAt: string;
  data?: Record<string, any>;
}

interface NotificationPanelProps {
  isOpen: boolean;
  onClose: () => void;
  onUnreadCountChange?: (count: number) => void;
}

const categoryColors: Record<string, string> = {
  security: "text-[#ef4444]",
  user_activity: "text-[#3b82f6]",
  payment: "text-[#f59e0b]",
  health: "text-[#ef4444]",
  milestone: "text-[#A2F301]",
};

const categoryLabels: Record<string, string> = {
  security: "Security",
  user_activity: "User",
  payment: "Payment",
  health: "System",
  milestone: "Milestone",
};

function timeAgo(dateStr: string): string {
  const diff = Date.now() - new Date(dateStr).getTime();
  const mins = Math.floor(diff / 60000);
  if (mins < 1) return "Just now";
  if (mins < 60) return `${mins}m ago`;
  const hours = Math.floor(mins / 60);
  if (hours < 24) return `${hours}h ago`;
  const days = Math.floor(hours / 24);
  return `${days}d ago`;
}

export function NotificationPanel({ isOpen, onClose, onUnreadCountChange }: NotificationPanelProps) {
  const [notifications, setNotifications] = useState<Notification[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (isOpen) fetchNotifications();
  }, [isOpen]);

  const fetchNotifications = async () => {
    try {
      setLoading(true);
      const data = await apiRequest("/admin/notifications?limit=20");
      setNotifications(data);
      const unread = data.filter((n: Notification) => !n.isRead).length;
      onUnreadCountChange?.(unread);
    } catch (error) {
      console.error("Failed to fetch notifications:", error);
    } finally {
      setLoading(false);
    }
  };

  const handleMarkRead = async (id: string) => {
    try {
      await apiRequest(`/admin/notifications/${id}/read`, { method: "PATCH" });
      setNotifications(prev => prev.map(n => n.id === id ? { ...n, isRead: true } : n));
      const unread = notifications.filter(n => !n.isRead && n.id !== id).length;
      onUnreadCountChange?.(unread);
    } catch (error) {
      console.error("Failed to mark as read:", error);
    }
  };

  const handleMarkAllRead = async () => {
    try {
      await apiRequest("/admin/notifications/read-all", { method: "POST" });
      setNotifications(prev => prev.map(n => ({ ...n, isRead: true })));
      onUnreadCountChange?.(0);
    } catch (error) {
      console.error("Failed to mark all as read:", error);
    }
  };

  if (!isOpen) return null;

  const unreadCount = notifications.filter(n => !n.isRead).length;

  return (
    <>
      <div className="fixed inset-0 z-40 bg-transparent" onClick={onClose} />
      
      <div className="absolute top-[70px] right-0 w-[400px] bg-[#1A1A1A] border border-[#2A2A2A] rounded-[8px] shadow-[0_20px_50px_rgba(0,0,0,0.5)] z-50 overflow-hidden animate-in fade-in slide-in-from-top-2 duration-200">
        <div className="flex items-center justify-between p-5 border-b border-[#2A2A2A]">
          <h2 className="text-[18px] font-bold text-white">Notifications</h2>
          <div className="flex items-center gap-3">
            {unreadCount > 0 && (
              <span className="px-2.5 py-1 bg-[#A2F301] text-black text-[11px] font-bold rounded-full">
                {unreadCount} new
              </span>
            )}
            {unreadCount > 0 && (
              <button
                onClick={handleMarkAllRead}
                className="text-[12px] text-[#A2F301] font-medium hover:underline"
              >
                Mark all read
              </button>
            )}
          </div>
        </div>

        <div className="max-h-[480px] overflow-y-auto custom-scrollbar">
          {loading ? (
            <div className="p-10 text-center">
              <Loader2 className="w-5 h-5 text-[#A2F301] animate-spin mx-auto" />
            </div>
          ) : notifications.length === 0 ? (
            <div className="p-10 text-center text-[#666666] text-[14px]">
              No notifications yet
            </div>
          ) : (
            notifications.map((notif) => (
              <div 
                key={notif.id}
                onClick={() => !notif.isRead && handleMarkRead(notif.id)}
                className={`p-5 border-b border-[#2A2A2A] last:border-0 hover:bg-white/[0.02] cursor-pointer transition-colors relative ${
                  !notif.isRead ? "bg-[#A2F301]/[0.03]" : ""
                }`}
              >
                <div className="flex gap-3">
                  {!notif.isRead && (
                    <div className="w-2 h-2 rounded-full bg-[#A2F301] mt-2 flex-shrink-0" />
                  )}
                  <div className={!notif.isRead ? "" : "pl-5"}>
                    <div className="flex items-center gap-2 mb-1">
                      <h3 className="text-white font-bold text-[14px]">{notif.title}</h3>
                      <span className={`text-[10px] font-bold uppercase tracking-wider ${categoryColors[notif.category] || "text-[#666666]"}`}>
                        {categoryLabels[notif.category] || notif.category}
                      </span>
                    </div>
                    <p className="text-[#999999] text-[13px] mb-1.5">{notif.body}</p>
                    <span className="text-[#666666] text-[11px] uppercase tracking-wider font-medium">
                      {timeAgo(notif.createdAt)}
                    </span>
                  </div>
                </div>
              </div>
            ))
          )}
        </div>
      </div>
    </>
  );
}
