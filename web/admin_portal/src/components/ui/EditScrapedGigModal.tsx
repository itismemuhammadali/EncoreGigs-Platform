"use client";

import React, { useState, useEffect, useMemo } from "react";
import { 
  X, 
  ChevronDown, 
  ExternalLink, 
  Copy, 
  Check, 
  Calendar, 
  Clock, 
  DollarSign, 
  Users, 
  Music, 
  Phone, 
  FileText, 
  Trash2, 
  ChevronLeft, 
  ChevronRight, 
  AlertCircle,
  ThumbsUp,
  MessageCircle,
  Share2,
  Sparkles,
  MapPin,
  Building
} from "lucide-react";

interface EditScrapedGigModalProps {
  isOpen: boolean;
  onClose: () => void;
  gigData: any | null;
  gigsList?: any[];
  currentIndex?: number;
  onNavigate?: (index: number) => void;
  onSave: (updatedGig: any) => Promise<void> | void;
  onApprove?: (gigId: string) => Promise<void> | void;
  onDelete?: (gigId: string) => Promise<void> | void;
}

const US_STATES = [
  "AL", "AK", "AZ", "AR", "CA", "CO", "CT", "DE", "FL", "GA",
  "HI", "ID", "IL", "IN", "IA", "KS", "KY", "LA", "ME", "MD",
  "MA", "MI", "MN", "MS", "MO", "MT", "NE", "NV", "NH", "NJ",
  "NM", "NY", "NC", "ND", "OH", "OK", "OR", "PA", "RI", "SC",
  "SD", "TN", "TX", "UT", "VT", "VA", "WA", "WV", "WI", "WY"
];

const DEFAULT_GENRES = [
  "Country", "Rock", "R&B", "Swamp Pop", "Zydeco", 
  "Variety", "Blues", "Soul", "Classic Hits", "Karaoke", 
  "Jazz", "Acoustic", "Pop"
];

const PERFORMER_TYPES = ["Solo", "Duo", "Trio", "Band", "DJ", "Any"];

// Common US Musician Hub Zip Code Fast Lookup
const COMMON_ZIP_LOOKUP: Record<string, { city: string; state: string }> = {
  "78701": { city: "Austin", state: "TX" },
  "78702": { city: "Austin", state: "TX" },
  "78704": { city: "Austin", state: "TX" },
  "78745": { city: "Austin", state: "TX" },
  "70501": { city: "Lafayette", state: "LA" },
  "70503": { city: "Lafayette", state: "LA" },
  "70506": { city: "Lafayette", state: "LA" },
  "70112": { city: "New Orleans", state: "LA" },
  "70116": { city: "New Orleans", state: "LA" },
  "70119": { city: "New Orleans", state: "LA" },
  "70130": { city: "New Orleans", state: "LA" },
  "37201": { city: "Nashville", state: "TN" },
  "37203": { city: "Nashville", state: "TN" },
  "37206": { city: "Nashville", state: "TN" },
  "37212": { city: "Nashville", state: "TN" },
  "90028": { city: "Los Angeles", state: "CA" },
  "90001": { city: "Los Angeles", state: "CA" },
  "10001": { city: "New York", state: "NY" },
  "10012": { city: "New York", state: "NY" },
  "77002": { city: "Houston", state: "TX" },
  "75201": { city: "Dallas", state: "TX" },
  "30303": { city: "Atlanta", state: "GA" },
  "60601": { city: "Chicago", state: "IL" },
};

function capitalizeWords(str: string): string {
  if (!str) return str;
  return str.replace(/\b\w+/g, (w) => {
    if (w.length <= 3 && w === w.toUpperCase()) return w;
    return w.charAt(0).toUpperCase() + w.slice(1).toLowerCase();
  });
}

function calculateDuration(startTime: string, endTime: string): string {
  if (!startTime || !endTime) return "";
  try {
    const parseTime = (t: string) => {
      const match = t.match(/(\d+):?(\d*)\s*(am|pm)?/i);
      if (!match) return null;
      let hours = parseInt(match[1], 10);
      const minutes = match[2] ? parseInt(match[2], 10) : 0;
      const meridiem = match[3] ? match[3].toLowerCase() : null;

      if (meridiem === "pm" && hours < 12) hours += 12;
      if (meridiem === "am" && hours === 12) hours = 0;
      return hours + minutes / 60;
    };

    const start = parseTime(startTime);
    const end = parseTime(endTime);

    if (start === null || end === null) return "";

    let diff = end - start;
    if (diff < 0) diff += 24; // Spanning midnight

    if (diff === 0) return "";
    return diff % 1 === 0 ? `${diff} hrs` : `${diff.toFixed(1)} hrs`;
  } catch {
    return "";
  }
}

