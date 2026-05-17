"use client";

import React, { useState, useMemo } from "react";
import {
  Play,
  Database,
  CheckCircle,
  AlertTriangle,
  FileText
} from "lucide-react";
import { Toast } from "@/components/ui/Toast";
import { ConfirmationModal } from "@/components/ui/ConfirmationModal";
import { ScraperDetailsModal } from "@/components/ui/ScraperDetailsModal";
import { EditScrapedGigModal } from "@/components/ui/EditScrapedGigModal";
import { RunScraperModal } from "@/components/ui/RunScraperModal";

/** 
 * BACKEND DEVELOPER NOTE:
 * The following interfaces define the structure expected from the API.
 * Integration points:
 * 1. Fetch overall stats for the dashboard cards.
 * 2. Fetch recent scraper runs list.
 * 3. Fetch recently imported gigs with filtering support.
 * 4. POST request to trigger the scraper engine.
 */

interface ScraperStat {
  label: string;
  value: string;
  subtext?: string;
  trend?: string;
  icon: React.ElementType;
}

interface ScraperRun {
  id: string;
  timestamp: string;
  source: string;
  imported: number;
  errors: number;
  duration: string;
  status: "success" | "failed";
}

interface ImportedGig {
  id: number;
  title: string;
  source: string;
  classification: string;
  confidence: string;
  flags: "None" | "Duplicate" | "Spam";
  importedAt: string;
}

