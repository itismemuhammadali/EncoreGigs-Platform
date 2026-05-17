"use client";

import React, { useState, useEffect } from "react";
import { X, Play, Loader2, CheckCircle2, Clock } from "lucide-react";

interface Source {
  id: string;
  name: string;
  description: string;
  disabled?: boolean;
}

const SOURCES: Source[] = [
  { id: "eventbrite", name: "Eventbrite", description: "Event management and ticketing platform" },
  { id: "bandsintown", name: "Bandsintown", description: "Live music discovery platform" },
  { id: "gigsalad", name: "GigSalad", description: "Entertainment booking marketplace" },
  { id: "thumbtack", name: "Thumbtack", description: "Local services marketplace", disabled: true },
  { id: "thebash", name: "The Bash", description: "Event entertainment booking" },
];

interface RunScraperModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export function RunScraperModal({ isOpen, onClose }: RunScraperModalProps) {
  const [step, setStep] = useState<"select" | "running" | "results">("select");
  const [selectedSources, setSelectedSources] = useState<string[]>(["eventbrite", "bandsintown", "gigsalad", "thebash"]);
  const [progress, setProgress] = useState<Record<string, number>>({});

  useEffect(() => {
    if (!isOpen) {
      setStep("select");
      setProgress({});
    }
  }, [isOpen]);

  const toggleSource = (id: string) => {
    setSelectedSources(prev => 
      prev.includes(id) ? prev.filter(s => s !== id) : [...prev, id]
    );
  };

