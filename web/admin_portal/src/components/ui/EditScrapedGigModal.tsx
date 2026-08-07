"use client";

import React, { useState, useEffect } from "react";
import { X, ChevronDown, ExternalLink } from "lucide-react";

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
    sourceUrl: "",
    classification: "",
    budget: "",
    location: "",
    description: "",
    contactEmail: "",
    contactPhone: "",
    date: "",
    duration: "",
    isDuplicate: false,
    isSpam: false
  });

  useEffect(() => {
    if (gigData) {
      setFormData({
        title: gigData.title || "",
        source: gigData.source || "",
        sourceUrl: gigData.sourceUrl || gigData.url || "",
        classification: gigData.classification || "Source",
        budget: gigData.budget || "",
        location: gigData.location || "",
        description: gigData.description || "",
        contactEmail: gigData.contactEmail || gigData.externalContactEmail || "",
        contactPhone: gigData.contactPhone || gigData.externalContactPhone || "",
        date: gigData.date || "",
        duration: gigData.duration || "",
        isDuplicate: gigData.flags === "Duplicate",
        isSpam: gigData.flags === "Spam"
      });
    }
  }, [gigData]);

  if (!isOpen || !gigData) return null;

  return (
    <div className="fixed inset-0 z-[100] flex items-center justify-center px-4 overflow-y-auto py-10">
      {/* Backdrop */}
      <div 
        className="fixed inset-0 bg-black/70 backdrop-blur-sm animate-in fade-in duration-300"
        onClick={onClose}
      />
      
      {/* Modal Content */}
      <div className="bg-[#1A1A1A] w-full max-w-[720px] rounded-[12px] overflow-hidden relative z-10 shadow-2xl animate-in zoom-in-95 duration-300 border border-[#2A2A2A] max-h-[90vh] flex flex-col">
        {/* Header */}
        <div className="flex items-center justify-between px-6 py-4 border-b border-[#2A2A2A] bg-[#141414] shrink-0">
          <div>
            <h2 className="text-white text-lg font-bold">Scraped Gig Details & Edit</h2>
            <p className="text-xs text-zinc-400">Admin view of entire scraped listing details</p>
          </div>
          <button 
            onClick={onClose}
            className="w-8 h-8 rounded-lg border border-zinc-700 flex items-center justify-center text-zinc-400 hover:text-white hover:bg-white/5 transition-all"
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        {/* Form Content */}
        <div className="p-6 space-y-5 overflow-y-auto custom-scrollbar flex-1">
          {/* Source URL Banner */}
          {formData.sourceUrl && (
            <div className="p-3 bg-[#242424] border border-[#333] rounded-lg flex items-center justify-between gap-4">
              <span className="text-xs text-zinc-300 font-mono truncate">
                Source URL: {formData.sourceUrl}
              </span>
              <a 
                href={formData.sourceUrl} 
                target="_blank" 
                rel="noopener noreferrer"
                className="flex items-center gap-1.5 text-xs font-bold text-[#b3ff00] hover:underline shrink-0 bg-[#b3ff00]/10 px-3 py-1.5 rounded border border-[#b3ff00]/20"
              >
                Open Original Source <ExternalLink className="w-3 h-3" />
              </a>
            </div>
          )}

          {/* Title & Source */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="space-y-1.5">
              <label className="text-zinc-300 text-xs font-medium">Gig Title</label>
              <input 
                type="text"
                value={formData.title}
                onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                className="w-full h-10 bg-[#141414] border border-[#2A2A2A] rounded-lg px-3 text-white text-sm focus:outline-none focus:border-[#b3ff00]/50 transition-all"
              />
            </div>

            <div className="space-y-1.5">
              <label className="text-zinc-300 text-xs font-medium">Source Platform</label>
              <input 
                type="text"
                value={formData.source}
                onChange={(e) => setFormData({ ...formData, source: e.target.value })}
                className="w-full h-10 bg-[#141414] border border-[#2A2A2A] rounded-lg px-3 text-white text-sm focus:outline-none focus:border-[#b3ff00]/50 transition-all"
              />
            </div>
          </div>

          {/* Budget, Location, Date */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="space-y-1.5">
              <label className="text-zinc-300 text-xs font-medium">Budget / Pay Range</label>
              <input 
                type="text"
                value={formData.budget}
                onChange={(e) => setFormData({ ...formData, budget: e.target.value })}
                placeholder="e.g. $250 / night"
                className="w-full h-10 bg-[#141414] border border-[#2A2A2A] rounded-lg px-3 text-white text-sm focus:outline-none focus:border-[#b3ff00]/50 transition-all"
              />
            </div>

            <div className="space-y-1.5">
              <label className="text-zinc-300 text-xs font-medium">Location / Venue</label>
              <input 
                type="text"
                value={formData.location}
                onChange={(e) => setFormData({ ...formData, location: e.target.value })}
                placeholder="e.g. Austin, TX"
                className="w-full h-10 bg-[#141414] border border-[#2A2A2A] rounded-lg px-3 text-white text-sm focus:outline-none focus:border-[#b3ff00]/50 transition-all"
              />
            </div>

            <div className="space-y-1.5">
              <label className="text-zinc-300 text-xs font-medium">Date & Duration</label>
              <input 
                type="text"
                value={formData.date}
                onChange={(e) => setFormData({ ...formData, date: e.target.value })}
                placeholder="e.g. Aug 15, 2026 (3 hrs)"
                className="w-full h-10 bg-[#141414] border border-[#2A2A2A] rounded-lg px-3 text-white text-sm focus:outline-none focus:border-[#b3ff00]/50 transition-all"
              />
            </div>
          </div>

          {/* Contact Details (Admin Only View) */}
          <div className="p-4 bg-[#222222] border border-[#333] rounded-lg space-y-3">
            <div className="flex items-center justify-between">
              <span className="text-xs font-bold text-[#b3ff00] uppercase tracking-wider">🔒 Admin-Only Contact Details</span>
              <span className="text-[11px] text-zinc-400">Not shown to public users</span>
            </div>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
              <div>
                <label className="text-zinc-400 text-[11px]">Scraped Contact Email</label>
                <input 
                  type="email"
                  value={formData.contactEmail}
                  onChange={(e) => setFormData({ ...formData, contactEmail: e.target.value })}
                  placeholder="e.g. poster@craigslist.org"
                  className="w-full h-9 bg-[#141414] border border-[#333] rounded px-2.5 text-white text-xs focus:outline-none focus:border-[#b3ff00]"
                />
              </div>
              <div>
                <label className="text-zinc-400 text-[11px]">Scraped Phone Number</label>
                <input 
                  type="text"
                  value={formData.contactPhone}
                  onChange={(e) => setFormData({ ...formData, contactPhone: e.target.value })}
                  placeholder="e.g. +1 555-0199"
                  className="w-full h-9 bg-[#141414] border border-[#333] rounded px-2.5 text-white text-xs focus:outline-none focus:border-[#b3ff00]"
                />
              </div>
            </div>
          </div>

          {/* Full Description */}
          <div className="space-y-1.5">
            <label className="text-zinc-300 text-xs font-medium">Full Listing Description</label>
            <textarea 
              rows={4}
              value={formData.description}
              onChange={(e) => setFormData({ ...formData, description: e.target.value })}
              placeholder="Full description extracted from original listing..."
              className="w-full bg-[#141414] border border-[#2A2A2A] rounded-lg p-3 text-white text-sm focus:outline-none focus:border-[#b3ff00]/50 transition-all custom-scrollbar"
            />
          </div>

          {/* Classification Dropdown & Flags */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 items-center">
            <div className="space-y-1.5">
              <label className="text-zinc-300 text-xs font-medium">AI Classification / Genre</label>
              <div className="relative">
                <select 
                  value={formData.classification}
                  onChange={(e) => setFormData({ ...formData, classification: e.target.value })}
                  className="w-full h-10 bg-[#141414] border border-[#2A2A2A] rounded-lg px-3 text-white text-sm font-medium appearance-none focus:outline-none focus:border-[#b3ff00]/50 transition-all"
                >
                  <option value="Source">Source</option>
                  <option value="Jazz">Jazz</option>
                  <option value="Rock">Rock</option>
                  <option value="Wedding">Wedding</option>
                  <option value="Acoustic">Acoustic</option>
                  <option value="DJ">DJ</option>
                  <option value="Spam">Spam</option>
                </select>
                <ChevronDown className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-zinc-400 pointer-events-none" />
              </div>
            </div>

            {/* Checkboxes */}
            <div className="flex items-center gap-6 pt-5">
              <label className="flex items-center gap-2 cursor-pointer group">
                <input 
                  type="checkbox"
                  checked={formData.isDuplicate}
                  onChange={(e) => setFormData({ ...formData, isDuplicate: e.target.checked, isSpam: false })}
                  className="w-4 h-4 accent-[#b3ff00] rounded cursor-pointer"
                />
                <span className="text-zinc-300 text-xs font-medium">Mark as Duplicate</span>
              </label>

              <label className="flex items-center gap-2 cursor-pointer group">
                <input 
                  type="checkbox"
                  checked={formData.isSpam}
                  onChange={(e) => setFormData({ ...formData, isSpam: e.target.checked, isDuplicate: false })}
                  className="w-4 h-4 accent-[#ef4444] rounded cursor-pointer"
                />
                <span className="text-zinc-300 text-xs font-medium">Mark as Spam</span>
              </label>
            </div>
          </div>
        </div>

        {/* Action Footer */}
        <div className="flex items-center justify-between px-6 py-4 border-t border-[#2A2A2A] bg-[#141414] shrink-0">
          <button 
            onClick={onClose}
            className="px-5 py-2 rounded-lg text-xs text-zinc-400 hover:text-white transition-all"
          >
            Cancel
          </button>
          <button 
            onClick={() => onSave({
              ...gigData,
              title: formData.title,
              source: formData.source,
              sourceUrl: formData.sourceUrl,
              classification: formData.classification,
              budget: formData.budget,
              location: formData.location,
              description: formData.description,
              contactEmail: formData.contactEmail,
              contactPhone: formData.contactPhone,
              date: formData.date,
              flags: formData.isSpam ? "Spam" : formData.isDuplicate ? "Duplicate" : "None"
            })}
            className="bg-[#b3ff00] text-black px-6 py-2.5 rounded-lg font-bold text-sm hover:bg-[#a2e600] transition-all shadow-lg shadow-[#b3ff00]/10"
          >
            Save Changes
          </button>
        </div>
      </div>
    </div>
  );
}
