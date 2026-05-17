"use client";

import React, { useState, useEffect } from "react";
import { X } from "lucide-react";

interface EditGigModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSave: (data: any) => void;
  gig: {
    id: number;
    title: string;
    venue: string;
    date: string;
    budget: string;
    description?: string;
    requirements?: string;
  } | null;
}

export function EditGigModal({ isOpen, onClose, onSave, gig }: EditGigModalProps) {
  const [formData, setFormData] = useState({
    title: "",
    venue: "",
    date: "",
    budget: "",
    description: "",
    requirements: ""
  });

  useEffect(() => {
    if (gig) {
      setFormData({
        title: gig.title || "",
        venue: gig.venue || "",
        date: gig.date || "",
        budget: gig.budget || "",
        description: gig.description || "Looking for a talented jazz ensemble",
        requirements: gig.requirements || "3+ years experience"
      });
    }
  }, [gig]);

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
          <h2 className="text-white text-[20px] font-bold">Edit Gig</h2>
          <button 
            onClick={onClose}
            className="w-10 h-10 rounded-[8px] border border-white/10 flex items-center justify-center text-white hover:bg-white/5 transition-all"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Form Content */}
        <div className="p-8 space-y-6 max-h-[70vh] overflow-y-auto custom-scrollbar">
          {/* Title */}
          <div className="space-y-2">
            <label className="text-white text-[14px] font-medium">Title</label>
            <input 
              type="text"
              value={formData.title}
              onChange={(e) => setFormData(prev => ({ ...prev, title: e.target.value }))}
              className="w-full bg-white/[0.03] border border-white/10 rounded-[8px] px-4 py-3 text-white focus:outline-none focus:border-[#b3ff00]/50 transition-all"
            />
          </div>

          {/* Venue & Date */}
          <div className="grid grid-cols-2 gap-6">
            <div className="space-y-2">
              <label className="text-white text-[14px] font-medium">Venue</label>
              <input 
                type="text"
                value={formData.venue}
                onChange={(e) => setFormData(prev => ({ ...prev, venue: e.target.value }))}
                className="w-full bg-white/[0.03] border border-white/10 rounded-[8px] px-4 py-3 text-white focus:outline-none focus:border-[#b3ff00]/50 transition-all"
              />
            </div>
            <div className="space-y-2">
              <label className="text-white text-[14px] font-medium">Date</label>
              <input 
                type="text"
                value={formData.date}
                onChange={(e) => setFormData(prev => ({ ...prev, date: e.target.value }))}
                className="w-full bg-white/[0.03] border border-white/10 rounded-[8px] px-4 py-3 text-white focus:outline-none focus:border-[#b3ff00]/50 transition-all"
              />
            </div>
          </div>

          {/* Budget */}
          <div className="space-y-2">
            <label className="text-white text-[14px] font-medium">Budget</label>
            <input 
              type="text"
              value={formData.budget}
              onChange={(e) => setFormData(prev => ({ ...prev, budget: e.target.value }))}
              className="w-full bg-white/[0.03] border border-white/10 rounded-[8px] px-4 py-3 text-white focus:outline-none focus:border-[#b3ff00]/50 transition-all"
            />
          </div>

          {/* Description */}
          <div className="space-y-2">
            <label className="text-white text-[14px] font-medium">Description</label>
            <textarea 
              rows={4}
              value={formData.description}
              onChange={(e) => setFormData(prev => ({ ...prev, description: e.target.value }))}
              className="w-full bg-white/[0.03] border border-white/10 rounded-[8px] px-4 py-3 text-white focus:outline-none focus:border-[#b3ff00]/50 transition-all resize-none"
            />
          </div>

          {/* Requirements */}
          <div className="space-y-2">
            <label className="text-white text-[14px] font-medium">Requirements</label>
            <textarea 
              rows={3}
              value={formData.requirements}
              onChange={(e) => setFormData(prev => ({ ...prev, requirements: e.target.value }))}
              className="w-full bg-white/[0.03] border border-white/10 rounded-[8px] px-4 py-3 text-white focus:outline-none focus:border-[#b3ff00]/50 transition-all resize-none"
            />
          </div>
        </div>

        {/* Footer Buttons */}
        <div className="p-8 pt-4 flex gap-4 border-t border-white/5">
          <button 
            onClick={onClose}
            className="flex-1 py-4 rounded-[10px] bg-[#27272a] text-white font-bold text-[16px] hover:bg-[#323238] transition-all"
          >
            Cancel
          </button>
          <button 
            onClick={() => onSave(formData)}
            className="flex-1 py-4 rounded-[10px] bg-[#b3ff00] text-black font-bold text-[16px] hover:bg-[#a2e600] transition-all shadow-lg shadow-[#b3ff00]/20"
          >
            Save Changes
          </button>
        </div>
      </div>
    </div>
  );
}
