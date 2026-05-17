"use client";

import React, { useState, useMemo, useEffect } from "react";
import { 
  Star, 
  Search, 
  Flag, 
  Trash2, 
  AlertCircle 
} from "lucide-react";
import { Toast } from "@/components/ui/Toast";
import { RemoveReviewModal } from "@/components/ui/RemoveReviewModal";
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
      setReviews(reviewsData);
      setStats(statsData);
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
        setToast({ show: true, message: `Review ${selectedReviewId} deleted successfully.` });
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

  const handleDeleteClick = (id: string) => {
    setSelectedReviewId(id);
    setIsDeleteModalOpen(true);
  };

  // --- Filtering Logic ---
  const filteredReviews = useMemo(() => {
    return reviews.filter(review => {
      const matchesSearch = review.musicianName.toLowerCase().includes(searchQuery.toLowerCase());
      const matchesRating = activeRatingFilter === "all" || Math.floor(review.rating) === activeRatingFilter;
      return matchesSearch && matchesRating;
    });
  }, [searchQuery, activeRatingFilter, reviews]);

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
      <div className="flex flex-col lg:flex-row lg:items-center gap-4 sm:gap-6 mb-8">
        <div className="relative flex-1 group">
          <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-[18px] h-[18px] text-[#52525b] group-focus-within:text-[#A2F301] transition-colors" />
          <input
            type="text"
            placeholder="Search by musician name..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full h-[48px] bg-[#1A1A1A] border border-[#2A2A2A] rounded-[8px] pl-11 pr-4 text-[14px] text-white focus:outline-none focus:border-[#A2F301]/40 transition-all placeholder:text-[#52525b]"
          />
        </div>
        
        <div className="flex items-center gap-2 overflow-x-auto custom-scrollbar pb-2 lg:pb-0">
          <button 
            onClick={() => setActiveRatingFilter("all")}
            className={`h-[40px] px-6 rounded-[8px] text-[14px] font-medium transition-all shrink-0 ${
              activeRatingFilter === "all" ? "bg-[#A2F301] text-black" : "bg-[#1A1A1A] border border-[#2A2A2A] text-white/60 hover:text-white"
            }`}
          >
            All
          </button>
          {ratingFilters.map((rating) => (
            <button 
              key={rating}
              onClick={() => setActiveRatingFilter(rating)}
              className={`h-[40px] px-4 rounded-[8px] flex items-center gap-2 text-[14px] font-medium transition-all shrink-0 ${
                activeRatingFilter === rating ? "bg-[#1A1A1A] border border-[#A2F301] text-white" : "bg-[#1A1A1A] border border-[#2A2A2A] text-white/60 hover:text-white"
              }`}
            >
              <Star size={14} className={activeRatingFilter === rating ? "fill-[#A2F301] text-[#A2F301]" : "text-white/60"} />
              {rating}
            </button>
          ))}
        </div>
      </div>

      {/* Reviews List */}
      <div className="flex flex-col gap-4">
        {loading ? (
          <div className="bg-[#1A1A1A] border border-[#2A2A2A] rounded-[8px] py-20 flex flex-col items-center justify-center">
            <div className="w-8 h-8 border-2 border-[#A2F301] border-t-transparent rounded-full animate-spin mb-4"></div>
            <p className="text-[#999999] text-[16px]">Loading reviews...</p>
          </div>
        ) : (
          <>
            {filteredReviews.map((review) => (
              <div 
                key={review.id}
                className="bg-[#1A1A1A] border border-[#2A2A2A] rounded-[8px] p-5 sm:p-6 hover:border-white/10 transition-all group relative animate-in fade-in duration-500 shadow-lg"
              >
                <div className="flex flex-col sm:flex-row justify-between items-start gap-4 mb-4">
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
                
                <p className="text-white/80 text-[14px] sm:text-[15px] leading-relaxed max-w-[800px]">
                  {review.content}
                </p>
              </div>
            ))}

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

      <Toast 
        show={toast.show}
        message={toast.message}
        onClose={() => setToast({ ...toast, show: false })}
      />
    </div>
  );
}
