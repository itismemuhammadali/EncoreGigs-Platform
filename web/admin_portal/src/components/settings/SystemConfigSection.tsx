"use client";

import React, { useState, useEffect, useRef } from "react";
import { 
  Key, 
  Globe, 
  RefreshCw, 
  CheckCircle, 
  AlertCircle, 
  Save, 
  Mail, 
  Upload, 
  FileText, 
  Download, 
  Check, 
  X, 
  Plus, 
  Trash2,
  Lock,
  Layers
} from "lucide-react";

export function SystemConfigSection() {
  const [sources, setSources] = useState<any[]>([]);
  const [loadingSources, setLoadingSources] = useState(true);
  const [newUrl, setNewUrl] = useState("");
  const [newName, setNewName] = useState("");
  const [addingSource, setAddingSource] = useState(false);

  // CSV Upload States
  const [sourceMode, setSourceMode] = useState<"manual" | "csv">("manual");
  const [csvFile, setCsvFile] = useState<File | null>(null);
  const [parsedCsvSources, setParsedCsvSources] = useState<{ name: string; url: string; type: string }[]>([]);
  const [csvError, setCsvError] = useState<string | null>(null);
  const [csvSuccess, setCsvSuccess] = useState<string | null>(null);
  const [importingCsv, setImportingCsv] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);

  // Cookies State
  const [cookiesJson, setCookiesJson] = useState("");
  const [savingCookies, setSavingCookies] = useState(false);
  const [cookiesMessage, setCookiesMessage] = useState<{ type: "success" | "error"; text: string } | null>(null);

  // SendGrid State
  const [sendgridKey, setSendgridKey] = useState("");
  const [senderEmail, setSenderEmail] = useState("notifications@onlygigz.app");
  const [sendgridStatus, setSendgridStatus] = useState<any>(null);
  const [savingSendgrid, setSavingSendgrid] = useState(false);
  const [sendgridMessage, setSendgridMessage] = useState<{ type: "success" | "error"; text: string } | null>(null);

  const API_URL = process.env.NEXT_PUBLIC_API_URL || "http://127.0.0.1:8000";

  useEffect(() => {
    fetchSources();
    fetchSendgridConfig();
  }, []);

  const fetchSendgridConfig = async () => {
    try {
      const res = await fetch(`${API_URL}/auth/sendgrid-config`);
      if (res.ok) {
        const data = await res.json();
        setSendgridStatus(data);
        if (data.from_email) setSenderEmail(data.from_email);
      }
    } catch (err) {
      console.error("Failed to fetch SendGrid config:", err);
    }
  };

  const handleSaveSendgrid = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!sendgridKey.trim()) {
      setSendgridMessage({ type: "error", text: "Please enter your Twilio SendGrid API Key (SG.xxxxxxxx...)" });
      return;
    }
    setSavingSendgrid(true);
    setSendgridMessage(null);
    try {
      const res = await fetch(`${API_URL}/auth/sendgrid-config`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          sendgrid_api_key: sendgridKey.trim(),
          from_email: senderEmail.trim() || "notifications@onlygigz.app",
        }),
      });

      if (res.ok) {
        const data = await res.json();
        setSendgridMessage({ type: "success", text: data.message || "Twilio SendGrid API Key saved successfully to Firebase!" });
        setSendgridKey("");
        fetchSendgridConfig();
      } else {
        const data = await res.json();
        setSendgridMessage({ type: "error", text: data.detail || "Failed to save SendGrid key" });
      }
    } catch (err: any) {
      setSendgridMessage({ type: "error", text: `Error: ${err.message}` });
    } finally {
      setSavingSendgrid(false);
    }
  };

  const fetchSources = async () => {
    try {
      setLoadingSources(true);
      const res = await fetch(`${API_URL}/scraper/sources`);
      if (res.ok) {
        const data = await res.json();
        setSources(data);
      }
    } catch (err) {
      console.error("Failed to fetch sources:", err);
    } finally {
      setLoadingSources(false);
    }
  };

  const handleAddSource = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newUrl.trim()) return;

    setAddingSource(true);
    try {
      const res = await fetch(`${API_URL}/scraper/sources`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          url: newUrl.trim(),
          name: newName.trim() || "Facebook Group",
          type: "facebook_group",
        }),
      });

      if (res.ok) {
        setNewUrl("");
        setNewName("");
        fetchSources();
      }
    } catch (err) {
      console.error("Failed to add source:", err);
    } finally {
      setAddingSource(false);
    }
  };

  const handleDeleteSource = async (id: string) => {
    if (!confirm("Are you sure you want to delete this scraper source?")) return;

    try {
      const res = await fetch(`${API_URL}/scraper/sources/${id}`, {
        method: "DELETE",
      });
      if (res.ok) {
        fetchSources();
      }
    } catch (err) {
      console.error("Failed to delete source:", err);
    }
  };

  const parseCsvContent = (text: string) => {
    setCsvError(null);
    setCsvSuccess(null);
    try {
      const lines = text.split(/\r?\n/).map((l) => l.trim()).filter(Boolean);
      if (lines.length === 0) {
        setCsvError("The selected CSV file is empty.");
        setParsedCsvSources([]);
        return;
      }

      const results: { name: string; url: string; type: string }[] = [];
      let startIndex = 0;

      const firstLineLower = lines[0].toLowerCase();
      if (
        firstLineLower.includes("url") ||
        firstLineLower.includes("link") ||
        firstLineLower.includes("group") ||
        firstLineLower.includes("name")
      ) {
        startIndex = 1;
      }

      for (let i = startIndex; i < lines.length; i++) {
        const line = lines[i];
        const parts = line.split(/[,;\t]/).map((p) => p.trim().replace(/^["']|["']$/g, ""));

        let url = "";
        let name = "Facebook Group";

        if (parts.length >= 2) {
          if (parts[0].startsWith("http") || parts[0].includes("facebook.com")) {
            url = parts[0];
            name = parts[1] || "Facebook Group";
          } else {
            name = parts[0] || "Facebook Group";
            url = parts[1];
          }
        } else if (parts.length === 1 && (parts[0].startsWith("http") || parts[0].includes("facebook.com"))) {
          url = parts[0];
          name = "Facebook Group";
        }

        if (
          url &&
          (url.startsWith("http://") ||
            url.startsWith("https://") ||
            url.startsWith("facebook.com") ||
            url.startsWith("www.facebook.com"))
        ) {
          if (!url.startsWith("http://") && !url.startsWith("https://")) {
            url = "https://" + url;
          }
          results.push({
            name: name || "Facebook Group",
            url: url,
            type: "facebook_group",
          });
        }
      }

      if (results.length === 0) {
        setCsvError("No valid URLs found in the CSV. Please ensure URLs start with http:// or https://facebook.com/groups/...");
        setParsedCsvSources([]);
      } else {
        setParsedCsvSources(results);
      }
    } catch (err: any) {
      setCsvError("Failed to parse CSV file: " + err.message);
    }
  };

  const handleCsvFileSelect = (file: File) => {
    if (!file.name.endsWith(".csv") && !file.type.includes("csv") && !file.type.includes("text")) {
      setCsvError("Please upload a valid .csv file.");
      return;
    }
    setCsvFile(file);
    const reader = new FileReader();
    reader.onload = (e) => {
      const text = e.target?.result as string;
      parseCsvContent(text);
    };
    reader.readAsText(file);
  };

  const handleBatchCsvImport = async () => {
    if (parsedCsvSources.length === 0) return;
    setImportingCsv(true);
    setCsvError(null);
    setCsvSuccess(null);

    try {
      const res = await fetch(`${API_URL}/scraper/sources/batch`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ sources: parsedCsvSources }),
      });

      if (res.ok) {
        const data = await res.json();
        setCsvSuccess(`Successfully imported ${data.added || parsedCsvSources.length} scraper group sources!`);
        setParsedCsvSources([]);
        setCsvFile(null);
        if (fileInputRef.current) fileInputRef.current.value = "";
        fetchSources();
      } else {
        let successCount = 0;
        for (const s of parsedCsvSources) {
          try {
            await fetch(`${API_URL}/scraper/sources`, {
              method: "POST",
              headers: { "Content-Type": "application/json" },
              body: JSON.stringify(s),
            });
            successCount++;
          } catch {}
        }
        setCsvSuccess(`Imported ${successCount} sources successfully into scraper.`);
        setParsedCsvSources([]);
        setCsvFile(null);
        if (fileInputRef.current) fileInputRef.current.value = "";
        fetchSources();
      }
    } catch (err: any) {
      setCsvError("Error importing sources: " + err.message);
    } finally {
      setImportingCsv(false);
    }
  };

  const downloadSampleCsv = () => {
    const sample = "Group Name,URL\nAustin Musician Gigs,https://facebook.com/groups/austinlivemusic\nNashville Gigs Network,https://facebook.com/groups/nashvillegigs\nLA Venues & Bands,https://facebook.com/groups/lamusicevents\n";
    const blob = new Blob([sample], { type: "text/csv;charset=utf-8;" });
    const url = URL.createObjectURL(blob);
    const link = document.createElement("a");
    link.setAttribute("href", url);
    link.setAttribute("download", "onlygigz_scraper_groups_template.csv");
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  const handleSaveCookies = async () => {
    if (!cookiesJson.trim()) {
      setCookiesMessage({ type: "error", text: "Please enter JSON cookies content" });
      return;
    }

    setSavingCookies(true);
    setCookiesMessage(null);

    try {
      JSON.parse(cookiesJson);

      const res = await fetch(`${API_URL}/scraper/cookies`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ cookies: cookiesJson }),
      });

      if (res.ok) {
        setCookiesMessage({ type: "success", text: "Facebook cookies updated successfully on server!" });
        setCookiesJson("");
      } else {
        const data = await res.json();
        setCookiesMessage({ type: "error", text: data.detail || "Failed to update cookies" });
      }
    } catch (err: any) {
      setCookiesMessage({ type: "error", text: `Invalid JSON format: ${err.message}` });
    } finally {
      setSavingCookies(false);
    }
  };

  return (
    <div className="p-6 sm:p-8 space-y-8">
      {/* Tab Header Banner */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between pb-6 border-b border-[#2A2A2A] gap-4">
        <div>
          <div className="flex items-center gap-2 mb-1">
            <h2 className="text-[18px] sm:text-[22px] font-bold text-white">System Configuration</h2>
            <span className="px-2.5 py-0.5 rounded-full text-[11px] font-bold bg-[#A2F301]/10 text-[#A2F301] border border-[#A2F301]/30">
              Super Admin Only
            </span>
          </div>
          <p className="text-[#999999] text-[13px] sm:text-[14px]">
            Manage infrastructure keys, external API integrations, and scraper targets.
          </p>
        </div>
      </div>

      {/* 1. Twilio SendGrid API Key Section */}
      <div className="bg-[#141414] border border-[#2A2A2A] rounded-[10px] p-6 space-y-6">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="p-3 bg-[#A2F301]/10 rounded-lg text-[#A2F301] border border-[#A2F301]/20">
              <Mail className="w-5 h-5" />
            </div>
            <div>
              <h3 className="text-[16px] font-bold text-white">Twilio SendGrid Email API</h3>
              <p className="text-[#888888] text-[13px]">
                Secures transactional notifications, user approval/rejection emails, and system dispatch alerts.
              </p>
            </div>
          </div>
          {sendgridStatus && (
            <span
              className={`px-3 py-1 text-xs font-semibold rounded-full border ${
                sendgridStatus.configured
                  ? "bg-emerald-500/10 text-emerald-400 border-emerald-500/20"
                  : "bg-amber-500/10 text-amber-400 border-amber-500/20"
              }`}
            >
              {sendgridStatus.configured ? `Configured (${sendgridStatus.masked_key})` : "Not Configured"}
            </span>
          )}
        </div>

        {sendgridMessage && (
          <div
            className={`p-4 rounded-[8px] flex items-center gap-3 ${
              sendgridMessage.type === "success"
                ? "bg-emerald-500/10 text-emerald-400 border border-emerald-500/20"
                : "bg-red-500/10 text-red-400 border border-red-500/20"
            }`}
          >
            {sendgridMessage.type === "success" ? <CheckCircle className="w-5 h-5" /> : <AlertCircle className="w-5 h-5" />}
            <span className="text-sm font-medium">{sendgridMessage.text}</span>
          </div>
        )}

        <form onSubmit={handleSaveSendgrid} className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-medium text-[#999999] mb-1.5">Twilio SendGrid API Key</label>
              <input
                type="password"
                placeholder="SG.xxxxxxxx..."
                value={sendgridKey}
                onChange={(e) => setSendgridKey(e.target.value)}
                className="w-full bg-[#1A1A1A] border border-[#2A2A2A] rounded-[8px] px-4 py-2.5 text-white placeholder:text-[#555555] focus:outline-none focus:border-[#A2F301] font-mono text-sm"
              />
            </div>
            <div>
              <label className="block text-xs font-medium text-[#999999] mb-1.5">Sender Email Address</label>
              <input
                type="email"
                placeholder="notifications@onlygigz.app"
                value={senderEmail}
                onChange={(e) => setSenderEmail(e.target.value)}
                className="w-full bg-[#1A1A1A] border border-[#2A2A2A] rounded-[8px] px-4 py-2.5 text-white placeholder:text-[#555555] focus:outline-none focus:border-[#A2F301] font-mono text-sm"
              />
            </div>
          </div>
          <div className="flex justify-end">
            <button
              type="submit"
              disabled={savingSendgrid}
              className="flex items-center gap-2 bg-[#A2F301] hover:bg-[#8ed601] text-black px-6 py-2.5 rounded-[8px] font-bold text-sm transition-all shadow-[0_4px_14px_rgba(162,243,1,0.25)] disabled:opacity-50"
            >
              <Save className="w-4 h-4" />
              {savingSendgrid ? "Saving to Firebase..." : "Save SendGrid Configuration"}
            </button>
          </div>
        </form>
      </div>

      {/* 2. Facebook Group Sources Section */}
      <div className="bg-[#141414] border border-[#2A2A2A] rounded-[10px] p-6 space-y-6">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="p-3 bg-indigo-500/10 rounded-lg text-indigo-400 border border-indigo-500/20">
              <Globe className="w-5 h-5" />
            </div>
            <div>
              <h3 className="text-[16px] font-bold text-white">Facebook Scraper Target Groups</h3>
              <p className="text-[#888888] text-[13px]">
                Target Facebook group URLs crawled by background workers for gig opportunities.
              </p>
            </div>
          </div>
          <button
            onClick={fetchSources}
            className="p-2 hover:bg-[#2A2A2A] rounded-lg text-[#888888] hover:text-white transition-colors"
            title="Refresh sources"
          >
            <RefreshCw className={`w-4 h-4 ${loadingSources ? "animate-spin text-[#A2F301]" : ""}`} />
          </button>
        </div>

        {/* Mode Selector Tabs */}
        <div className="flex items-center justify-between border-b border-[#2A2A2A] pb-3">
          <div className="flex gap-2">
            <button
              type="button"
              onClick={() => setSourceMode("manual")}
              className={`px-3 py-1.5 rounded-lg text-xs font-semibold transition-all ${
                sourceMode === "manual"
                  ? "bg-indigo-600 text-white shadow"
                  : "bg-[#1A1A1A] text-[#888888] hover:text-white"
              }`}
            >
              Single Group URL
            </button>
            <button
              type="button"
              onClick={() => setSourceMode("csv")}
              className={`px-3 py-1.5 rounded-lg text-xs font-semibold flex items-center gap-1.5 transition-all ${
                sourceMode === "csv"
                  ? "bg-indigo-600 text-white shadow"
                  : "bg-[#1A1A1A] text-[#888888] hover:text-white"
              }`}
            >
              <Upload className="w-3.5 h-3.5" />
              Upload CSV File
            </button>
          </div>

          {sourceMode === "csv" && (
            <button
              type="button"
              onClick={downloadSampleCsv}
              className="text-xs text-indigo-400 hover:text-indigo-300 flex items-center gap-1 font-medium transition-colors"
            >
              <Download className="w-3.5 h-3.5" />
              Download Sample CSV
            </button>
          )}
        </div>

        {/* Feedback Banners for CSV */}
        {csvError && (
          <div className="p-3.5 rounded-lg flex items-center justify-between gap-3 bg-red-500/10 text-red-400 border border-red-500/20 text-xs font-medium">
            <div className="flex items-center gap-2">
              <AlertCircle className="w-4 h-4 shrink-0" />
              <span>{csvError}</span>
            </div>
            <button onClick={() => setCsvError(null)} className="text-zinc-500 hover:text-white">
              <X className="w-4 h-4" />
            </button>
          </div>
        )}

        {csvSuccess && (
          <div className="p-3.5 rounded-lg flex items-center justify-between gap-3 bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 text-xs font-medium">
            <div className="flex items-center gap-2">
              <CheckCircle className="w-4 h-4 shrink-0" />
              <span>{csvSuccess}</span>
            </div>
            <button onClick={() => setCsvSuccess(null)} className="text-zinc-500 hover:text-white">
              <X className="w-4 h-4" />
            </button>
          </div>
        )}

        {/* Mode 1: Manual Single Input Form */}
        {sourceMode === "manual" ? (
          <form onSubmit={handleAddSource} className="grid grid-cols-1 md:grid-cols-3 gap-3">
            <input
              type="text"
              placeholder="Group Name (e.g. Austin Musician Gigs)"
              value={newName}
              onChange={(e) => setNewName(e.target.value)}
              className="bg-[#1A1A1A] border border-[#2A2A2A] rounded-lg px-4 py-2.5 text-white placeholder:text-[#555555] focus:outline-none focus:border-indigo-500 text-sm"
            />
            <input
              type="url"
              placeholder="https://facebook.com/groups/..."
              value={newUrl}
              onChange={(e) => setNewUrl(e.target.value)}
              required
              className="bg-[#1A1A1A] border border-[#2A2A2A] rounded-lg px-4 py-2.5 text-white placeholder:text-[#555555] focus:outline-none focus:border-indigo-500 text-sm"
            />
            <button
              type="submit"
              disabled={addingSource}
              className="flex items-center justify-center gap-2 bg-indigo-600 hover:bg-indigo-500 text-white px-5 py-2.5 rounded-lg font-bold transition-colors disabled:opacity-50 text-sm"
            >
              <Plus className="w-4 h-4" />
              {addingSource ? "Adding..." : "Add Group URL"}
            </button>
          </form>
        ) : (
          /* Mode 2: CSV Bulk Upload UI */
          <div className="space-y-4">
            <div
              onClick={() => fileInputRef.current?.click()}
              onDragOver={(e) => e.preventDefault()}
              onDrop={(e) => {
                e.preventDefault();
                if (e.dataTransfer.files && e.dataTransfer.files[0]) {
                  handleCsvFileSelect(e.dataTransfer.files[0]);
                }
              }}
              className="border-2 border-dashed border-[#2A2A2A] hover:border-indigo-500/50 bg-[#1A1A1A]/60 rounded-xl p-6 text-center cursor-pointer transition-all group"
            >
              <input
                ref={fileInputRef}
                type="file"
                accept=".csv,text/csv,text/plain"
                className="hidden"
                onChange={(e) => {
                  if (e.target.files && e.target.files[0]) {
                    handleCsvFileSelect(e.target.files[0]);
                  }
                }}
              />
              <div className="w-12 h-12 rounded-full bg-indigo-500/10 text-indigo-400 flex items-center justify-center mx-auto mb-3 group-hover:scale-110 transition-transform">
                <Upload className="w-6 h-6" />
              </div>
              <p className="text-sm font-semibold text-white">
                {csvFile ? csvFile.name : "Click to select or drag and drop your CSV file here"}
              </p>
              <p className="text-xs text-[#888888] mt-1">
                CSV format: Column headers (Name, URL) or a simple list of Facebook group links
              </p>
            </div>

            {/* Parsed CSV Preview */}
            {parsedCsvSources.length > 0 && (
              <div className="bg-[#1A1A1A] border border-[#2A2A2A] rounded-lg p-4 space-y-3">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <FileText className="w-4 h-4 text-indigo-400" />
                    <span className="text-sm font-semibold text-white">
                      Found {parsedCsvSources.length} Group Sources Ready to Import
                    </span>
                  </div>
                  <button
                    type="button"
                    onClick={() => {
                      setParsedCsvSources([]);
                      setCsvFile(null);
                      if (fileInputRef.current) fileInputRef.current.value = "";
                    }}
                    className="text-xs text-[#888888] hover:text-red-400"
                  >
                    Clear File
                  </button>
                </div>

                <div className="max-h-40 overflow-y-auto divide-y divide-[#2A2A2A] text-xs">
                  {parsedCsvSources.slice(0, 10).map((src, i) => (
                    <div key={i} className="py-1.5 flex items-center justify-between text-zinc-300">
                      <span className="font-medium text-white truncate max-w-xs">{src.name}</span>
                      <span className="text-[#888888] truncate max-w-md">{src.url}</span>
                    </div>
                  ))}
                  {parsedCsvSources.length > 10 && (
                    <div className="py-1.5 text-[#888888] text-center italic">
                      + {parsedCsvSources.length - 10} more rows
                    </div>
                  )}
                </div>

                <div className="pt-2 flex justify-end">
                  <button
                    type="button"
                    disabled={importingCsv}
                    onClick={handleBatchCsvImport}
                    className="flex items-center gap-2 bg-indigo-600 hover:bg-indigo-500 text-white px-5 py-2 rounded-lg text-sm font-semibold transition-colors disabled:opacity-50"
                  >
                    <Check className="w-4 h-4" />
                    {importingCsv
                      ? "Importing Groups to Firebase..."
                      : `Import All ${parsedCsvSources.length} Groups`}
                  </button>
                </div>
              </div>
            )}
          </div>
        )}

        {/* Sources List */}
        <div className="divide-y divide-[#2A2A2A] border border-[#2A2A2A] rounded-lg bg-[#141414] max-h-72 overflow-y-auto">
          {loadingSources ? (
            <div className="p-8 text-center text-[#888888] text-sm">Loading scraper sources...</div>
          ) : sources.length === 0 ? (
            <div className="p-8 text-center text-[#888888] text-sm">No scraper sources configured yet.</div>
          ) : (
            sources.map((source) => (
              <div key={source.id} className="p-3.5 flex items-center justify-between hover:bg-[#1A1A1A] transition-colors">
                <div>
                  <div className="font-bold text-white text-[13px]">{source.name}</div>
                  <a
                    href={source.url}
                    target="_blank"
                    rel="noreferrer"
                    className="text-xs text-indigo-400 hover:underline truncate max-w-md block"
                  >
                    {source.url}
                  </a>
                </div>
                <button
                  onClick={() => handleDeleteSource(source.id)}
                  className="p-1.5 text-[#888888] hover:text-red-400 hover:bg-red-500/10 rounded-lg transition-colors"
                  title="Delete source"
                >
                  <Trash2 className="w-4 h-4" />
                </button>
              </div>
            ))
          )}
        </div>
      </div>

      {/* 3. Facebook Cookies Manager */}
      <div className="bg-[#141414] border border-[#2A2A2A] rounded-[10px] p-6 space-y-6">
        <div className="flex items-center gap-3">
          <div className="p-3 bg-amber-500/10 rounded-lg text-amber-400 border border-amber-500/20">
            <Key className="w-5 h-5" />
          </div>
          <div>
            <h3 className="text-[16px] font-bold text-white">Facebook Session Cookies</h3>
            <p className="text-[#888888] text-[13px]">Paste exported JSON session cookies to maintain background scraper authentication.</p>
          </div>
        </div>

        {cookiesMessage && (
          <div
            className={`p-4 rounded-[8px] flex items-center gap-3 ${
              cookiesMessage.type === "success" ? "bg-emerald-500/10 text-emerald-400 border border-emerald-500/20" : "bg-red-500/10 text-red-400 border border-red-500/20"
            }`}
          >
            {cookiesMessage.type === "success" ? <CheckCircle className="w-5 h-5" /> : <AlertCircle className="w-5 h-5" />}
            <span className="text-sm font-medium">{cookiesMessage.text}</span>
          </div>
        )}

        <div className="space-y-4">
          <textarea
            rows={6}
            placeholder='Paste JSON cookies here (e.g. [{"name": "c_user", "value": "..."}, ...])'
            value={cookiesJson}
            onChange={(e) => setCookiesJson(e.target.value)}
            className="w-full bg-[#1A1A1A] border border-[#2A2A2A] rounded-lg p-4 font-mono text-xs text-zinc-300 placeholder:text-[#555555] focus:outline-none focus:border-amber-500"
          />

          <div className="flex justify-end">
            <button
              onClick={handleSaveCookies}
              disabled={savingCookies}
              className="flex items-center gap-2 bg-amber-600 hover:bg-amber-500 text-white px-6 py-2.5 rounded-[8px] font-bold text-sm transition-colors disabled:opacity-50"
            >
              <Save className="w-4 h-4" />
              {savingCookies ? "Updating Server..." : "Update Facebook Cookies"}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