  const handleRun = () => {
    setStep("running");
    // Simulate progress
    const simulateProgress = async () => {
      for (const source of selectedSources) {
        let p = 0;
        while (p <= 100) {
          setProgress(prev => ({ ...prev, [source]: p }));
          p += Math.random() * 30;
          await new Promise(r => setTimeout(r, 800));
        }
      }
      setStep("results");
    };
    simulateProgress();
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-[100] flex items-center justify-center px-4">
      {/* Backdrop */}
      <div 
        className="absolute inset-0 bg-black/60 backdrop-blur-sm animate-in fade-in duration-300"
        onClick={onClose}
      />
      
      {/* Modal Container - Responsive height with max-h for viewport safety */}
      {/* Modal Container - Responsive height with max-h for viewport safety */}
      <div 
        className="bg-[#1A1A1A] w-full max-w-4xl max-h-[95vh] h-auto rounded-[8px] overflow-hidden relative z-10 shadow-2xl animate-in zoom-in-95 duration-300 border border-[#2A2A2A] flex flex-col transition-all duration-300"
      >
        
        {/* Header - Responsive Height */}
        <div className="px-6 py-4 sm:h-[85.06px] border-b border-[#2A2A2A] flex justify-between items-center shrink-0">
          <div className="flex flex-col gap-1 pr-4">
            <h2 className="text-white text-[18px] sm:text-[20px] font-semibold leading-tight">Run Scraper</h2>
            <p className="text-[#999999] text-[13px] sm:text-[14px] font-normal leading-tight">Select the sources you want to scrape and start the process.</p>
          </div>
          <button 
            onClick={onClose}
            className="w-9 h-9 rounded-[8px] border border-white flex items-center justify-center text-white hover:bg-white/5 transition-all shrink-0"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Dynamic Content - Padding 0 32px */}
        <div className="px-4 sm:px-8 py-6 flex-1 overflow-y-auto">
          {step === "select" && (
            <div className="space-y-6">
              <h3 className="text-white text-[14px] font-semibold leading-[20px]">Select Sources</h3>
              
              <div className="flex flex-col sm:flex-row gap-4">
                {/* Column 1 */}
                <div className="flex-1 flex flex-col gap-4">
                  {SOURCES.filter((_, i) => i % 2 === 0).map((source) => {
                    const isSelected = selectedSources.includes(source.id);
                    return (
                      <div 
                        key={source.id}
                        onClick={() => !source.disabled && toggleSource(source.id)}
                        className={`w-full min-h-[72.17px] p-4 rounded-[8.68px] border cursor-pointer transition-all flex items-start gap-4 ${
                          source.disabled 
                            ? 'bg-[#1A1A1A] opacity-60' 
                            : isSelected
                              ? 'bg-[#A2F301]/5'
                              : 'bg-[#1A1A1A] hover:bg-white/[0.02]'
                        }`}
                        style={{ 
                          borderWidth: '1.08513px',
                          borderColor: isSelected ? '#A2F301' : '#2A2A2A'
                        }}
                      >
                        <div className={`w-4 h-4 rounded-[4px] border mt-0.5 shrink-0 transition-all ${
                          isSelected ? 'border-white/80' : 'border-white/20'
                        }`} />
                        <div className="flex flex-col gap-0.5">
                          <p className="text-white font-medium text-[14px] leading-[20px]">{source.name}</p>
                          <p className="text-[#999999] text-[12px] font-medium leading-[16px]">{source.description}</p>
                        </div>
                      </div>
                    );
                  })}
                </div>

                {/* Column 2 */}
                <div className="flex-1 flex flex-col gap-4">
                  {SOURCES.filter((_, i) => i % 2 !== 0).map((source) => {
                    const isSelected = selectedSources.includes(source.id);
                    return (
                      <div 
                        key={source.id}
                        onClick={() => !source.disabled && toggleSource(source.id)}
                        className={`w-full min-h-[72.17px] p-4 rounded-[8.68px] border cursor-pointer transition-all flex items-start gap-4 ${
                          source.disabled 
                            ? 'bg-[#1A1A1A] opacity-60' 
                            : isSelected
                              ? 'bg-[#A2F301]/5'
                              : 'bg-[#1A1A1A] hover:bg-white/[0.02]'
                        }`}
                        style={{ 
                          borderWidth: '1.08513px',
                          borderColor: isSelected ? '#A2F301' : '#2A2A2A'
                        }}
                      >
                        <div className={`w-4 h-4 rounded-[4px] border mt-0.5 shrink-0 transition-all ${
                          isSelected ? 'border-white/80' : 'border-white/20'
                        }`} />
                        <div className="flex flex-col gap-1">
                          <p className="text-white font-medium text-[14px] leading-[20px]">{source.name}</p>
                          <p className="text-[#999999] text-[12px] font-medium leading-[16px]">{source.description}</p>
                          {source.disabled && (
                            <div className="mt-1 flex">
                              <span className="px-2 py-0.5 bg-[#f59e0b]/10 text-[#f59e0b] rounded-[4px] text-[12px] font-medium leading-[16px]">Disabled</span>
                            </div>
                          )}
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>

              {/* Summary Bar */}
              <div className="w-full h-[52px] bg-[#333333]/30 border border-[#2A2A2A] rounded-[8px] px-4 flex items-center shrink-0 mt-2">
                <p className="text-white text-[14px] font-bold leading-[20px]">
                  {selectedSources.length} sources selected
                </p>
              </div>
            </div>
          )}

          {step === "running" && (
            <div className="flex flex-col items-center gap-6">
              {/* Central Spinner */}
              <div className="w-full py-8 flex items-center justify-center shrink-0">
                <div 
                  className="w-8 h-8 rounded-full"
                  style={{ 
                    border: '3px solid #A2F301',
                    borderTopColor: 'transparent',
                    animation: 'scraper-spin 1s linear infinite'
                  }}
                />
              </div>
              
              {/* Progress Cards Container */}
              <div className="w-full flex flex-col gap-4">
                {selectedSources.map((sourceId) => {
                  const source = SOURCES.find(s => s.id === sourceId);
                  const p = progress[sourceId] || 0;
                  const isDone = p >= 100;
                  const isStarted = p > 0;
                  const isRunning = isStarted && !isDone;

                  return (
                    <div 
                      key={sourceId} 
                      className={`w-full px-4 rounded-[8px] border border-[#2A2A2A] flex flex-col justify-center transition-all duration-300 ${
                        isRunning ? 'min-h-[72px] gap-2 py-4' : 'h-[56.01px] py-0'
                      }`}
                    >
                      <div className="w-full flex justify-between items-center h-auto min-h-[24px]">
                        <div className="flex items-center gap-[4.82px]">
                          <p className="text-white text-[15px] sm:text-[16px] font-medium leading-tight">{source?.name}</p>
                          {isRunning && (
                            <div 
                              className="w-4 h-4 rounded-full"
                              style={{ 
                                border: '1.5px solid #A2F301',
                                borderTopColor: 'transparent',
                                animation: 'scraper-spin 1s linear infinite'
                              }}
                            />
                          )}
                          {!isStarted && !isDone && (
                            <Clock className="w-4 h-4 text-[#999999]" />
                          )}
                          {isDone && (
                            <CheckCircle2 className="w-4 h-4 text-[#10b981]" />
                          )}
                        </div>
                        
                        <div className="flex items-center gap-3">
                          {isStarted && (
                            <p className="text-[#999999] text-[13px] sm:text-[14px] font-normal">22 gigs</p>
                          )}
                          <div className={`px-2 py-[4px] rounded-[4px] min-w-[60px] flex items-center justify-center transition-all ${
                            isDone 
                              ? 'bg-[#10b981]/10 text-[#10b981]' 
                              : isRunning 
                                ? 'bg-[#3B82F6]/10 text-[#3B82F6]' 
                                : 'bg-[#333333] text-[#999999]'
                          }`}>
                            <span className="text-[11px] sm:text-[12px] font-medium leading-none">
                              {isDone ? 'completed' : isRunning ? 'running' : 'waiting'}
                            </span>
                          </div>
                        </div>
                      </div>

                      {isRunning && (
                        <div className="w-full h-2 bg-[#333333] rounded-full overflow-hidden">
                          <div 
                            className="h-full bg-[#A2F301] transition-all duration-500 rounded-full"
                            style={{ width: `${p}%` }}
                          />
                        </div>
                      )}
                    </div>
                  );
                })}
              </div>
            </div>
          )}

          {step === "results" && (
            <div className="space-y-6">
              {/* Success Banner */}
              <div className="w-full h-auto py-8 bg-[#10B981]/10 border border-[#10B981]/20 rounded-[8px] flex flex-col items-center justify-center gap-[10px] shrink-0 px-4">
                <div className="w-12 h-12 flex items-center justify-center">
                  <CheckCircle2 className="w-full h-full text-[#10B981] stroke-[3px]" />
                </div>
                <h3 className="text-white text-[18px] sm:text-[20px] font-bold leading-tight text-center">Scraper Completed Successfully!</h3>
                <p className="text-[#999999] text-[13px] sm:text-[14px] font-normal leading-tight text-center">Processed 4 sources in 12m 39s</p>
              </div>

              {/* Stats Grid */}
              <div className="grid grid-cols-2 sm:grid-cols-4 gap-4 w-full">
                <div className="h-[92px] bg-[#1A1A1A] border border-[#2A2A2A] rounded-[8px] flex flex-col items-center justify-center gap-1 p-2">
                  <p className="text-[#A2F301] text-2xl sm:text-[30px] font-bold leading-none">77</p>
                  <p className="text-[#999999] text-[12px] sm:text-[14px] font-normal leading-tight text-center">Total Gigs</p>
                </div>
                <div className="h-[92px] bg-[#1A1A1A] border border-[#2A2A2A] rounded-[8px] flex flex-col items-center justify-center gap-1 p-2">
                  <p className="text-[#F59E0B] text-2xl sm:text-[30px] font-bold leading-none">7</p>
                  <p className="text-[#999999] text-[12px] sm:text-[14px] font-normal leading-tight text-center">Duplicates Filtered</p>
                </div>
                <div className="h-[92px] bg-[#1A1A1A] border border-[#2A2A2A] rounded-[8px] flex flex-col items-center justify-center gap-1 p-2">
                  <p className="text-[#EF4444] text-2xl sm:text-[30px] font-bold leading-none">3</p>
                  <p className="text-[#999999] text-[12px] sm:text-[14px] font-normal leading-tight text-center">Spam Filtered</p>
                </div>
                <div className="h-[92px] bg-[#1A1A1A] border border-[#2A2A2A] rounded-[8px] flex flex-col items-center justify-center gap-1 p-2">
                  <p className="text-[#EF4444] text-2xl sm:text-[30px] font-bold leading-none">8</p>
                  <p className="text-[#999999] text-[12px] sm:text-[14px] font-normal leading-tight text-center">Total Errors</p>
                </div>
              </div>

              {/* Source Breakdown */}
              <div className="space-y-[10px]">
                <h4 className="text-white text-[14px] font-semibold leading-[20px]">Source Breakdown</h4>
                <div className="flex flex-col gap-2">
                  {selectedSources.map((sourceId) => {
                    const source = SOURCES.find(s => s.id === sourceId);
                    return (
                      <div 
                        key={sourceId}
                        className="w-full min-h-[46.18px] bg-[#10B981]/[0.05] border border-[#10B981]/20 rounded-[8px] p-3 flex flex-col sm:flex-row sm:items-center justify-between gap-2"
                      >
                        <div className="flex items-center gap-[7.99px]">
                          <CheckCircle2 className="w-4 h-4 text-[#10B981]" />
                          <p className="text-white text-[15px] sm:text-[16px] font-medium leading-tight">{source?.name}</p>
                        </div>
                        <div className="flex items-center gap-4">
                          <p className="text-[#999999] text-[13px] sm:text-[14px] font-normal">24 gigs</p>
                          <p className="text-[#EF4444] text-[13px] sm:text-[14px] font-normal">2 errors</p>
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>
            </div>
          )}
        </div>

        {/* Footer - Responsive Height */}
        <div className="px-6 py-4 border-t border-[#2A2A2A] bg-[#1A1A1A] flex items-center shrink-0">
          {step === "select" && (
            <div className="flex gap-2 w-full">
              <button 
                onClick={handleRun}
                disabled={selectedSources.length === 0}
                className="flex-1 sm:flex-none sm:w-[149.99px] h-[44px] bg-[#A2F301] text-[#000000] rounded-[8px] font-medium text-[16px] flex items-center justify-center gap-2 hover:bg-[#91da00] transition-all disabled:opacity-50 disabled:cursor-not-allowed"
              >
                <Play className="w-4 h-4 fill-black" />
                Run Scraper
              </button>
              <button 
                onClick={onClose}
                className="flex-1 sm:flex-none sm:w-[101px] h-[44px] bg-[#333333] text-[#999999] rounded-[8px] font-medium text-[16px] flex items-center justify-center hover:bg-[#404040] transition-all"
              >
                Cancel
              </button>
            </div>
          )}
          {step === "running" && null}
          {step === "results" && (
            <button 
              onClick={onClose}
              className="w-full sm:w-[76px] h-[44px] bg-[#A2F301] text-[#000000] rounded-[8px] font-medium text-[16px] flex items-center justify-center hover:bg-[#91da00] transition-all"
            >
              Close
            </button>
          )}
        </div>
      </div>
    </div>
  );
}
