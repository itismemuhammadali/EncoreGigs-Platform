"use client";

import React, { useState, useEffect, useRef } from "react";
import { X, Play, Loader2, CheckCircle2, Clock, AlertCircle } from "lucide-react";
import { apiRequest } from "@/lib/api";

interface Source {
  id: string;
  name: string;
  description: string;
  disabled?: boolean;
}

const SOURCES: Source[] = [
  { id: "craigslist", name: "Craigslist", description: "Community gig listings (Musicians section)" },
  { id: "eventbrite", name: "Eventbrite", description: "Global event discovery for live music" },
  { id: "facebook", name: "Facebook", description: "Local musician groups and community posts" },
  { id: "gigsalad", name: "GigSalad", description: "Professional entertainment booking platform" },
];

interface RunScraperModalProps {
  isOpen: boolean;
  onClose: () => void;
  onConfirm?: (sources: string[]) => void;
  onRefreshData?: () => void;
}

interface SourceResult {
  source: string;
  imported: number;
  duplicates: number;
  errors: number;
  status: "waiting" | "running" | "success" | "failed";
  message?: string;
}

export function RunScraperModal({ isOpen, onClose, onConfirm, onRefreshData }: RunScraperModalProps) {
  const [step, setStep] = useState<"select" | "running" | "saving" | "results">("select");
  const [selectedSources, setSelectedSources] = useState<string[]>(["craigslist", "eventbrite", "facebook", "gigsalad"]);
  const [progress, setProgress] = useState<Record<string, number>>({});
  const [realResults, setRealResults] = useState<SourceResult[]>([]);
  const [isPolling, setIsPolling] = useState(false);

  const sessionIdRef = useRef<string>("");
  const runStartTime = useRef<number>(0);
  const pollingTimerRef = useRef<NodeJS.Timeout | null>(null);

  useEffect(() => {
    if (!isOpen) {
      if (pollingTimerRef.current) clearInterval(pollingTimerRef.current);
      setStep("select");
      setProgress({});
      setRealResults([]);
      setIsPolling(false);
    }
  }, [isOpen]);

  const toggleSource = (id: string) => {
    setSelectedSources(prev => 
      prev.includes(id) ? prev.filter(s => s !== id) : [...prev, id]
    );
  };

  const handleRun = async () => {
    if (selectedSources.length === 0) return;

    runStartTime.current = Date.now();
    setStep("running");
    setIsPolling(true);

    // Initial state for each selected source
    const initialResults: SourceResult[] = selectedSources.map(s => ({
      source: s,
      imported: 0,
      duplicates: 0,
      errors: 0,
      status: "running"
    }));
    setRealResults(initialResults);

    const initialProg: Record<string, number> = {};
    selectedSources.forEach(s => { initialProg[s] = 15; });
    setProgress(initialProg);

    let activeSessionId = "";

    try {
      // 1. Trigger backend scraper runner with selected sources asynchronously
      const res = await apiRequest("/scraper/run", {
        method: "POST",
        body: JSON.stringify({ sources: selectedSources })
      });
      if (res && res.session_id) {
        activeSessionId = res.session_id;
        sessionIdRef.current = activeSessionId;
      }
    } catch (err) {
      console.error("Failed to start scraper run:", err);
    }

    const startTimestamp = runStartTime.current;
    let pollCount = 0;
    const maxPolls = 60; // 60 * 1.5s = 90s safety timeout

    // 2. Poll /scraper/runs every 1.5 seconds for live status & counts
    pollingTimerRef.current = setInterval(async () => {
      pollCount++;
      try {
        const rawRuns = await apiRequest("/scraper/runs?limit=30");
        const runs: any[] = Array.isArray(rawRuns) ? rawRuns : [];

        let allCompleted = true;

        setRealResults(prev => {
          const updated = prev.map(item => {
            const srcLower = item.source.toLowerCase();

            // Match by sessionId or by recent timestamp (created after run started)
            const match = runs.find((r: any) => {
              if (r.source?.toLowerCase() !== srcLower) return false;
              if (activeSessionId && r.sessionId === activeSessionId) return true;
              if (r.timestamp && r.timestamp !== "N/A") {
                const runMs = new Date(r.timestamp).getTime();
                return runMs >= (startTimestamp - 5000);
              }
              return false;
            });

            if (!match) {
              allCompleted = false;
              setProgress(p => ({
                ...p,
                [item.source]: Math.min((p[item.source] || 15) + 4, 90)
              }));
              return item;
            }

            const matchStatus = match.status; // "running", "success", "failed"
            const isDone = matchStatus === "success" || matchStatus === "failed";

            if (!isDone) {
              allCompleted = false;
            }

            // Update progress bar
            setProgress(p => ({
              ...p,
              [item.source]: isDone ? 100 : Math.min((p[item.source] || 15) + 6, 92)
            }));

            return {
              source: item.source,
              imported: match.imported ?? 0,
              duplicates: match.duplicates ?? 0,
              errors: match.errors ?? 0,
              status: matchStatus,
            };
          });

          return updated;
        });

        // 3. When all selected sources are finished (or safety timeout reached)
        if (allCompleted || pollCount >= maxPolls) {
          if (pollingTimerRef.current) clearInterval(pollingTimerRef.current);
          setIsPolling(false);

          selectedSources.forEach(s => {
            setProgress(p => ({ ...p, [s]: 100 }));
          });

          setStep("saving");
          await new Promise(r => setTimeout(r, 1200));

          if (onRefreshData) onRefreshData();
          setStep("results");
        }
      } catch (e) {
        console.error("Error polling scraper runs:", e);
      }
    }, 1500);
  };

  if (!isOpen) return null;

  const totalImported = realResults.reduce((sum, r) => sum + (r.imported || 0), 0);
  const totalDuplicates = realResults.reduce((sum, r) => sum + (r.duplicates || 0), 0);
  const totalErrors = realResults.reduce((sum, r) => sum + (r.errors || 0), 0);

  const runDuration = () => {
    if (!runStartTime.current) return '0s';
    const diff = Date.now() - runStartTime.current;
    const s = Math.floor(diff / 1000);
    const m = Math.floor(s / 60);
    const sec = s % 60;
    return m > 0 ? `${m}m ${sec}s` : `${sec}s`;
  };

  return (
    <div className="fixed inset-0 z-[100] flex items-center justify-center px-4">
      <div className="absolute inset-0 bg-black/60 backdrop-blur-sm animate-in fade-in duration-300" onClick={onClose} />
      
      <div className="bg-[#1A1A1A] w-full max-w-4xl max-h-[95vh] rounded-[8px] overflow-hidden relative z-10 shadow-2xl border border-[#2A2A2A] flex flex-col">
        
        <div className="px-6 py-4 border-b border-[#2A2A2A] flex justify-between items-center">
          <div>
            <h2 className="text-white text-[20px] font-semibold">Scraper Manager</h2>
            <p className="text-[#999999] text-[14px]">Tracking musician gigs in real-time.</p>
          </div>
          <button onClick={onClose} className="text-white opacity-50 hover:opacity-100 transition-all"><X className="w-5 h-5" /></button>
        </div>

        <div className="px-8 py-6 flex-1 overflow-y-auto">
          {step === "select" && (
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              {SOURCES.map((source) => (
                <div 
                  key={source.id}
                  onClick={() => toggleSource(source.id)}
                  className={`p-4 rounded-[8px] border cursor-pointer transition-all flex items-start gap-4 ${
                    selectedSources.includes(source.id) ? 'bg-[#A2F301]/5 border-[#A2F301]' : 'bg-[#1A1A1A] border-[#2A2A2A] hover:bg-white/[0.02]'
                  }`}
                >
                  <div className={`w-4 h-4 rounded-[4px] border mt-0.5 ${selectedSources.includes(source.id) ? 'bg-[#A2F301] border-[#A2F301]' : 'border-white/20'}`} />
                  <div>
                    <p className="text-white font-medium">{source.name}</p>
                    <p className="text-[#999999] text-[12px]">{source.description}</p>
                  </div>
                </div>
              ))}
            </div>
          )}

          {step === "running" && (
            <div className="space-y-6">
              <div className="py-6">
                <Loader2 className="w-12 h-12 text-[#A2F301] animate-spin mx-auto mb-2" />
                <p className="text-white font-semibold text-lg text-center">Fetching live gig listings...</p>
                <p className="text-[#888888] text-sm text-center mt-1">Processing selected sources simultaneously in real time</p>
              </div>

              <div className="space-y-4">
                {selectedSources.map((srcId) => {
                  const r = realResults.find(rr => rr.source?.toLowerCase() === srcId.toLowerCase()) || { source: srcId, status: 'running', imported: 0, errors: 0 };
                  const prog = progress[srcId] ?? 15;
                  const isRunning = r.status === 'running';
                  const isSuccess = r.status === 'success';
                  const isFailed = r.status === 'failed';

                  return (
                    <div key={srcId} className="p-4 border rounded-[10px] bg-[#0b0b0b]" style={{ borderColor: '#1f1f1f' }}>
                      <div className="flex items-center justify-between mb-3">
                        <div className="flex items-center gap-3">
                          <div>
                            {isRunning ? (
                              <Loader2 className="w-5 h-5 text-[#3B82F6] animate-spin" />
                            ) : isSuccess ? (
                              <CheckCircle2 className="w-5 h-5 text-[#10B981]" />
                            ) : isFailed ? (
                              <AlertCircle className="w-5 h-5 text-[#EF4444]" />
                            ) : (
                              <Clock className="w-5 h-5 text-[#9CA3AF]" />
                            )}
                          </div>
                          <span className="text-lg capitalize font-medium text-white">{r.source}</span>
                        </div>
                        <div className="flex items-center gap-3">
                          {isSuccess && (
                            <span className="text-[#A2F301] text-sm font-semibold">{r.imported} gigs found</span>
                          )}
                          <span
                            className="px-2.5 py-1 text-xs font-semibold rounded-md uppercase tracking-wider"
                            style={{
                              backgroundColor: isRunning ? 'rgba(59,130,246,0.15)' : isSuccess ? 'rgba(16,185,129,0.15)' : 'rgba(239,68,68,0.15)',
                              color: isRunning ? '#60A5FA' : isSuccess ? '#34D399' : '#F87171'
                            }}
                          >
                            {isSuccess ? 'finished' : isFailed ? 'failed' : 'running'}
                          </span>
                        </div>
                      </div>

                      <div className="w-full bg-[#0f0f0f] rounded-full h-3 overflow-hidden border border-[#262626]">
                        <div
                          className="h-3 bg-[#A2F301] rounded-full transition-all duration-300"
                          style={{ width: `${Math.min(Math.max(prog, 0), 100)}%` }}
                        />
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          )}

          {step === "saving" && (
            <div className="space-y-6 py-12">
              <div className="text-center">
                <Loader2 className="w-16 h-16 text-[#A2F301] animate-spin mx-auto mb-4" />
                <p className="text-white font-semibold text-lg">Saving scraped gigs to database...</p>
                <p className="text-[#9CA3AF] mt-2">Processing duplicates and indexing newly discovered gigs.</p>
              </div>
            </div>
          )}

          {step === "results" && (
            <div className="space-y-6">
              <div className="bg-[#0f2f24] border border-[#123827] p-6 rounded-[8px] text-center">
                <div className="flex flex-col items-center justify-center gap-3">
                  <CheckCircle2 className="w-12 h-12 text-[#10B981]" />
                  <h3 className="text-white text-lg font-bold">Scraper Completed Successfully!</h3>
                  <p className="text-[#9CA3AF] text-sm">Processed {selectedSources.length} sources in {runDuration()}</p>
                </div>
              </div>

              <div className="grid grid-cols-4 gap-4">
                <div className="bg-[#0b0b0b] border border-[#232323] p-6 rounded-[8px] text-center">
                  <p className="text-[#A2F301] text-3xl font-bold">{totalImported}</p>
                  <p className="text-[#9CA3AF] text-xs uppercase mt-2 font-bold tracking-widest">New Gigs Added</p>
                </div>
                <div className="bg-[#0b0b0b] border border-[#232323] p-6 rounded-[8px] text-center">
                  <p className="text-[#F59E0B] text-3xl font-bold">{totalDuplicates}</p>
                  <p className="text-[#9CA3AF] text-xs uppercase mt-2 font-bold tracking-widest">Duplicates Filtered</p>
                </div>
                <div className="bg-[#0b0b0b] border border-[#232323] p-6 rounded-[8px] text-center">
                  <p className="text-[#3B82F6] text-3xl font-bold">{totalImported + totalDuplicates}</p>
                  <p className="text-[#9CA3AF] text-xs uppercase mt-2 font-bold tracking-widest">Total Scanned</p>
                </div>
                <div className="bg-[#0b0b0b] border border-[#232323] p-6 rounded-[8px] text-center">
                  <p className="text-[#EF4444] text-3xl font-bold">{totalErrors}</p>
                  <p className="text-[#9CA3AF] text-xs uppercase mt-2 font-bold tracking-widest">Total Errors</p>
                </div>
              </div>

              <div>
                <h4 className="text-white text-sm font-bold mb-3">Source Breakdown</h4>
                <div className="space-y-3">
                  {realResults.map((r, i) => (
                    <div
                      key={i}
                      className={`flex items-center justify-between p-4 border rounded-[8px] ${
                        r.status === 'failed'
                          ? 'border-red-900/40 bg-red-950/20'
                          : 'border-[#173225] bg-[#071612]'
                      }`}
                    >
                      <div className="flex items-center gap-3">
                        {r.status === 'failed' ? (
                          <AlertCircle className="text-[#EF4444] w-5 h-5" />
                        ) : (
                          <CheckCircle2 className="text-[#10B981] w-5 h-5" />
                        )}
                        <span className="text-white font-medium capitalize">{r.source}</span>
                      </div>
                      <div className="flex items-center gap-4">
                        <div className="text-[#9CA3AF] text-sm">
                          <span className="text-[#A2F301] font-bold">{r.imported || 0} new</span>
                          {r.duplicates > 0 && <span className="text-[#F59E0B] ml-2">({r.duplicates} duplicates)</span>}
                        </div>
                        <div className={`text-sm font-bold ${r.errors > 0 ? 'text-[#EF4444]' : 'text-zinc-500'}`}>
                          {r.errors || 0} errors
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          )}
        </div>

        <div className="px-6 py-4 border-t border-[#2A2A2A] bg-[#1A1A1A] flex items-center justify-between">
          {step === "select" && (
            <>
              <div className="text-[#999999] px-4 py-3 rounded-md bg-[#0f0f0f]">{selectedSources.length} sources selected</div>
              <div className="flex items-center gap-3">
                <button onClick={onClose} className="px-6 py-3 bg-[#2A2A2A] text-white rounded-[8px] hover:opacity-90 transition-all">Cancel</button>
                <button
                  onClick={handleRun}
                  disabled={selectedSources.length === 0}
                  className="px-6 py-3 sm:px-8 bg-[#A2F301] text-black font-medium rounded-[12px] flex items-center gap-3 shadow-md hover:scale-[1.02] transition-all disabled:opacity-50 disabled:hover:scale-100"
                >
                  <Play className="w-5 h-5 stroke-[2px]" />
                  <span className="text-lg">Run Scraper</span>
                </button>
              </div>
            </>
          )}

          {step === "running" && (
            <div className="ml-auto text-[#999999] px-4 py-3 rounded-md bg-[#0f0f0f]">{selectedSources.length} sources selected</div>
          )}

          {step === "saving" && (
            <div className="ml-auto text-[#999999] px-4 py-3 rounded-md bg-[#0f0f0f]">Saving results...</div>
          )}

          {step === "results" && (
            <div className="w-full flex justify-end">
              <button onClick={onClose} className="px-6 py-3 bg-[#A2F301] text-black font-bold rounded-[12px] hover:opacity-95 transition-all">DONE</button>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