export default function ScraperModule() {
  const [activeTab, setActiveTab] = useState<"all" | "duplicates" | "spam">("all");
  const [toast, setToast] = useState<{ show: boolean; message: string }>({ show: false, message: "" });
  const [deleteModal, setDeleteModal] = useState<{ show: boolean; gigId: number | null }>({ show: false, gigId: null });
  const [detailsModal, setDetailsModal] = useState<{ show: boolean; run: ScraperRun | null }>({ show: false, run: null });
  const [editModal, setEditModal] = useState<{ show: boolean; gig: ImportedGig | null }>({ show: false, gig: null });
  const [runScraperModal, setRunScraperModal] = useState(false);

  // BACKEND: Replace these initial state values with data from your API
  const [stats, setStats] = useState<ScraperStat[]>([
    { label: "Total Scraped Gigs", value: "1,845", subtext: "Last 30 days", icon: Database },
    { label: "Success Rate", value: "94.2%", trend: "+2.3%", icon: CheckCircle },
    { label: "Duplicates Detected", value: "124", subtext: "Automatically filtered", icon: FileText },
    { label: "Spam Flagged", value: "37", subtext: "AI detection active", icon: AlertTriangle },
  ]);

  const [recentRuns, setRecentRuns] = useState<ScraperRun[]>([
    { id: "1", timestamp: "2026-02-17 08:30:00", source: "Eventbrite", imported: 45, errors: 2, duration: "3m 24s", status: "success" },
    { id: "2", timestamp: "2026-02-17 06:00:00", source: "Bandsintown", imported: 67, errors: 0, duration: "4m 12s", status: "success" },
    { id: "3", timestamp: "2026-02-17 03:30:00", source: "GigSalad", imported: 23, errors: 1, duration: "2m 45s", status: "success" },
    { id: "4", timestamp: "2026-02-16 22:00:00", source: "Thumbtack", imported: 0, errors: 5, duration: "0m 32s", status: "failed" },
    { id: "5", timestamp: "2026-02-16 18:30:00", source: "The Bash", imported: 34, errors: 0, duration: "3m 56s", status: "success" },
  ]);

  const [importedGigs, setImportedGigs] = useState<ImportedGig[]>([
    { id: 1, title: "Jazz Festival Performance", source: "Eventbrite", classification: "Jazz", confidence: "95%", flags: "None", importedAt: "2 hours ago" },
    { id: 2, title: "Wedding Band Needed", source: "GigSalad", classification: "Wedding", confidence: "88%", flags: "None", importedAt: "3 hours ago" },
    { id: 3, title: "Rock Concert Drummer", source: "Bandsintown", classification: "Rock", confidence: "92%", flags: "Duplicate", importedAt: "5 hours ago" },
    { id: 4, title: "Quick Cash for Musicians!!!", source: "Unknown", classification: "Spam", confidence: "78%", flags: "Spam", importedAt: "6 hours ago" },
  ]);

  // Handle Filtering Logic
  const filteredGigs = useMemo(() => {
    return importedGigs.filter((gig) => {
      if (activeTab === "all") return true;
      if (activeTab === "duplicates") return gig.flags === "Duplicate";
      if (activeTab === "spam") return gig.flags === "Spam";
      return true;
    });
  }, [importedGigs, activeTab]);

  const showToast = (message: string) => {
    setToast({ show: true, message });
  };

  /** 
   * BACKEND INTEGRATION: Trigger Scraper 
   */
  const handleRunScraper = async () => {
    // TODO: Implement API call to POST /api/scraper/run
    showToast("Scraper started successfully");
  };

  /** 
   * BACKEND INTEGRATION: Delete Scraped Gig 
   */
  const handleDeleteGig = async () => {
    if (deleteModal.gigId) {
      // TODO: Implement API call to DELETE /api/scraper/gigs/:id
      setImportedGigs(prev => prev.filter(g => g.id !== deleteModal.gigId));
      setDeleteModal({ show: false, gigId: null });
      showToast("Gig deleted successfully");
    }
  };

  return (
    <div className="relative min-h-screen">
      <div className="space-y-8 animate-in fade-in duration-700 pb-20">
        {/* --- HEADER --- */}
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-6">
          <div>
            <h1 className="text-2xl sm:text-[32px] font-bold text-white mb-2 leading-tight">Scraper Module Management</h1>
            <p className="text-[#a1a1aa] text-sm sm:text-[16px]">Monitor and manage the automated gig scraping engine</p>
          </div>
          <button 
            onClick={() => setRunScraperModal(true)}
            className="flex items-center justify-center gap-3 bg-[#b3ff00] text-black px-6 py-3 rounded-[8px] font-semibold text-[16px] sm:text-[18px] hover:bg-[#a2e600] transition-all shadow-lg shadow-[#b3ff00]/10 whitespace-nowrap"
          >
            <Play className="w-4 h-4 sm:w-5 sm:h-5 stroke-[2.5px]" />
            Run Scraper Now
          </button>
        </div>

        {/* --- STAT CARDS --- */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
          {stats.map((stat, i) => (
            <div key={i} className="bg-[#1A1A1A] border border-[#2A2A2A] p-6 rounded-xl shadow-xl flex justify-between items-start group hover:border-[#b3ff00]/30 transition-all">
              <div className="space-y-1">
                <p className="text-[#71717a] text-[13px] sm:text-[14px] font-medium">{stat.label}</p>
                <h3 className="text-white text-2xl sm:text-[30px] font-bold leading-tight py-1">{stat.value}</h3>
                {stat.trend ? (
                  <p className="text-[#b3ff00] text-[12px] sm:text-[13px] font-medium">{stat.trend} from last week</p>
                ) : (
                  <p className="text-[#71717a] text-[12px] sm:text-[13px] font-medium">{stat.subtext}</p>
                )}
              </div>
              <div className="w-12 h-12 sm:w-[58px] sm:h-[58px] rounded-lg bg-[#1c2114] flex items-center justify-center border border-[#b3ff00]/10 flex-shrink-0">
                <stat.icon className="w-6 h-6 sm:w-7 sm:h-7 text-[#b3ff00]" />
              </div>
            </div>
          ))}
        </div>

        {/* --- RECENT RUNS TABLE --- */}
        <div className="bg-[#1A1A1A] border border-[#2A2A2A] rounded-2xl overflow-hidden shadow-2xl">
          <div className="p-6">
            <h2 className="text-white text-[18px] sm:text-[20px] font-bold">Recent Scraper Runs</h2>
          </div>
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="bg-[#262626] border-y border-[#2A2A2A]">
                  <th className="px-6 py-4 text-[14px] font-medium leading-[20px] text-[#FFFFFF] capitalize">Timestamp</th>
                  <th className="px-6 py-4 text-[14px] font-medium leading-[20px] text-[#FFFFFF] capitalize">Source</th>
                  <th className="px-6 py-4 text-[14px] font-medium leading-[20px] text-[#FFFFFF] capitalize">Gigs Imported</th>
                  <th className="px-6 py-4 text-[14px] font-medium leading-[20px] text-[#FFFFFF] capitalize">Errors</th>
                  <th className="px-6 py-4 text-[14px] font-medium leading-[20px] text-[#FFFFFF] capitalize">Duration</th>
                  <th className="px-6 py-4 text-[14px] font-medium leading-[20px] text-[#FFFFFF] capitalize">Status</th>
                  <th className="px-6 py-4 text-[14px] font-medium leading-[20px] text-[#FFFFFF] capitalize">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-[#2A2A2A]">
                {recentRuns.map((run) => (
                  <tr key={run.id} className="hover:bg-white/[0.02] transition-colors group">
                    <td className="px-6 py-5 text-[#a1a1aa] text-[14px]">{run.timestamp}</td>
                    <td className="px-6 py-5 text-white font-medium text-[14px]">{run.source}</td>
                    <td className="px-6 py-5 text-[#b3ff00] font-bold text-[14px]">{run.imported}</td>
                    <td className="px-6 py-5 text-[#ef4444] font-medium text-[14px]">{run.errors}</td>
                    <td className="px-6 py-5 text-[#a1a1aa] text-[14px]">{run.duration}</td>
                    <td className="px-6 py-5">
                      <span className={`px-3 py-1 rounded-full text-[12px] font-bold lowercase ${
                        run.status === 'success' ? 'bg-[#10b981]/10 text-[#10b981]' : 'bg-[#ef4444]/10 text-[#ef4444]'
                      }`}>
                        {run.status}
                      </span>
                    </td>
                    <td className="px-6 py-5">
                      <button 
                        onClick={() => setDetailsModal({ show: true, run })}
                        className="text-[#b3ff00] text-[13px] font-bold hover:underline"
                      >
                        View Details
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        {/* --- RECENTLY IMPORTED GIGS TABLE --- */}
        <div className="bg-[#1A1A1A] border border-[#2A2A2A] rounded-2xl overflow-hidden shadow-2xl">
          <div className="p-6 flex flex-col sm:flex-row sm:items-center justify-between gap-4">
            <h2 className="text-white text-[18px] sm:text-[20px] font-bold">Recently Imported Gigs</h2>
            <div className="flex items-center gap-2 overflow-x-auto custom-scrollbar pb-2 sm:pb-0">
              {["All", "Duplicates", "Spam"].map((tab) => (
                <button
                  key={tab}
                  onClick={() => setActiveTab(tab.toLowerCase() as any)}
                  className={`px-4 py-1.5 rounded-[6px] text-[13px] sm:text-[14px] font-medium transition-all whitespace-nowrap ${
                    activeTab === tab.toLowerCase() ? "bg-[#3f3f46] text-white shadow-lg" : "bg-[#27272a] text-white/80 hover:text-white hover:bg-[#323238]"
                  }`}
                >
                  {tab}
                </button>
              ))}
            </div>
          </div>
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="bg-[#262626] border-y border-[#2A2A2A]">
                  <th className="px-6 py-4 text-[14px] font-medium leading-[20px] text-[#FFFFFF] capitalize">Title</th>
                  <th className="px-6 py-4 text-[14px] font-medium leading-[20px] text-[#FFFFFF] capitalize">Source</th>
                  <th className="px-6 py-4 text-[14px] font-medium leading-[20px] text-[#FFFFFF] capitalize">AI Classification</th>
                  <th className="px-6 py-4 text-[14px] font-medium leading-[20px] text-[#FFFFFF] capitalize">Confidence</th>
                  <th className="px-6 py-4 text-[14px] font-medium leading-[20px] text-[#FFFFFF] capitalize">Flags</th>
                  <th className="px-6 py-4 text-[14px] font-medium leading-[20px] text-[#FFFFFF] capitalize">Imported</th>
                  <th className="px-6 py-4 text-[14px] font-medium leading-[20px] text-[#FFFFFF] capitalize">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-[#2A2A2A]">
                {filteredGigs.map((gig) => (
                  <tr key={gig.id} className="hover:bg-white/[0.02] transition-colors group">
                    <td className="px-6 py-5 text-white font-bold text-[14px] truncate max-w-[200px]">{gig.title}</td>
                    <td className="px-6 py-5 text-[#a1a1aa] text-[14px] font-medium">{gig.source}</td>
                    <td className="px-6 py-5">
                      <span className={`px-3 py-1 rounded-full text-[11px] font-bold ${
                        gig.flags === 'Spam' ? 'bg-[#ef4444]/10 text-[#ef4444]' : 'bg-[#b3ff00]/10 text-[#b3ff00]'
                      }`}>
                        {gig.classification}
                      </span>
                    </td>
                    <td className="px-6 py-5 text-[#10b981] font-bold text-[14px]">{gig.confidence}</td>
                    <td className="px-6 py-5">
                      <span className={`px-2 py-0.5 rounded text-[11px] font-bold uppercase ${
                        gig.flags === 'None' ? 'text-[#52525b]' : 
                        gig.flags === 'Duplicate' ? 'bg-[#f59e0b]/10 text-[#f59e0b]' : 'bg-[#ef4444]/10 text-[#ef4444]'
                      }`}>
                        {gig.flags}
                      </span>
                    </td>
                    <td className="px-6 py-5 text-[#a1a1aa] text-[13px]">{gig.importedAt}</td>
                    <td className="px-6 py-5">
                      <div className="flex items-center gap-4">
                        <button 
                          onClick={() => setEditModal({ show: true, gig })}
                          className="text-[#b3ff00] text-[13px] font-bold hover:underline"
                        >
                          Edit
                        </button>
                        <button 
                          onClick={() => setDeleteModal({ show: true, gigId: gig.id })}
                          className="text-[#ef4444] text-[13px] font-bold hover:underline"
                        >
                          Delete
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <Toast show={toast.show} message={toast.message} onClose={() => setToast({ show: false, message: "" })} />
      
      <ConfirmationModal 
        isOpen={deleteModal.show}
        onClose={() => setDeleteModal({ show: false, gigId: null })}
        onConfirm={handleDeleteGig}
        title="Delete Scraped Gig?"
        description="This action will permanently remove the scraped gig from the moderation queue."
        cancelLabel="Cancel"
        confirmLabel="Delete Gig"
      />
      <ScraperDetailsModal 
        isOpen={detailsModal.show}
        onClose={() => setDetailsModal({ show: false, run: null })}
        runData={detailsModal.run}
      />
      <EditScrapedGigModal 
        isOpen={editModal.show}
        onClose={() => setEditModal({ show: false, gig: null })}
        gigData={editModal.gig}
        onSave={(updatedGig) => {
          setImportedGigs(prev => prev.map(g => g.id === updatedGig.id ? updatedGig : g));
          setEditModal({ show: false, gig: null });
          setToast({ show: true, message: "Gig updated successfully" });
        }}
      />
      <RunScraperModal 
        isOpen={runScraperModal}
        onClose={() => setRunScraperModal(false)}
      />
    </div>
  );
}
