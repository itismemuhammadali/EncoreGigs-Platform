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
}

export function RunScraperModal({ isOpen, onClose, onConfirm }: RunScraperModalProps) {
  const [step, setStep] = useState<"select" | "running" | "saving" | "results">("select");
  const [selectedSources, setSelectedSources] = useState<string[]>(["craigslist", "eventbrite", "facebook", "gigsalad"]);
  const [progress, setProgress] = useState<Record<string, number>>({});
  const [realResults, setRealResults] = useState<any[]>([]);
  const [isPolling, setIsPolling] = useState(false);
  
  const runStartTime = useRef<number>(0);

  useEffect(() => {
    if (!isOpen) {
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

  const fetchResults = async () => {
    try {
      const runs = await apiRequest("/scraper/runs?limit=20");
      // Look for any run in the last 15 minutes relative to when WE started it
      const searchCutoff = runStartTime.current - (15 * 60 * 1000); 

      const latestPerSource = selectedSources.map(sourceId => {
        const found = runs.find((r: any) => {
          const runTime = new Date(r.timestamp).getTime();
          return r.source.toLowerCase() === sourceId.toLowerCase() && runTime > searchCutoff;
        });
        
        return found || {
          source: sourceId,
          imported: 0,
          duplicates: 0,
          errors: 0,
          status: "waiting"
        };
      });
      
      setRealResults(latestPerSource);
      
      // Stop polling when everything is success or failed
      const allDone = latestPerSource.every(r => r.status === "success" || r.status === "failed");
      return allDone;
    } catch (error) {
      return false;
    }
  };

  const handleRun = () => {
    runStartTime.current = Date.now();
    if (onConfirm) onConfirm(selectedSources);
    setStep("running");
    
    const runProcess = async () => {
      // 1. Progress Simulation (Fast)
      for (const source of selectedSources) {
        let p = 0;
        while (p <= 100) {
          setProgress(prev => ({ ...prev, [source]: p }));
          p += 50;
          await new Promise(r => setTimeout(r, 200));
        }
      }
      
      // 2. Real Polling for Database entries
      setIsPolling(true);
      for (let i = 0; i < 45; i++) { // Try for 90 seconds
        const isDone = await fetchResults();
        if (isDone) break;
        await new Promise(r => setTimeout(r, 2000));
      }
      
      setIsPolling(false);
      setStep("saving");
      
      // Start a 15s UI timer (does not block saving) as requested
      const timerPromise = new Promise<void>(res => setTimeout(res, 15000));

      const pollForGigs = async () => {
        for (let retry = 0; retry < 40; retry++) { 
          try {
            const importedGigs = await apiRequest("/scraper/imported?filter_type=all");
            if (importedGigs && importedGigs.length > 0) {
              await fetchResults();
              return true;
            }
          } catch (e) {
            // ignore
          }
          await new Promise(r => setTimeout(r, 500));
        }
        return false;
      };

      // We wait for the timer to ensure the design flow the user built is respected
      await timerPromise;
      await fetchResults();
      setStep("results");
    };
    
    runProcess();
  };

  if (!isOpen) return null;

  const totalImported = realResults.reduce((sum, r) => sum + (r.imported || 0), 0);
  const totalDuplicates = realResults.reduce((sum, r) => sum + (r.duplicates || 0), 0);
  const totalErrors = realResults.reduce((sum, r) => sum + (r.errors || 0), 0);
  const totalSpam = realResults.reduce((sum, r) => sum + (r.spam || 0), 0);

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
                <p className="text-white font-semibold text-lg text-center">{isPolling ? "Fetching live data..." : "Starting scrapers..."}</p>
              </div>

              <div className="space-y-4">
                {selectedSources.map((srcId) => {
                  const r = realResults.find(rr => rr.source?.toLowerCase() === srcId.toLowerCase()) || { source: srcId, status: 'waiting' };
                  const prog = progress[srcId] ?? 0;
                  const isRunning = (r.status === 'running' || isPolling);
                  return (
                    <div key={srcId} className="p-4 border rounded-[10px] bg-[#0b0b0b]" style={{ borderColor: '#1f1f1f' }}>
                      <div className="flex items-center justify-between mb-3">
                        <div className="flex items-center gap-3">
                          <div>
                            {isRunning ? (
                              <Loader2 className="w-5 h-5 text-[#3B82F6] animate-spin" />
                            ) : r.status === 'success' ? (
                              <CheckCircle2 className="w-5 h-5 text-[#10B981]" />
                            ) : r.status === 'failed' ? (
                              <AlertCircle className="w-5 h-5 text-[#EF4444]" />
                            ) : (
                              <Clock className="w-5 h-5 text-[#9CA3AF]" />
                            )}
                          </div>
                          <span className="text-lg capitalize font-medium text-white">{r.source}</span>
                        </div>
                        <div className="flex items-center gap-3">
                          <span className="px-2 py-1 text-xs rounded" style={{ backgroundColor: isRunning ? 'rgba(59,130,246,0.1)' : (r.status === 'success' ? 'rgba(16,185,129,0.1)' : 'rgba(107,114,128,0.12)'), color: isRunning ? '#3B82F6' : '#D1D5DB' }}>{r.status === 'success' ? 'finished' : (r.status === 'failed' ? 'failed' : (isRunning ? 'running' : r.status))}</span>
                        </div>
                      </div>

                      <div className="w-full bg-[#0f0f0f] rounded-full h-3 overflow-hidden border border-[#262626]">
                        <div className="h-3 bg-[#A2F301] rounded-full transition-all" style={{ width: `${Math.min(Math.max(prog, 0), 100)}%` }} />
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
                <p className="text-[#9CA3AF] mt-2">Please wait while we process and store the data.</p>
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
                  <p className="text-[#9CA3AF] text-xs uppercase mt-2 font-bold tracking-widest">Total Gigs</p>
                </div>
                <div className="bg-[#0b0b0b] border border-[#232323] p-6 rounded-[8px] text-center">
                  <p className="text-[#F59E0B] text-3xl font-bold">{totalDuplicates}</p>
                  <p className="text-[#9CA3AF] text-xs uppercase mt-2 font-bold tracking-widest">Duplicates Filtered</p>
                </div>
                <div className="bg-[#0b0b0b] border border-[#232323] p-6 rounded-[8px] text-center">
                  <p className="text-[#EF4444] text-3xl font-bold">{totalSpam}</p>
                  <p className="text-[#9CA3AF] text-xs uppercase mt-2 font-bold tracking-widest">Spam Filtered</p>
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
                    <div key={i} className="flex items-center justify-between p-4 border border-[#173225] rounded-[8px] bg-[#071612]">
                      <div className="flex items-center gap-3">
                        <CheckCircle2 className="text-[#10B981]" />
                        <span className="text-white font-medium">{r.source}</span>
                      </div>
                      <div className="flex items-center gap-4">
                        <div className="text-[#9CA3AF] text-sm">{r.imported || 0} gigs</div>
                        <div className="text-[#EF4444] text-sm font-bold">{r.errors || 0} errors</div>
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
                <button onClick={handleRun} className="px-6 py-3 sm:px-8 bg-[#A2F301] text-black font-medium rounded-[12px] flex items-center gap-3 shadow-md hover:scale-[1.02] transition-all">
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
