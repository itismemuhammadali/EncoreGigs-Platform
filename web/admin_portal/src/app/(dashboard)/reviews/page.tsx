"use client";

import React, { useState, useMemo, useEffect } from "react";
import { 
  Star, 
  Search, 
  Flag, 
  Trash2, 
  AlertCircle,
  X,
  Loader2
} from "lucide-react";
import { Toast } from "@/components/ui/Toast";
import { RemoveReviewModal } from "@/components/ui/RemoveReviewModal";
import { ConfirmationModal } from "@/components/ui/ConfirmationModal";
import { apiRequest } from "@/lib/api";

// --- Types & Interfaces ---
interface Review {
  id: string;
  musicianName: string;
  rating: number;
  organizer: string;
  gigReference: string;
  date: string;
  content: string;
  isFlagged: boolean;
}

interface ReviewStats {
  total: number;
  average: string;
  fiveStars: number;
  flagged: number;
}

export default function ReviewsPage() {
  const [reviews, setReviews] = useState<Review[]>([]);
  const [stats, setStats] = useState<ReviewStats>({ total: 0, average: "0.0", fiveStars: 0, flagged: 0 });
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState("");
  const [activeRatingFilter, setActiveRatingFilter] = useState<number | "all">("all");
  const [toast, setToast] = useState({ show: false, message: "" });
  const [isDeleteModalOpen, setIsDeleteModalOpen] = useState(false);
  const [selectedReviewId, setSelectedReviewId] = useState<string | null>(null);

  // Selection & Bulk Delete States
  const [selectedReviewIds, setSelectedReviewIds] = useState<string[]>([]);
  const [bulkDeleteModalOpen, setBulkDeleteModalOpen] = useState(false);
  const [bulkActionLoading, setBulkActionLoading] = useState(false);

  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    try {
      setLoading(true);
      const [reviewsData, statsData] = await Promise.all([
        apiRequest("/reviews/list"),
        apiRequest("/reviews/stats")
      ]);
      setReviews(Array.isArray(reviewsData) ? reviewsData : []);
      setStats(statsData || { total: 0, average: "0.0", fiveStars: 0, flagged: 0 });
      setSelectedReviewIds([]);
    } catch (error) {
      console.error("Error fetching reviews:", error);
      setToast({ show: true, message: "Failed to load reviews data." });
    } finally {
      setLoading(false);
    }
  };

  // --- Handlers ---
  const handleFlag = async (id: string) => {
    const review = reviews.find(r => r.id === id);
    if (!review) return;

    try {
      const newFlagStatus = !review.isFlagged;
      await apiRequest(`/reviews/${id}/flag`, {
        method: "POST",
        body: JSON.stringify({ isFlagged: newFlagStatus })
      });
      
      setReviews(prev => prev.map(r => 
        r.id === id ? { ...r, isFlagged: newFlagStatus } : r
      ));
      
      const action = newFlagStatus ? "flagged" : "unflagged";
      setToast({ show: true, message: `Review ${id} ${action} successfully.` });
      
      // Update stats as well
      const updatedStats = await apiRequest("/reviews/stats");
      setStats(updatedStats);
    } catch (error) {
      console.error("Error flagging review:", error);
      setToast({ show: true, message: "Failed to update review status." });
    }
  };

  const confirmDelete = async () => {
    if (selectedReviewId) {
      try {
        await apiRequest(`/reviews/${selectedReviewId}`, {
          method: "DELETE"
        });
        
        setReviews(prev => prev.filter(r => r.id !== selectedReviewId));
        setSelectedReviewIds(prev => prev.filter(id => id !== selectedReviewId));
        setToast({ show: true, message: `Review deleted successfully.` });
        setIsDeleteModalOpen(false);
        setSelectedReviewId(null);
        
        // Update stats
        const updatedStats = await apiRequest("/reviews/stats");
        setStats(updatedStats);
      } catch (error) {
        console.error("Error deleting review:", error);
        setToast({ show: true, message: "Failed to delete review." });
      }
    }
  };

  const handleConfirmBulkDelete = async () => {
    if (selectedReviewIds.length === 0) return;
    try {
      setBulkActionLoading(true);
      const res = await apiRequest("/reviews/bulk-delete", {
        method: "POST",
        body: JSON.stringify({ reviewIds: selectedReviewIds })
      });
      const count = res?.deletedCount ?? selectedReviewIds.length;
      setReviews(prev => prev.filter(r => !selectedReviewIds.includes(r.id)));
      setSelectedReviewIds([]);
      setBulkDeleteModalOpen(false);
      setToast({ show: true, message: `Deleted ${count} reviews successfully.` });
      
      const updatedStats = await apiRequest("/reviews/stats");
      setStats(updatedStats);
    } catch (error) {
      console.error("Error bulk deleting reviews:", error);
      setToast({ show: true, message: "Failed to delete selected reviews." });
    } finally {
      setBulkActionLoading(false);
    }
  };

  const handleDeleteClick = (id: string) => {
    setSelectedReviewId(id);
    setIsDeleteModalOpen(true);
  };

  // --- Filtering Logic ---
  const filteredReviews = useMemo(() => {
    return reviews.filter(review => {
      const matchesSearch = review.musicianName.toLowerCase().includes(searchQuery.toLowerCase()) ||
        review.organizer.toLowerCase().includes(searchQuery.toLowerCase()) ||
        review.content.toLowerCase().includes(searchQuery.toLowerCase());
      const matchesRating = activeRatingFilter === "all" || Math.floor(review.rating) === activeRatingFilter;
      return matchesSearch && matchesRating;
    });
  }, [searchQuery, activeRatingFilter, reviews]);

  // --- Selection Logic ---
  const isAllSelected = filteredReviews.length > 0 && filteredReviews.every(r => selectedReviewIds.includes(r.id));

  const handleToggleSelectAll = () => {
    if (isAllSelected) {
      setSelectedReviewIds([]);
    } else {
      setSelectedReviewIds(filteredReviews.map(r => r.id));
    }
  };

  const handleToggleSelect = (id: string) => {
    setSelectedReviewIds(prev =>
      prev.includes(id) ? prev.filter(item => item !== id) : [...prev, id]
    );
  };

  // --- UI Configuration Arrays ---
  const statCards = [
    { label: "Total Reviews", value: stats.total, color: "text-white" },
    { label: "Average Rating", value: stats.average, color: "text-white", hasStars: true },
    { label: "5-Star Reviews", value: stats.fiveStars, color: "text-[#10B981]" },
    { label: "Flagged Reviews", value: stats.flagged, color: "text-[#F59E0B]" }
  ];

  const ratingFilters = [5, 4, 3, 2, 1];

  // --- UI Components ---
  const getRatingColor = (rating: number) => {
    if (rating >= 4) return "text-[#10B981]"; // Green
    if (rating >= 3) return "text-[#F59E0B]"; // Amber
    return "text-[#F87171]"; // Red
  };

  const StarRating = ({ rating, size = 16 }: { rating: number, size?: number }) => {
    return (
      <div className="flex gap-1">
        {[1, 2, 3, 4, 5].map((star) => (
          <Star 
            key={star}
            size={size}
            className={star <= Math.round(rating) ? "fill-[#A2F301] text-[#A2F301]" : "text-[#404040]"}
          />
        ))}
      </div>
    );
  };

  return (
    <div className="w-full pb-20">
      {/* Header Section */}
      <div className="mb-8">
        <h1 className="text-2xl sm:text-[30px] font-bold text-white leading-tight mb-1">Reviews Management</h1>
        <p className="text-[#999999] text-sm sm:text-[16px]">Monitor and manage musician reviews and ratings</p>
      </div>

      {/* Stats Cards Grid */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 sm:gap-6 mb-10">
        {statCards.map((card, i) => (
          <div key={i} className="bg-[#1A1A1A] border border-[#2A2A2A] p-4 sm:p-6 rounded-[8px] shadow-xl">
            <p className="text-[#999999] text-[12px] sm:text-[14px] font-medium mb-2">{card.label}</p>
            <div className="flex flex-col sm:flex-row sm:items-center gap-2 sm:gap-3">
              <p className={`${card.color} text-2xl sm:text-[32px] font-bold leading-none`}>{card.value}</p>
              {card.hasStars && <div className="scale-75 sm:scale-100 origin-left"><StarRating rating={Number(card.value)} size={16} /></div>}
            </div>
          </div>
        ))}
      </div>

      {/* Search and Filters */}
      <div className="flex flex-col lg:flex-row lg:items-center gap-4 sm:gap-6 mb-6">
        <div className="relative flex-1 group">
          <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-[18px] h-[18px] text-[#52525b] group-focus-within:text-[#A2F301] transition-colors" />
          <input
            type="text"
            placeholder="Search by musician, organizer, or review content..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full h-[48px] bg-[#1A1A1A] border border-[#2A2A2A] rounded-[8px] pl-11 pr-4 text-[14px] text-white focus:outline-none focus:border-[#A2F301]/40 transition-all placeholder:text-[#52525b]"
          />
        </div>
        
        <div className="flex items-center gap-2 overflow-x-auto custom-scrollbar pb-2 lg:pb-0">
          <button 
            onClick={() => setActiveRatingFilter("all")}
            className={`h-[40px] px-6 rounded-[8px] text-[14px] font-medium transition-all shrink-0 ${
              activeRatingFilter === "all" ? "bg-[#A2F301] text-black font-bold" : "bg-[#1A1A1A] border border-[#2A2A2A] text-white/60 hover:text-white"
            }`}
          >
            All
          </button>
          {ratingFilters.map((rating) => (
            <button 
              key={rating}
              onClick={() => setActiveRatingFilter(rating)}
              className={`h-[40px] px-4 rounded-[8px] flex items-center gap-2 text-[14px] font-medium transition-all shrink-0 ${
                activeRatingFilter === rating ? "bg-[#1A1A1A] border border-[#A2F301] text-white font-bold" : "bg-[#1A1A1A] border border-[#2A2A2A] text-white/60 hover:text-white"
              }`}
            >
              <Star size={14} className={activeRatingFilter === rating ? "fill-[#A2F301] text-[#A2F301]" : "text-white/60"} />
              {rating}
            </button>
          ))}
        </div>
      </div>

      {/* Bulk Action Toolbar */}
      {selectedReviewIds.length > 0 && (
        <div className="mb-6 flex flex-wrap items-center justify-between gap-4 bg-[#1a2110] border border-[#A2F301]/40 rounded-xl px-5 py-3.5 shadow-2xl animate-in slide-in-from-top-2">
          <div className="flex items-center gap-3">
            <div className="w-8 h-8 rounded-lg bg-[#A2F301] flex items-center justify-center text-black font-extrabold text-sm shadow">
              {selectedReviewIds.length}
            </div>
            <span className="text-white font-medium text-sm">
              {selectedReviewIds.length} of {filteredReviews.length} reviews selected
            </span>
            <button
              onClick={handleToggleSelectAll}
              className="text-[#A2F301] hover:underline text-xs font-bold ml-2"
            >
              {isAllSelected ? "Deselect All" : `Select All (${filteredReviews.length})`}
            </button>
          </div>

          <div className="flex items-center gap-2">
            <button
              onClick={() => setBulkDeleteModalOpen(true)}
              disabled={bulkActionLoading}
              className="flex items-center gap-1.5 bg-[#ef4444]/20 hover:bg-[#ef4444]/30 text-[#ef4444] border border-[#ef4444]/40 px-3.5 py-1.5 rounded-lg text-xs font-bold transition-all disabled:opacity-50"
            >
              {bulkActionLoading ? <Loader2 className="w-3.5 h-3.5 animate-spin" /> : <Trash2 className="w-3.5 h-3.5" />}
              Delete Selected ({selectedReviewIds.length})
            </button>
            <button
              onClick={() => setSelectedReviewIds([])}
              className="text-[#a1a1aa] hover:text-white p-1.5 rounded-lg hover:bg-white/5 transition-all ml-1"
              title="Clear Selection"
            >
              <X className="w-4 h-4" />
            </button>
          </div>
        </div>
      )}

      {/* Select All Option Header */}
      {filteredReviews.length > 0 && (
        <div className="flex items-center justify-between px-2 mb-3">
          <label className="flex items-center gap-2 text-xs text-[#a1a1aa] cursor-pointer hover:text-white transition-colors">
            <input
              type="checkbox"
              checked={isAllSelected}
              onChange={handleToggleSelectAll}
              className="w-4 h-4 rounded border-[#3A3A3A] bg-[#141414] text-[#A2F301] accent-[#A2F301] cursor-pointer"
            />
            <span>Select All Reviews</span>
          </label>
          <span className="text-xs text-[#52525b]">Showing {filteredReviews.length} reviews</span>
        </div>
      )}

      {/* Reviews List */}
      <div className="flex flex-col gap-4">
        {loading ? (
          <div className="bg-[#1A1A1A] border border-[#2A2A2A] rounded-[8px] py-20 flex flex-col items-center justify-center">
            <div className="w-8 h-8 border-2 border-[#A2F301] border-t-transparent rounded-full animate-spin mb-4"></div>
            <p className="text-[#999999] text-[16px]">Loading reviews...</p>
          </div>
        ) : (
          <>
            {filteredReviews.map((review) => {
              const isSelected = selectedReviewIds.includes(review.id);
              return (
                <div 
                  key={review.id}
                  className={`border rounded-[8px] p-5 sm:p-6 transition-all group relative animate-in fade-in duration-500 shadow-lg ${
                    isSelected ? "bg-[#A2F301]/[0.04] border-[#A2F301]/40" : "bg-[#1A1A1A] border-[#2A2A2A] hover:border-white/10"
                  }`}
                >
                  <div className="flex flex-col sm:flex-row justify-between items-start gap-4 mb-4">
                    <div className="flex items-start gap-3 w-full">
                      <input
                        type="checkbox"
                        checked={isSelected}
                        onChange={() => handleToggleSelect(review.id)}
                        className="w-4 h-4 rounded border-[#3A3A3A] bg-[#141414] text-[#A2F301] accent-[#A2F301] cursor-pointer mt-1"
                      />
                      <div className="w-full">
                        <div className="flex flex-col sm:flex-row sm:items-center gap-2 sm:gap-3 mb-1">
                          <h3 className="text-white text-[18px] font-semibold">{review.musicianName}</h3>
                          <div className="flex items-center gap-2">
                            <StarRating rating={review.rating} />
                            <span className={`text-[14px] font-bold ${getRatingColor(review.rating)}`}>
                              {review.rating.toFixed(1)}
                            </span>
                            {review.isFlagged && (
                              <div className="flex items-center gap-1.5 px-2 py-0.5 bg-[#F59E0B]/10 rounded-[4px] border border-[#F59E0B]/20">
                                <Flag size={12} className="text-[#F59E0B] fill-[#F59E0B]" />
                                <span className="text-[#F59E0B] text-[10px] font-bold uppercase tracking-wider">Flagged</span>
                              </div>
                            )}
                          </div>
                        </div>
                        <p className="text-[#999999] text-[13px] sm:text-[14px]">
                          By {review.organizer} • {review.gigReference}
                        </p>
                        <p className="text-[#52525b] text-[11px] mt-1">{review.date}</p>
                      </div>
                    </div>
                    <div className="flex items-center gap-3 self-end sm:self-start">
                      <button 
                        onClick={() => handleFlag(review.id)}
                        className={`p-2 rounded-[8px] border transition-all ${
                          review.isFlagged ? "bg-[#F59E0B]/10 border-[#F59E0B]/20 text-[#F59E0B]" : "bg-transparent border-[#2A2A2A] text-[#999999] hover:text-white"
                        }`}
                        title={review.isFlagged ? "Unflag Review" : "Flag Review"}
                      >
                        <Flag size={18} className={review.isFlagged ? "fill-current" : ""} />
                      </button>
                      <button 
                        onClick={() => handleDeleteClick(review.id)}
                        className="p-2 bg-transparent border border-[#2A2A2A] rounded-[8px] text-[#999999] hover:bg-[#F87171]/10 hover:border-[#F87171]/30 hover:text-[#F87171] transition-all"
                        title="Delete Review"
                      >
                        <Trash2 size={18} />
                      </button>
                    </div>
                  </div>
                  
                  <p className="text-white/80 text-[14px] sm:text-[15px] leading-relaxed max-w-[800px] pl-7">
                    {review.content}
                  </p>
                </div>
              );
            })}

            {filteredReviews.length === 0 && (
              <div className="bg-[#1A1A1A] border border-[#2A2A2A] border-dashed rounded-[8px] py-16 flex flex-col items-center justify-center">
                <p className="text-[#999999] text-[16px]">No reviews found matching your criteria.</p>
                <button 
                  onClick={() => {setSearchQuery(""); setActiveRatingFilter("all");}}
                  className="mt-4 text-[#A2F301] hover:underline text-[14px]"
                >
                  Clear all filters
                </button>
              </div>
            )}
          </>
        )}
      </div>

      {/* --- Modals & Notifications --- */}
      <RemoveReviewModal 
        isOpen={isDeleteModalOpen}
        onClose={() => setIsDeleteModalOpen(false)}
        onConfirm={confirmDelete}
      />

      <ConfirmationModal 
        isOpen={bulkDeleteModalOpen}
        onClose={() => setBulkDeleteModalOpen(false)}
        onConfirm={handleConfirmBulkDelete}
        title={`Delete ${selectedReviewIds.length} Selected Reviews?`}
        description={`Are you sure you want to permanently delete these ${selectedReviewIds.length} reviews? Ratings and metrics will be updated. This cannot be undone.`}
        cancelLabel="Cancel"
        confirmLabel={`Delete ${selectedReviewIds.length} Reviews`}
        confirmVariant="danger"
      />

      <Toast 
        show={toast.show}
        message={toast.message}
        onClose={() => setToast({ ...toast, show: false })}
      />
    </div>
  );
}
