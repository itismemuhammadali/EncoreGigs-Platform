"use client";

import React from "react";

interface Notification {
  id: string;
  title: string;
  description: string;
  time: string;
  isUnread: boolean;
}

const MOCK_NOTIFICATIONS: Notification[] = [
  {
    id: "1",
    title: "New dispute filed",
    description: "DSP-005 requires your attention",
    time: "5 min ago",
    isUnread: true
  },
  {
    id: "2",
    title: "Payment processed",
    description: "Escrow payment of $2,500 completed",
    time: "1 hour ago",
    isUnread: true
  },
  {
    id: "3",
    title: "New user registered",
    description: "John Smith joined as musician",
    time: "2 hours ago",
    isUnread: false
  },
  {
    id: "4",
    title: "Review flagged",
    description: "A review has been flagged for moderation",
    time: "3 hours ago",
    isUnread: false
  },
  {
    id: "5",
    title: "Gig application",
    description: "8 new applications received",
    time: "5 hours ago",
    isUnread: false
  }
];

interface NotificationPanelProps {
  isOpen: boolean;
  onClose: () => void;
}

export function NotificationPanel({ isOpen, onClose }: NotificationPanelProps) {
  if (!isOpen) return null;

  return (
    <>
      {/* Overlay to close panel when clicking outside */}
      <div 
        className="fixed inset-0 z-40 bg-transparent" 
        onClick={onClose}
      />
      
      <div className="absolute top-[70px] right-0 w-[380px] bg-[#1A1A1A] border border-[#2A2A2A] rounded-[8px] shadow-[0_20px_50px_rgba(0,0,0,0.5)] z-50 overflow-hidden animate-in fade-in slide-in-from-top-2 duration-200">
        {/* Header */}
        <div className="flex items-center justify-between p-6 border-b border-[#2A2A2A]">
          <h2 className="text-[18px] font-bold text-white">Notifications</h2>
          <span className="px-2.5 py-1 bg-[#A2F301] text-black text-[11px] font-bold rounded-full">
            2 new
          </span>
        </div>

        {/* List */}
        <div className="max-h-[480px] overflow-y-auto custom-scrollbar">
          {MOCK_NOTIFICATIONS.map((notif, idx) => (
            <div 
              key={notif.id}
              className={`p-6 border-b border-[#2A2A2A] last:border-0 hover:bg-white/[0.02] cursor-pointer transition-colors relative ${
                notif.isUnread ? "bg-[#A2F301]/[0.03]" : ""
              }`}
            >
              <div className="flex gap-4">
                {notif.isUnread && (
                  <div className="w-2 h-2 rounded-full bg-[#A2F301] mt-2 flex-shrink-0" />
                )}
                <div className={notif.isUnread ? "" : "pl-6"}>
                  <h3 className="text-white font-bold text-[15px] mb-1">{notif.title}</h3>
                  <p className="text-[#999999] text-[13px] mb-2">{notif.description}</p>
                  <span className="text-[#666666] text-[11px] uppercase tracking-wider font-medium">
                    {notif.time}
                  </span>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </>
  );
}