export function EditScrapedGigModal({
  isOpen,
  onClose,
  gigData,
  gigsList = [],
  currentIndex = 0,
  onNavigate,
  onSave,
  onApprove,
  onDelete
}: EditScrapedGigModalProps) {
  const [formData, setFormData] = useState({
    posterName: "",
    title: "",
    source: "Facebook",
    sourceUrl: "",
    venue: "",
    venueNotListed: false,
    zip: "",
    city: "",
    state: "TX",
    date: "",
    startTime: "08:00 PM",
    endTime: "11:00 PM",
    duration: "3 hrs",
    minPay: "",
    maxPay: "",
    payNotListed: false,
    lookingFor: ["Band"],
    genres: ["Rock"],
    contactName: "",
    contactPhone: "",
    contactEmail: "",
    contactViaFb: true,
    profileUrl: "",
    description: "",
    classification: "Rock",
    isDuplicate: false,
    isSpam: false,
    missingDetails: false,
  });

  const [copiedUrl, setCopiedUrl] = useState(false);
  const [newGenreInput, setNewGenreInput] = useState("");
  const [showAddGenre, setShowAddGenre] = useState(false);
  const [isSaving, setIsSaving] = useState(false);
  const [isPublishing, setIsPublishing] = useState(false);
  const [isDeleting, setIsDeleting] = useState(false);
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false);

  // Initialize form state when gigData changes
  useEffect(() => {
    if (gigData) {
      const rawLocation = gigData.location || gigData.venue || "";
      let city = gigData.city || "";
      let state = gigData.state || "TX";
      let venue = gigData.venue || "";

      // Attempt to extract city and state from raw location if not separated
      if (!city && rawLocation.includes(",")) {
        const parts = rawLocation.split(",");
        city = parts[0].trim();
        const stateCandidate = parts[1].trim().split(" ")[0].toUpperCase();
        if (US_STATES.includes(stateCandidate)) {
          state = stateCandidate;
        }
      } else if (!city && rawLocation) {
        city = rawLocation;
      }

      const budgetStr = gigData.budget || "";
      let minPay = gigData.minPay || "";
      let maxPay = gigData.maxPay || "";
      if (!minPay && budgetStr) {
        const numbers = budgetStr.match(/\d[\d,]*/g);
        if (numbers && numbers.length >= 2) {
          minPay = numbers[0].replace(/,/g, "");
          maxPay = numbers[1].replace(/,/g, "");
        } else if (numbers && numbers.length === 1) {
          minPay = numbers[0].replace(/,/g, "");
        }
      }

      const posterName = gigData.posterName || gigData.contactName || gigData.organizerName || (gigData.title?.includes(" - ") ? gigData.title.split(" - ")[0] : "Ronald P Johnson");
      const title = capitalizeWords(gigData.title || "");
      const startTime = gigData.startTime || "08:00 PM";
      const endTime = gigData.endTime || "11:00 PM";
      const autoDuration = gigData.duration || calculateDuration(startTime, endTime) || "3 hrs";

      setFormData({
        posterName,
        title,
        source: gigData.source || "Facebook",
        sourceUrl: gigData.sourceUrl || gigData.source_url || gigData.url || gigData.link || "",
        venue: venue || (rawLocation.includes(",") ? "" : rawLocation),
        venueNotListed: Boolean(gigData.venueNotListed),
        zip: gigData.zip || "",
        city: capitalizeWords(city || "Austin"),
        state: state || "TX",
        date: gigData.date || "",
        startTime,
        endTime,
        duration: autoDuration,
        minPay,
        maxPay,
        payNotListed: Boolean(gigData.payNotListed || (!minPay && !maxPay && budgetStr.toLowerCase().includes("tbd"))),
        lookingFor: Array.isArray(gigData.lookingFor) && gigData.lookingFor.length > 0 ? gigData.lookingFor : ["Band"],
        genres: Array.isArray(gigData.genres) && gigData.genres.length > 0 ? gigData.genres : [gigData.classification || "Rock"],
        contactName: gigData.contactName || posterName,
        contactPhone: gigData.contactPhone || gigData.externalContactPhone || "",
        contactEmail: gigData.contactEmail || gigData.externalContactEmail || "",
        contactViaFb: gigData.contactViaFb !== undefined ? Boolean(gigData.contactViaFb) : true,
        profileUrl: gigData.profileUrl || gigData.organizerProfileUrl || "",
        description: gigData.description || "",
        classification: gigData.classification || "Rock",
        isDuplicate: gigData.flags === "Duplicate",
        isSpam: gigData.flags === "Spam",
        missingDetails: Boolean(gigData.flags === "MissingDetails"),
      });

      setShowDeleteConfirm(false);
    }
  }, [gigData]);

  // Auto-populate City & State from Zip Code
  const handleZipChange = async (val: string) => {
    const cleaned = val.replace(/\D/g, "").slice(0, 5);
    setFormData(prev => ({ ...prev, zip: cleaned }));

    if (cleaned.length === 5) {
      if (COMMON_ZIP_LOOKUP[cleaned]) {
        const match = COMMON_ZIP_LOOKUP[cleaned];
        setFormData(prev => ({
          ...prev,
          city: match.city,
          state: match.state
        }));
        return;
      }

      // Online fallback using public US zip api
      try {
        const res = await fetch(`https://api.zippopotam.us/us/${cleaned}`);
        if (res.ok) {
          const data = await res.json();
          if (data.places && data.places.length > 0) {
            const place = data.places[0];
            setFormData(prev => ({
              ...prev,
              city: place["place name"] || prev.city,
              state: place["state abbreviation"] || prev.state
            }));
          }
        }
      } catch (err) {
        // Silent fallback
      }
    }
  };

  // Auto calculate duration on time changes
  const handleStartTimeChange = (val: string) => {
    const dur = calculateDuration(val, formData.endTime);
    setFormData(prev => ({
      ...prev,
      startTime: val,
      duration: dur || prev.duration
    }));
  };

  const handleEndTimeChange = (val: string) => {
    const dur = calculateDuration(formData.startTime, val);
    setFormData(prev => ({
      ...prev,
      endTime: val,
      duration: dur || prev.duration
    }));
  };

  const handleCopyUrl = () => {
    if (formData.sourceUrl) {
      navigator.clipboard.writeText(formData.sourceUrl);
      setCopiedUrl(true);
      setTimeout(() => setCopiedUrl(false), 2000);
    }
  };

  const toggleLookingFor = (type: string) => {
    setFormData(prev => {
      const exists = prev.lookingFor.includes(type);
      return {
        ...prev,
        lookingFor: exists 
          ? prev.lookingFor.filter(t => t !== type)
          : [...prev.lookingFor, type]
      };
    });
  };

  const toggleGenre = (genre: string) => {
    setFormData(prev => {
      const exists = prev.genres.includes(genre);
      const newGenres = exists 
        ? prev.genres.filter(g => g !== genre)
        : [...prev.genres, genre];
      return {
        ...prev,
        genres: newGenres.length > 0 ? newGenres : [genre],
        classification: newGenres[0] || prev.classification
      };
    });
  };

  const handleAddNewGenre = () => {
    const trimmed = newGenreInput.trim();
    if (trimmed && !formData.genres.includes(trimmed)) {
      setFormData(prev => ({
        ...prev,
        genres: [...prev.genres, trimmed]
      }));
      setNewGenreInput("");
      setShowAddGenre(false);
    }
  };

  const handleCopyFromSource = () => {
    if (gigData?.description) {
      setFormData(prev => ({
        ...prev,
        description: gigData.description
      }));
    }
  };

  const getPayload = () => {
    const combinedBudget = formData.payNotListed 
      ? "Not listed" 
      : formData.minPay && formData.maxPay 
        ? `$${formData.minPay} - $${formData.maxPay}` 
        : formData.minPay 
          ? `$${formData.minPay}` 
          : "Not listed";

    const combinedLocation = formData.venue && !formData.venueNotListed 
      ? `${formData.venue}, ${formData.city}, ${formData.state}` 
      : `${formData.city}, ${formData.state}`;

    return {
      ...gigData,
      title: formData.title,
      posterName: formData.posterName,
      source: formData.source,
      sourceUrl: formData.sourceUrl,
      venue: formData.venueNotListed ? "Venue not listed" : formData.venue,
      venueNotListed: formData.venueNotListed,
      city: formData.city,
      state: formData.state,
      zip: formData.zip,
      location: combinedLocation,
      date: formData.date,
      startTime: formData.startTime,
      endTime: formData.endTime,
      duration: formData.duration,
      minPay: formData.minPay,
      maxPay: formData.maxPay,
      payNotListed: formData.payNotListed,
      budget: combinedBudget,
      lookingFor: formData.lookingFor,
      genres: formData.genres,
      contactName: formData.contactName,
      contactPhone: formData.contactPhone,
      contactEmail: formData.contactEmail,
      contactViaFb: formData.contactViaFb,
      profileUrl: formData.profileUrl,
      description: formData.description,
      classification: formData.classification,
      flags: formData.isSpam ? "Spam" : formData.isDuplicate ? "Duplicate" : formData.missingDetails ? "MissingDetails" : "None"
    };
  };

  const handleSaveDraft = async () => {
    setIsSaving(true);
    try {
      await onSave(getPayload());
      onClose();
    } finally {
      setIsSaving(false);
    }
  };

  const handlePublishAndNext = async () => {
    setIsPublishing(true);
    try {
      const payload = getPayload();
      await onSave(payload);
      if (onApprove && gigData?.id) {
        await onApprove(gigData.id);
      }
      
      // Navigate to next gig if available
      if (onNavigate && currentIndex < gigsList.length - 1) {
        onNavigate(currentIndex + 1);
      } else {
        onClose();
      }
    } finally {
      setIsPublishing(false);
    }
  };

  const handleSkip = () => {
    if (onNavigate && currentIndex < gigsList.length - 1) {
      onNavigate(currentIndex + 1);
    } else {
      onClose();
    }
  };

  const handleDelete = async () => {
    if (!onDelete || !gigData?.id) return;
    setIsDeleting(true);
    try {
      await onDelete(gigData.id);
      // Close the modal immediately after deletion — no navigation to avoid race condition
      onClose();
    } finally {
      setIsDeleting(false);
      setShowDeleteConfirm(false);
    }
  };

  if (!isOpen || !gigData) return null;

  const totalGigs = gigsList.length || 1;
  const displayIndex = currentIndex + 1;

  return (
    <div className="fixed inset-0 z-[100] flex items-center justify-center px-3 sm:px-6 overflow-y-auto py-6">
      {/* Backdrop */}
      <div 
        className="fixed inset-0 bg-black/85 backdrop-blur-md animate-in fade-in duration-300"
        onClick={onClose}
      />
      
      {/* Modal Dialog */}
      <div className="bg-[#121214] w-full max-w-[1240px] rounded-2xl overflow-hidden relative z-10 shadow-2xl animate-in zoom-in-95 duration-200 border border-[#27272a] max-h-[92vh] flex flex-col">
        
        {/* ================= HEADER ================= */}
        <div className="flex items-center justify-between px-6 py-3.5 border-b border-[#27272a] bg-[#161619] shrink-0">
          <div>
            <h2 className="text-white text-lg font-bold flex items-center gap-2">
              Add / Review Scraped Gig
            </h2>
            <p className="text-xs text-zinc-400">Review the source post, confirm details, and publish to OnlyGigz.</p>
          </div>

          <div className="flex items-center gap-4">
            {/* Carousel / Navigation Counter */}
            {gigsList.length > 0 && (
              <div className="flex items-center gap-1.5 bg-[#1F1F24] border border-[#2e2e33] rounded-lg px-2.5 py-1">
                <button
                  type="button"
                  onClick={() => onNavigate && currentIndex > 0 && onNavigate(currentIndex - 1)}
                  disabled={currentIndex === 0}
                  className="p-1 rounded text-zinc-400 hover:text-white disabled:opacity-30 disabled:hover:text-zinc-400 transition-colors"
                >
                  <ChevronLeft className="w-4 h-4" />
                </button>
                <span className="text-xs font-semibold text-zinc-200 font-mono px-1">
                  {displayIndex} of {totalGigs}
                </span>
                <button
                  type="button"
                  onClick={() => onNavigate && currentIndex < gigsList.length - 1 && onNavigate(currentIndex + 1)}
                  disabled={currentIndex >= gigsList.length - 1}
                  className="p-1 rounded text-zinc-400 hover:text-white disabled:opacity-30 disabled:hover:text-zinc-400 transition-colors"
                >
                  <ChevronRight className="w-4 h-4" />
                </button>
              </div>
            )}

            {/* Status Pill */}
            <div className={`px-2.5 py-1 rounded-full text-[11px] font-bold border flex items-center gap-1.5 ${
              gigData.publishedToApp 
                ? "bg-emerald-500/10 text-emerald-400 border-emerald-500/20"
                : "bg-amber-500/10 text-amber-400 border-amber-500/20"
            }`}>
              <span className={`w-1.5 h-1.5 rounded-full ${gigData.publishedToApp ? "bg-emerald-400" : "bg-amber-400 animate-pulse"}`} />
              {gigData.publishedToApp ? "Published in App" : "Needs Review"}
            </div>

            <button 
              onClick={onClose}
              className="w-8 h-8 rounded-lg border border-zinc-700 flex items-center justify-center text-zinc-400 hover:text-white hover:bg-white/10 transition-all"
            >
              <X className="w-4 h-4" />
            </button>
          </div>
        </div>

        {/* ================= MODAL BODY: 2-COLUMN SPLIT ================= */}
        <div className="flex-1 overflow-y-auto custom-scrollbar p-6 grid grid-cols-1 lg:grid-cols-12 gap-6 bg-[#0E0E10]">
          
          {/* ---------------- LEFT COLUMN: ORIGINAL SOURCE (5 COLS) ---------------- */}
          <div className="lg:col-span-5 space-y-4">
            <div className="bg-[#18181B] border border-[#27272a] rounded-xl overflow-hidden shadow-lg">
              
              {/* Facebook Source Header */}
              <div className="p-3.5 bg-[#1F1F23] border-b border-[#27272a] flex items-center justify-between">
                <div className="flex items-center gap-2.5">
                  <div className="w-7 h-7 rounded-full bg-[#1877F2] text-white flex items-center justify-center font-bold text-xs shadow">
                    f
                  </div>
                  <div>
                    <h4 className="text-xs font-bold text-white leading-none">Facebook</h4>
                    <p className="text-[10px] text-zinc-400 leading-none mt-1 truncate max-w-[180px]">
                      {gigData.sourceGroup || "Musicians & Venues (Public Group)"}
                    </p>
                  </div>
                </div>

                {formData.sourceUrl && (
                  <a
                    href={formData.sourceUrl.startsWith("http") ? formData.sourceUrl : `https://${formData.sourceUrl}`}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="flex items-center gap-1.5 text-xs font-semibold bg-[#b3ff00] text-black px-2.5 py-1.5 rounded-lg hover:bg-[#a3eb00] transition-colors"
                  >
                    Open on Facebook <ExternalLink className="w-3 h-3" />
                  </a>
                )}
              </div>

              {/* Source Post Card (Facebook Mockup View) */}
              <div className="p-4 space-y-3.5 bg-[#141416]">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2.5">
                    <div className="w-9 h-9 rounded-full bg-gradient-to-br from-indigo-500 to-purple-600 text-white flex items-center justify-center font-bold text-xs shadow">
                      {formData.posterName.charAt(0) || "U"}
                    </div>
                    <div>
                      <p className="text-xs font-bold text-white leading-tight">{formData.posterName}</p>
                      <p className="text-[11px] text-zinc-400">12h &bull; &#127758;</p>
                    </div>
                  </div>
                  <span className="text-zinc-500 text-sm font-bold">&bull;&bull;&bull;</span>
                </div>

                {/* Post Body Text */}
                <div className="text-xs text-zinc-200 whitespace-pre-wrap leading-relaxed bg-[#1B1B1F] p-3 rounded-lg border border-zinc-800">
                  {gigData.description || gigData.rawText || gigData.title || "Looking for a band for our fall festival! October 17th in Austin, TX. 8-11pm. Outdoor stage. Message me with info and rates!"}
                </div>

                {/* Post Image Preview */}
                <div className="relative rounded-lg overflow-hidden border border-zinc-800 bg-zinc-950 aspect-video flex items-center justify-center group">
                  {gigData.imageUrl || gigData.postImageUrl ? (
                    <img 
                      src={gigData.imageUrl || gigData.postImageUrl} 
                      alt="Scraped Post" 
                      className="w-full h-full object-cover"
                    />
                  ) : (
                    <div className="text-center p-6 text-zinc-500 space-y-1">
                      <Music className="w-8 h-8 mx-auto text-zinc-600" />
                      <p className="text-xs">Live Music Event Image</p>
                    </div>
                  )}
                </div>

                {/* Post Reactions Bar */}
                <div className="pt-1 flex items-center justify-between text-[11px] text-zinc-400 border-t border-zinc-800/60">
                  <div className="flex items-center gap-1 text-xs">
                    <span className="text-red-400">&#10084;&#65039;</span>
                    <span className="text-blue-400">&#128077;</span>
                    <span className="font-semibold text-zinc-300 ml-1">24</span>
                  </div>
                  <div className="flex items-center gap-3">
                    <span>12 comments</span>
                    <span>2 shares</span>
                  </div>
                </div>
              </div>

              {/* Post URL with Copy Button */}
              {formData.sourceUrl && (
                <div className="p-3 bg-[#1A1A1E] border-t border-[#27272a] space-y-1.5">
                  <label className="text-[10px] uppercase font-bold text-zinc-400">Post URL</label>
                  <div className="flex items-center gap-2 bg-[#121214] border border-zinc-800 rounded-lg px-2.5 py-1.5">
                    <input
                      type="text"
                      readOnly
                      value={formData.sourceUrl}
                      className="w-full bg-transparent text-xs text-zinc-300 font-mono truncate focus:outline-none"
                    />
                    <button
                      type="button"
                      onClick={handleCopyUrl}
                      className="text-xs text-indigo-400 hover:text-indigo-300 flex items-center gap-1 font-semibold shrink-0"
                    >
                      {copiedUrl ? <Check className="w-3.5 h-3.5 text-emerald-400" /> : <Copy className="w-3.5 h-3.5" />}
                      {copiedUrl ? "Copied" : "Copy"}
                    </button>
                  </div>
                </div>
              )}
            </div>
          </div>

          {/* ---------------- RIGHT COLUMN: DATA ENTRY FORM (7 COLS) ---------------- */}
          <div className="lg:col-span-7 space-y-5">
            
            {/* SECTION 1: GIG BASICS */}
            <div className="bg-[#18181B] border border-[#27272a] rounded-xl p-4 space-y-3.5 shadow">
              <div className="flex items-center gap-2 text-lime-400 text-xs font-bold uppercase tracking-wider border-b border-zinc-800/80 pb-2">
                <Calendar className="w-4 h-4" />
                <span>Gig Basics</span>
              </div>

              {/* Poster & Gig Title */}
              <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                <div className="space-y-1">
                  <label className="text-zinc-300 text-xs font-medium">Posted By (Poster)</label>
                  <input
                    type="text"
                    value={formData.posterName}
                    onChange={(e) => setFormData({ ...formData, posterName: e.target.value })}
                    className="w-full h-9 bg-[#121214] border border-[#27272a] rounded-lg px-3 text-white text-xs focus:outline-none focus:border-[#b3ff00]"
                  />
                </div>
                <div className="space-y-1">
                  <label className="text-zinc-300 text-xs font-medium">
                    Gig / Event Title <span className="text-red-400">*</span>
                  </label>
                  <input
                    type="text"
                    required
                    value={formData.title}
                    onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                    placeholder="e.g. Fall Festival, Live Music Needed"
                    className="w-full h-9 bg-[#121214] border border-[#27272a] rounded-lg px-3 text-white text-xs focus:outline-none focus:border-[#b3ff00]"
                  />
                </div>
              </div>

              {/* Venue, City, State, Zip (with Auto-Populate) */}
              <div className="grid grid-cols-1 md:grid-cols-12 gap-3 items-end">
                <div className="md:col-span-4 space-y-1">
                  <div className="flex items-center justify-between">
                    <label className="text-zinc-300 text-xs font-medium">Venue Name</label>
                    <label className="flex items-center gap-1 text-[10px] text-zinc-400 cursor-pointer">
                      <input
                        type="checkbox"
                        checked={formData.venueNotListed}
                        onChange={(e) => setFormData({ ...formData, venueNotListed: e.target.checked })}
                        className="w-3 h-3 accent-[#b3ff00] rounded"
                      />
                      Not listed
                    </label>
                  </div>
                  <input
                    type="text"
                    disabled={formData.venueNotListed}
                    value={formData.venue}
                    onChange={(e) => setFormData({ ...formData, venue: e.target.value })}
                    placeholder="e.g. The Cove, Main Bar"
                    className="w-full h-9 bg-[#121214] border border-[#27272a] rounded-lg px-3 text-white text-xs focus:outline-none focus:border-[#b3ff00] disabled:opacity-40"
                  />
                </div>

                <div className="md:col-span-3 space-y-1">
                  <label className="text-zinc-300 text-xs font-medium flex items-center justify-between">
                    <span>Zip Code</span>
                    <span className="text-[10px] text-lime-400">Auto-fill</span>
                  </label>
                  <input
                    type="text"
                    value={formData.zip}
                    onChange={(e) => handleZipChange(e.target.value)}
                    placeholder="e.g. 78701"
                    maxLength={5}
                    className="w-full h-9 bg-[#121214] border border-[#27272a] rounded-lg px-3 text-white text-xs font-mono focus:outline-none focus:border-[#b3ff00]"
                  />
                </div>

                <div className="md:col-span-3 space-y-1">
                  <label className="text-zinc-300 text-xs font-medium">
                    City <span className="text-red-400">*</span>
                  </label>
                  <input
                    type="text"
                    value={formData.city}
                    onChange={(e) => setFormData({ ...formData, city: e.target.value })}
                    placeholder="Austin"
                    className="w-full h-9 bg-[#121214] border border-[#27272a] rounded-lg px-3 text-white text-xs focus:outline-none focus:border-[#b3ff00]"
                  />
                </div>

                <div className="md:col-span-2 space-y-1">
                  <label className="text-zinc-300 text-xs font-medium">
                    State <span className="text-red-400">*</span>
                  </label>
                  <select
                    value={formData.state}
                    onChange={(e) => setFormData({ ...formData, state: e.target.value })}
                    className="w-full h-9 bg-[#121214] border border-[#27272a] rounded-lg px-2 text-white text-xs font-medium focus:outline-none focus:border-[#b3ff00]"
                  >
                    {US_STATES.map((st) => (
                      <option key={st} value={st}>{st}</option>
                    ))}
                  </select>
                </div>
              </div>

              {/* Date, Start Time, End Time & Auto Duration */}
              <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
                <div className="space-y-1">
                  <label className="text-zinc-300 text-xs font-medium">
                    Date <span className="text-red-400">*</span>
                  </label>
                  <input
                    type="text"
                    value={formData.date}
                    onChange={(e) => setFormData({ ...formData, date: e.target.value })}
                    placeholder="Oct 17, 2026"
                    className="w-full h-9 bg-[#121214] border border-[#27272a] rounded-lg px-3 text-white text-xs focus:outline-none focus:border-[#b3ff00]"
                  />
                </div>
                <div className="space-y-1">
                  <label className="text-zinc-300 text-xs font-medium">Start Time</label>
                  <input
                    type="text"
                    value={formData.startTime}
                    onChange={(e) => handleStartTimeChange(e.target.value)}
                    placeholder="8:00 PM"
                    className="w-full h-9 bg-[#121214] border border-[#27272a] rounded-lg px-3 text-white text-xs focus:outline-none focus:border-[#b3ff00]"
                  />
                </div>
                <div className="space-y-1">
                  <label className="text-zinc-300 text-xs font-medium">End Time</label>
                  <input
                    type="text"
                    value={formData.endTime}
                    onChange={(e) => handleEndTimeChange(e.target.value)}
                    placeholder="11:00 PM"
                    className="w-full h-9 bg-[#121214] border border-[#27272a] rounded-lg px-3 text-white text-xs focus:outline-none focus:border-[#b3ff00]"
                  />
                </div>
                <div className="space-y-1">
                  <label className="text-zinc-300 text-xs font-medium flex items-center justify-between">
                    <span>Duration</span>
                    <span className="text-[10px] text-lime-400 font-mono">auto</span>
                  </label>
                  <input
                    type="text"
                    value={formData.duration}
                    onChange={(e) => setFormData({ ...formData, duration: e.target.value })}
                    placeholder="3 hrs"
                    className="w-full h-9 bg-[#1F1F24] border border-[#27272a] rounded-lg px-3 text-[#b3ff00] text-xs font-bold focus:outline-none"
                  />
                </div>
              </div>
            </div>

            {/* SECTION 2: PAY & BUDGET + LOOKING FOR */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              
              {/* Pay / Budget */}
              <div className="bg-[#18181B] border border-[#27272a] rounded-xl p-4 space-y-3 shadow">
                <div className="flex items-center justify-between border-b border-zinc-800/80 pb-2">
                  <div className="flex items-center gap-1.5 text-lime-400 text-xs font-bold uppercase tracking-wider">
                    <DollarSign className="w-4 h-4" />
                    <span>Pay / Budget</span>
                  </div>
                  <label className="flex items-center gap-1 text-[11px] text-zinc-400 cursor-pointer">
                    <input
                      type="checkbox"
                      checked={formData.payNotListed}
                      onChange={(e) => setFormData({ ...formData, payNotListed: e.target.checked })}
                      className="w-3 h-3 accent-[#b3ff00] rounded"
                    />
                    Not listed
                  </label>
                </div>

                <div className="grid grid-cols-2 gap-3">
                  <div className="space-y-1">
                    <label className="text-zinc-400 text-[11px]">Min Pay ($)</label>
                    <input
                      type="number"
                      disabled={formData.payNotListed}
                      value={formData.minPay}
                      onChange={(e) => setFormData({ ...formData, minPay: e.target.value })}
                      placeholder="e.g. 250"
                      className="w-full h-9 bg-[#121214] border border-[#27272a] rounded-lg px-3 text-white text-xs focus:outline-none focus:border-[#b3ff00] disabled:opacity-40"
                    />
                  </div>
                  <div className="space-y-1">
                    <label className="text-zinc-400 text-[11px]">Max Pay ($)</label>
                    <input
                      type="number"
                      disabled={formData.payNotListed}
                      value={formData.maxPay}
                      onChange={(e) => setFormData({ ...formData, maxPay: e.target.value })}
                      placeholder="e.g. 500"
                      className="w-full h-9 bg-[#121214] border border-[#27272a] rounded-lg px-3 text-white text-xs focus:outline-none focus:border-[#b3ff00] disabled:opacity-40"
                    />
                  </div>
                </div>
              </div>

              {/* Looking For (Performer Type) */}
              <div className="bg-[#18181B] border border-[#27272a] rounded-xl p-4 space-y-3 shadow">
                <div className="flex items-center gap-1.5 text-lime-400 text-xs font-bold uppercase tracking-wider border-b border-zinc-800/80 pb-2">
                  <Users className="w-4 h-4" />
                  <span>Looking For</span>
                </div>

                <div className="flex flex-wrap gap-1.5 pt-1">
                  {PERFORMER_TYPES.map((type) => {
                    const isSelected = formData.lookingFor.includes(type);
                    return (
                      <button
                        key={type}
                        type="button"
                        onClick={() => toggleLookingFor(type)}
                        className={`px-3 py-1.5 rounded-lg text-xs font-semibold transition-all border ${
                          isSelected
                            ? "bg-[#b3ff00]/15 border-[#b3ff00] text-[#b3ff00] shadow-sm"
                            : "bg-[#121214] border-zinc-800 text-zinc-300 hover:border-zinc-700"
                        }`}
                      >
                        {type} {isSelected && "✓"}
                      </button>
                    );
                  })}
                </div>
              </div>
            </div>

            {/* SECTION 3: GENRES */}
            <div className="bg-[#18181B] border border-[#27272a] rounded-xl p-4 space-y-3 shadow">
              <div className="flex items-center justify-between border-b border-zinc-800/80 pb-2">
                <div className="flex items-center gap-1.5 text-lime-400 text-xs font-bold uppercase tracking-wider">
                  <Music className="w-4 h-4" />
                  <span>Genre(s) - Multi-Select</span>
                </div>
                <span className="text-[11px] text-zinc-400">Quick Tags</span>
              </div>

              <div className="flex flex-wrap gap-1.5 items-center">
                {DEFAULT_GENRES.concat(formData.genres.filter(g => !DEFAULT_GENRES.includes(g))).map((genre) => {
                  const isSelected = formData.genres.includes(genre);
                  return (
                    <button
                      key={genre}
                      type="button"
                      onClick={() => toggleGenre(genre)}
                      className={`px-2.5 py-1 rounded-md text-xs font-medium transition-all border ${
                        isSelected
                          ? "bg-[#b3ff00] border-[#b3ff00] text-black font-bold shadow-sm"
                          : "bg-[#121214] border-zinc-800 text-zinc-300 hover:border-zinc-700 hover:text-white"
                      }`}
                    >
                      {genre} {isSelected && "✓"}
                    </button>
                  );
                })}

                {/* Add Custom Genre Button / Input */}
                {showAddGenre ? (
                  <div className="flex items-center gap-1 bg-[#121214] border border-[#b3ff00] rounded-md px-1.5 py-0.5">
                    <input
                      type="text"
                      autoFocus
                      placeholder="New genre..."
                      value={newGenreInput}
                      onChange={(e) => setNewGenreInput(e.target.value)}
                      onKeyDown={(e) => e.key === "Enter" && handleAddNewGenre()}
                      className="w-20 bg-transparent text-xs text-white focus:outline-none"
                    />
                    <button
                      type="button"
                      onClick={handleAddNewGenre}
                      className="text-[10px] text-lime-400 font-bold hover:underline"
                    >
                      Add
                    </button>
                    <button
                      type="button"
                      onClick={() => setShowAddGenre(false)}
                      className="text-[10px] text-zinc-500 hover:text-white"
                    >
                      ✕
                    </button>
                  </div>
                ) : (
                  <button
                    type="button"
                    onClick={() => setShowAddGenre(true)}
                    className="px-2.5 py-1 rounded-md text-xs font-semibold border border-dashed border-zinc-700 text-zinc-400 hover:text-white hover:border-zinc-500 transition-colors"
                  >
                    + Add Genre
                  </button>
                )}
              </div>
            </div>

            {/* SECTION 4: CONTACT DETAILS */}
            <div className="bg-[#18181B] border border-[#27272a] rounded-xl p-4 space-y-3 shadow">
              <div className="flex items-center gap-1.5 text-lime-400 text-xs font-bold uppercase tracking-wider border-b border-zinc-800/80 pb-2">
                <Phone className="w-4 h-4" />
                <span>Contact Details</span>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                <div className="space-y-1">
                  <label className="text-zinc-400 text-[11px]">Contact Name</label>
                  <input
                    type="text"
                    value={formData.contactName}
                    onChange={(e) => setFormData({ ...formData, contactName: e.target.value })}
                    className="w-full h-9 bg-[#121214] border border-[#27272a] rounded-lg px-3 text-white text-xs focus:outline-none focus:border-[#b3ff00]"
                  />
                </div>
                <div className="space-y-1">
                  <label className="text-zinc-400 text-[11px]">Phone Number</label>
                  <input
                    type="text"
                    value={formData.contactPhone}
                    onChange={(e) => setFormData({ ...formData, contactPhone: e.target.value })}
                    placeholder="e.g. +1 555-0199"
                    className="w-full h-9 bg-[#121214] border border-[#27272a] rounded-lg px-3 text-white text-xs focus:outline-none focus:border-[#b3ff00]"
                  />
                </div>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-3 items-center">
                <div className="space-y-1">
                  <label className="text-zinc-400 text-[11px]">Email</label>
                  <input
                    type="email"
                    value={formData.contactEmail}
                    onChange={(e) => setFormData({ ...formData, contactEmail: e.target.value })}
                    placeholder="e.g. poster@example.com"
                    className="w-full h-9 bg-[#121214] border border-[#27272a] rounded-lg px-3 text-white text-xs focus:outline-none focus:border-[#b3ff00]"
                  />
                </div>

                <div className="space-y-1">
                  <label className="text-zinc-400 text-[11px] flex items-center justify-between">
                    <span>Profile URL (optional)</span>
                    <label className="flex items-center gap-1 text-[10px] text-zinc-400 cursor-pointer">
                      <input
                        type="checkbox"
                        checked={formData.contactViaFb}
                        onChange={(e) => setFormData({ ...formData, contactViaFb: e.target.checked })}
                        className="w-3 h-3 accent-[#b3ff00] rounded"
                      />
                      Facebook DM
                    </label>
                  </label>
                  <input
                    type="text"
                    value={formData.profileUrl}
                    onChange={(e) => setFormData({ ...formData, profileUrl: e.target.value })}
                    placeholder="e.g. facebook.com/ronald"
                    className="w-full h-9 bg-[#121214] border border-[#27272a] rounded-lg px-3 text-white text-xs focus:outline-none focus:border-[#b3ff00]"
                  />
                </div>
              </div>
            </div>

            {/* SECTION 5: PUBLIC DESCRIPTION */}
            <div className="bg-[#18181B] border border-[#27272a] rounded-xl p-4 space-y-2 shadow">
              <div className="flex items-center justify-between border-b border-zinc-800/80 pb-2">
                <div className="flex items-center gap-1.5 text-lime-400 text-xs font-bold uppercase tracking-wider">
                  <FileText className="w-4 h-4" />
                  <span>Public Listing Description (Optional)</span>
                </div>
                <button
                  type="button"
                  onClick={handleCopyFromSource}
                  className="text-[11px] text-indigo-400 hover:text-indigo-300 font-semibold"
                >
                  Copy from Source Post
                </button>
              </div>

              <textarea
                rows={3}
                maxLength={1000}
                value={formData.description}
                onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                placeholder="Write or edit the description for the OnlyGigz listing... (You can copy from the post or write your own)"
                className="w-full bg-[#121214] border border-[#27272a] rounded-lg p-3 text-white text-xs focus:outline-none focus:border-[#b3ff00] leading-relaxed custom-scrollbar"
              />
              <div className="flex justify-end text-[10px] text-zinc-500">
                {formData.description.length} / 1000
              </div>
            </div>

            {/* SECTION 6: AI CLASSIFICATION & MODERATION FLAGS */}
            <div className="bg-[#18181B] border border-[#27272a] rounded-xl p-4 space-y-3 shadow">
              <div className="flex items-center gap-1.5 text-lime-400 text-xs font-bold uppercase tracking-wider border-b border-zinc-800/80 pb-2">
                <Sparkles className="w-4 h-4" />
                <span>AI Classification & Moderation Flags</span>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4 items-center">
                <div className="space-y-1">
                  <label className="text-zinc-400 text-[11px]">Primary Genre</label>
                  <select
                    value={formData.classification}
                    onChange={(e) => setFormData({ ...formData, classification: e.target.value })}
                    className="w-full h-9 bg-[#121214] border border-[#27272a] rounded-lg px-2.5 text-white text-xs font-medium focus:outline-none focus:border-[#b3ff00]"
                  >
                    {DEFAULT_GENRES.map(g => (
                      <option key={g} value={g}>{g}</option>
                    ))}
                  </select>
                </div>

                <div className="flex flex-wrap gap-4 pt-4">
                  <label className="flex items-center gap-1.5 cursor-pointer text-xs text-zinc-300">
                    <input
                      type="checkbox"
                      checked={formData.missingDetails}
                      onChange={(e) => setFormData({ ...formData, missingDetails: e.target.checked })}
                      className="w-3.5 h-3.5 accent-amber-500 rounded"
                    />
                    <span>Missing details ⓘ</span>
                  </label>

                  <label className="flex items-center gap-1.5 cursor-pointer text-xs text-zinc-300">
                    <input
                      type="checkbox"
                      checked={formData.isDuplicate}
                      onChange={(e) => setFormData({ ...formData, isDuplicate: e.target.checked, isSpam: false })}
                      className="w-3.5 h-3.5 accent-[#b3ff00] rounded"
                    />
                    <span>Mark as Duplicate</span>
                  </label>

                  <label className="flex items-center gap-1.5 cursor-pointer text-xs text-zinc-300">
                    <input
                      type="checkbox"
                      checked={formData.isSpam}
                      onChange={(e) => setFormData({ ...formData, isSpam: e.target.checked, isDuplicate: false })}
                      className="w-3.5 h-3.5 accent-red-500 rounded"
                    />
                    <span>Mark as Spam</span>
                  </label>
                </div>
              </div>
            </div>

          </div>
        </div>

        {/* ================= MODAL FOOTER ================= */}
        <div className="flex flex-col sm:flex-row items-center justify-between gap-3 px-6 py-3.5 border-t border-[#27272a] bg-[#161619] shrink-0">
          
          {/* Left Actions: Delete, Skip, Save Draft */}
          <div className="flex items-center gap-2 w-full sm:w-auto">
            {onDelete && (
              showDeleteConfirm ? (
                <div className="flex items-center gap-1.5 bg-red-950/60 border border-red-500/40 rounded-lg px-2 py-1">
                  <span className="text-xs text-red-300 font-semibold">Delete?</span>
                  <button
                    type="button"
                    disabled={isDeleting}
                    onClick={handleDelete}
                    className="text-xs bg-red-600 hover:bg-red-500 text-white px-2 py-0.5 rounded font-bold transition-colors disabled:opacity-60 flex items-center gap-1"
                  >
                    {isDeleting ? (
                      <>
                        <svg className="animate-spin w-3 h-3" viewBox="0 0 24 24" fill="none">
                          <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                          <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8z" />
                        </svg>
                        Deleting...
                      </>
                    ) : "Yes"}
                  </button>
                  <button
                    type="button"
                    onClick={() => setShowDeleteConfirm(false)}
                    className="text-xs text-zinc-400 hover:text-white px-1.5 py-0.5"
                  >
                    No
                  </button>
                </div>
              ) : (
                <button
                  type="button"
                  onClick={() => setShowDeleteConfirm(true)}
                  className="px-3 py-2 rounded-lg text-xs font-semibold text-red-400 border border-red-500/20 hover:bg-red-500/10 transition-colors flex items-center gap-1.5"
                >
                  <Trash2 className="w-3.5 h-3.5" />
                  Delete
                </button>
              )
            )}

            <button
              type="button"
              onClick={handleSkip}
              className="px-3.5 py-2 rounded-lg text-xs font-semibold text-zinc-400 hover:text-white bg-zinc-800/80 hover:bg-zinc-800 transition-colors"
            >
              Skip
            </button>

            <button
              type="button"
              disabled={isSaving}
              onClick={handleSaveDraft}
              className="px-4 py-2 rounded-lg text-xs font-semibold text-zinc-200 bg-[#222227] hover:bg-[#2c2c33] border border-zinc-700 transition-colors disabled:opacity-50"
            >
              {isSaving ? "Saving..." : "Save as Draft"}
            </button>
          </div>

          {/* Right Action: Publish & Next */}
          <div className="flex items-center gap-3 w-full sm:w-auto justify-end">
            <button
              type="button"
              disabled={isPublishing}
              onClick={handlePublishAndNext}
              className="w-full sm:w-auto flex items-center justify-center gap-2 bg-[#b3ff00] hover:bg-[#a2e600] text-black px-6 py-2.5 rounded-lg font-bold text-xs shadow-lg shadow-[#b3ff00]/15 transition-all disabled:opacity-50"
            >
              {isPublishing ? "Publishing..." : "Publish & Next ➔"}
            </button>
          </div>
        </div>

      </div>
    </div>
  );
}
