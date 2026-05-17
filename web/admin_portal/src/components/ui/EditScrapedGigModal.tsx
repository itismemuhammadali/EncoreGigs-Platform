"use client";

import React, { useState, useEffect } from "react";
import { X, ChevronDown } from "lucide-react";

interface EditScrapedGigModalProps {
  isOpen: boolean;
  onClose: () => void;
  gigData: any | null;
  onSave: (updatedGig: any) => void;
}

export function EditScrapedGigModal({ isOpen, onClose, gigData, onSave }: EditScrapedGigModalProps) {
  const [formData, setFormData] = useState({
    title: "",
    source: "",
    classification: "",
    isDuplicate: false,
    isSpam: false
  });

  useEffect(() => {
    if (gigData) {
      setFormData({
        title: gigData.title || "",
        source: gigData.source || "",
        classification: gigData.classification || "Source",
        isDuplicate: gigData.flags === "Duplicate",
        isSpam: gigData.flags === "Spam"
      });
    }
  }, [gigData]);

  if (!isOpen || !gigData) return null;

  return (
    <div className="fixed inset-0 z-[100] flex items-center justify-center px-4">
      {/* Backdrop */}
      <div 
        className="absolute inset-0 bg-black/60 backdrop-blur-sm animate-in fade-in duration-300"
        onClick={onClose}
      />
      
      {/* Modal Content - Width 670px as per CSS */}
      <div className="bg-[#1A1A1A] w-full max-w-[670px] rounded-[8px] overflow-hidden relative z-10 shadow-2xl animate-in zoom-in-95 duration-300 border border-[#2A2A2A]">
        {/* Header - Height 69.02px as per CSS */}
        <div className="flex items-center justify-between px-[24px] h-[69.02px] border-b border-[#2A2A2A]">
          <h2 className="text-white text-[20px] font-semibold leading-[28px]">Edit Scraped Gig</h2>
          <button 
            onClick={onClose}
            className="w-9 h-9 rounded-[8px] border border-white flex items-center justify-center text-white hover:bg-white/5 transition-all"
          >
            <X className="w-[19px] h-[20px]" />
          </button>
        </div>

        {/* Form Content */}
        <div className="p-8 space-y-6">
          {/* Title Input */}
          <div className="space-y-2">
            <label className="text-white text-[14px] font-medium leading-[20px]">Title</label>
            <input 
              type="text"
              value={formData.title}
              onChange={(e) => setFormData({ ...formData, title: e.target.value })}
              className="w-full h-[48px] bg-[#1A1A1A] border border-[#2A2A2A] rounded-[8px] px-3 text-white text-[16px] focus:outline-none focus:border-[#b3ff00]/50 transition-all"
            />
          </div>

          {/* Source Input */}
          <div className="space-y-2">
            <label className="text-white text-[14px] font-medium leading-[20px]">Source</label>
            <input 
              type="text"
              value={formData.source}
              onChange={(e) => setFormData({ ...formData, source: e.target.value })}
              className="w-full h-[48px] bg-[#1A1A1A] border border-[#2A2A2A] rounded-[8px] px-3 text-white text-[16px] focus:outline-none focus:border-[#b3ff00]/50 transition-all"
            />
          </div>

          {/* Classification Dropdown */}
          <div className="space-y-2">
            <label className="text-white text-[14px] font-medium leading-[20px]">Classification</label>
            <div className="relative">
              <select 
                value={formData.classification}
                onChange={(e) => setFormData({ ...formData, classification: e.target.value })}
                className="w-full h-[44px] bg-[#1A1A1A] border border-[#2A2A2A] rounded-[8px] px-3 text-white text-[14px] font-medium appearance-none focus:outline-none focus:border-[#b3ff00]/50 transition-all"
              >
                <option value="Source">Source</option>
                <option value="Jazz">Jazz</option>
                <option value="Rock">Rock</option>
                <option value="Wedding">Wedding</option>
                <option value="Spam">Spam</option>
              </select>
              <ChevronDown className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-white pointer-events-none" />
            </div>
          </div>

          {/* Checkboxes */}
          <div className="flex items-center gap-6 pt-2">
            <label className="flex items-center gap-2 cursor-pointer group">
              <div className="relative">
                <input 
                  type="checkbox"
                  checked={formData.isDuplicate}
                  onChange={(e) => setFormData({ ...formData, isDuplicate: e.target.checked, isSpam: false })}
                  className="peer hidden"
                />
                <div className="w-4 h-4 border border-white rounded-[4px] peer-checked:bg-[#b3ff00] peer-checked:border-[#b3ff00] transition-all flex items-center justify-center">
                  {formData.isDuplicate && <div className="w-2 h-2 bg-black rounded-[1px]" />}
                </div>
              </div>
              <span className="text-white text-[14px] font-medium leading-[20px]">Mark as Duplicate</span>
            </label>

            <label className="flex items-center gap-2 cursor-pointer group">
              <div className="relative">
                <input 
                  type="checkbox"
                  checked={formData.isSpam}
                  onChange={(e) => setFormData({ ...formData, isSpam: e.target.checked, isDuplicate: false })}
                  className="peer hidden"
                />
                <div className="w-4 h-4 border border-white rounded-[4px] peer-checked:bg-[#ef4444] peer-checked:border-[#ef4444] transition-all flex items-center justify-center">
                  {formData.isSpam && <div className="w-2 h-2 bg-black rounded-[1px]" />}
                </div>
              </div>
              <span className="text-white text-[14px] font-medium leading-[20px]">Mark as Spam</span>
            </label>
          </div>

          {/* Action Footer */}
          <div className="flex justify-end pt-4">
            <button 
              onClick={() => onSave({
                ...gigData,
                title: formData.title,
                source: formData.source,
                classification: formData.classification,
                flags: formData.isSpam ? "Spam" : formData.isDuplicate ? "Duplicate" : "None"
              })}
              className="bg-[#b3ff00] text-black px-8 py-2.5 rounded-[8px] font-bold hover:bg-[#a2e600] transition-all shadow-lg shadow-[#b3ff00]/10"
            >
              Save Changes
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
