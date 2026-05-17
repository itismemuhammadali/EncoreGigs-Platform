"use client";

import React from "react";
import { X } from "lucide-react";

interface ScraperDetailsModalProps {
  isOpen: boolean;
  onClose: () => void;
  runData: any | null;
}

export function ScraperDetailsModal({ isOpen, onClose, runData }: ScraperDetailsModalProps) {
  if (!isOpen || !runData) return null;

  return (
    <div className="fixed inset-0 z-[100] flex items-center justify-center px-4">
      {/* Backdrop */}
      <div 
        className="absolute inset-0 bg-black/60 backdrop-blur-sm animate-in fade-in duration-300"
        onClick={onClose}
      />
      
      {/* Modal Content - Width 671.98px as per CSS */}
      <div className="bg-[#1A1A1A] w-full max-w-[671.98px] rounded-[8px] overflow-hidden relative z-10 shadow-2xl animate-in zoom-in-95 duration-300 border border-[#2A2A2A]">
        {/* Header - Height 69.02px as per CSS */}
        <div className="flex items-center justify-between px-[24px] h-[69.02px] border-b border-[#2A2A2A]">
          <h2 className="text-white text-[20px] font-semibold leading-[28px]">Scraper Run Details</h2>
          <button 
            onClick={onClose}
            className="w-9 h-9 rounded-[8px] border border-white flex items-center justify-center text-white hover:bg-white/5 transition-all"
          >
            <X className="w-[19px] h-[20px]" />
          </button>
        </div>

        {/* Content - Gap 16px as per CSS */}
        <div className="p-8 space-y-6">
          {/* Info Grid - Dual Column */}
          <div className="grid grid-cols-2 gap-x-16 gap-y-4">
            {/* Row 1 */}
            <div className="space-y-1">
              <p className="text-[#999999] text-[14px] leading-[20px]">Timestamp</p>
              <p className="text-white text-[14px] font-medium leading-[20px]">{runData.timestamp}</p>
            </div>
            <div className="space-y-1">
              <p className="text-[#999999] text-[14px] leading-[20px]">Source</p>
              <p className="text-white text-[14px] font-medium leading-[20px]">{runData.source}</p>
            </div>

            {/* Row 2 */}
            <div className="space-y-1">
              <p className="text-[#999999] text-[14px] leading-[20px]">Gigs Imported</p>
              <p className="text-[#A2F301] text-[14px] font-medium leading-[20px]">{runData.imported}</p>
            </div>
            <div className="space-y-1">
              <p className="text-[#999999] text-[14px] leading-[20px]">Errors</p>
              <p className="text-[#EF4444] text-[14px] font-medium leading-[20px]">{runData.errors}</p>
            </div>

            {/* Row 3 */}
            <div className="space-y-1">
              <p className="text-[#999999] text-[14px] leading-[20px]">Duration</p>
              <p className="text-white text-[14px] font-medium leading-[20px]">{runData.duration}</p>
            </div>
            <div className="space-y-1">
              <p className="text-[#999999] text-[14px] leading-[20px]">Status</p>
              <div className="flex items-center pt-0.5">
                <span className={`px-2 py-0.5 rounded-full text-[12px] font-medium lowercase ${
                  runData.status === 'success' ? 'bg-[#10B981]/10 text-[#10B981]' : 'bg-[#EF4444]/10 text-[#EF4444]'
                }`}>
                  {runData.status}
                </span>
              </div>
            </div>
          </div>

          {/* Error Log Section - Only visible if errors > 0 */}
          {runData.errors > 0 && (
            <div className="bg-[#EF4444]/10 border border-[#EF4444]/20 rounded-[8px] p-4 space-y-2">
              <p className="text-[#EF4444] text-[14px] font-medium leading-[20px]">Error Log:</p>
              <div className="space-y-1">
                <p className="text-[#999999] text-[12px] leading-[16px]">Connection timeout after 30s</p>
                <p className="text-[#999999] text-[12px] leading-[16px]">Rate limit exceeded (429)</p>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
