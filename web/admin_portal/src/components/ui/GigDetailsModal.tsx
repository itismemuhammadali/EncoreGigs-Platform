"use client";

import React from "react";
import { X, MapPin, Calendar, DollarSign, Users } from "lucide-react";

interface GigDetailsModalProps {
  isOpen: boolean;
  onClose: () => void;
  gig: {
    title: string;
    type: string;
    venue: string;
    date: string;
    budget: string;
    applicants: number;
    status: string;
    description?: string;
    requirements?: string;
  } | null;
}

export function GigDetailsModal({ isOpen, onClose, gig }: GigDetailsModalProps) {
  if (!isOpen || !gig) return null;

  return (
    <div className="fixed inset-0 z-[100] flex items-center justify-center px-4">
      {/* Backdrop */}
      <div 
        className="absolute inset-0 bg-black/60 backdrop-blur-sm animate-in fade-in duration-300"
        onClick={onClose}
      />
      
      {/* Modal Content */}
      <div className="bg-[#1A1A1A] w-full max-w-[800px] rounded-[12px] overflow-hidden relative z-10 shadow-2xl animate-in zoom-in-95 duration-300 border border-white/5">
        {/* Header */}
        <div className="flex items-center justify-between p-6 border-b border-white/5">
          <h2 className="text-white text-[20px] font-bold">Gig Details</h2>
          <button 
            onClick={onClose}
            className="w-10 h-10 rounded-[8px] border border-white/10 flex items-center justify-center text-white hover:bg-white/5 transition-all"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Content */}
        <div className="p-8 space-y-8 max-h-[80vh] overflow-y-auto custom-scrollbar">
          {/* Title and Badges */}
          <div>
            <h3 className="text-white text-[28px] font-bold mb-4">{gig.title}</h3>
            <div className="flex gap-3">
              <span className="px-4 py-1.5 rounded-full bg-[#b3ff00]/10 text-[#b3ff00] text-[13px] font-bold">
                {gig.type}
              </span>
              <span className="px-4 py-1.5 rounded-full bg-[#10b981]/10 text-[#10b981] text-[13px] font-bold">
                {gig.status}
              </span>
            </div>
          </div>

          {/* Info Grid */}
          <div className="grid grid-cols-2 gap-y-8">
            <div className="flex items-start gap-4">
              <div className="w-10 h-10 rounded-full flex items-center justify-center text-[#b3ff00]">
                <MapPin className="w-6 h-6" />
              </div>
              <div>
                <p className="text-[#a1a1aa] text-[13px] font-medium mb-1">Location</p>
                <p className="text-white text-[16px] font-bold">{gig.venue}</p>
              </div>
            </div>

            <div className="flex items-start gap-4">
              <div className="w-10 h-10 rounded-full flex items-center justify-center text-[#b3ff00]">
                <DollarSign className="w-6 h-6" />
              </div>
              <div>
                <p className="text-[#a1a1aa] text-[13px] font-medium mb-1">Budget</p>
                <p className="text-white text-[16px] font-bold">{gig.budget}</p>
              </div>
            </div>

            <div className="flex items-start gap-4">
              <div className="w-10 h-10 rounded-full flex items-center justify-center text-[#b3ff00]">
                <Calendar className="w-6 h-6" />
              </div>
              <div>
                <p className="text-[#a1a1aa] text-[13px] font-medium mb-1">Date</p>
                <p className="text-white text-[16px] font-bold">{gig.date}</p>
              </div>
            </div>

            <div className="flex items-start gap-4">
              <div className="w-10 h-10 rounded-full flex items-center justify-center text-[#b3ff00]">
                <Users className="w-6 h-6" />
              </div>
              <div>
                <p className="text-[#a1a1aa] text-[13px] font-medium mb-1">Applicants</p>
                <p className="text-white text-[16px] font-bold">{gig.applicants}</p>
              </div>
            </div>
          </div>

          {/* Description */}
          <div className="space-y-3">
            <h4 className="text-white text-[16px] font-bold">Description</h4>
            <p className="text-[#a1a1aa] text-[15px] leading-relaxed">
              {gig.description || "Looking for a talented jazz ensemble to perform for an evening event. The performance will consist of two sets with a short break in between."}
            </p>
          </div>

          {/* Requirements */}
          <div className="space-y-3">
            <h4 className="text-white text-[16px] font-bold">Requirements</h4>
            <p className="text-[#a1a1aa] text-[15px] leading-relaxed">
              {gig.requirements || "3+ years experience performing in professional settings. Own equipment required."}
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
