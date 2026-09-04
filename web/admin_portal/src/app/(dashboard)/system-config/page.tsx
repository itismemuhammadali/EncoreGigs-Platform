"use client";

import { useState, useEffect } from "react";
import { Plus, Trash2, Key, Globe, RefreshCw, CheckCircle, AlertCircle, Save, Mail } from "lucide-react";

export default function SystemConfigPage() {
  const [sources, setSources] = useState<any[]>([]);
  const [loadingSources, setLoadingSources] = useState(true);
  const [newUrl, setNewUrl] = useState("");
  const [newName, setNewName] = useState("");
  const [addingSource, setAddingSource] = useState(false);

  const [cookiesJson, setCookiesJson] = useState("");
  const [savingCookies, setSavingCookies] = useState(false);
  const [cookiesMessage, setCookiesMessage] = useState<{ type: "success" | "error"; text: string } | null>(null);

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
    <div className="p-8 max-w-6xl mx-auto space-y-8">
      <div>
        <h1 className="text-3xl font-bold text-white tracking-tight">System Management & Services Config</h1>
        <p className="text-zinc-400 mt-1">Manage SendGrid API Keys, Facebook scraper groups, and session cookie authentication.</p>
      </div>

      {/* Twilio SendGrid API Key Section */}
      <div className="bg-zinc-900 border border-zinc-800 rounded-xl p-6 shadow-xl space-y-6">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="p-3 bg-lime-500/10 rounded-lg text-lime-400">
              <Mail className="w-6 h-6" />
            </div>
            <div>
              <h2 className="text-xl font-semibold text-white">Twilio SendGrid Email API Key</h2>
              <p className="text-sm text-zinc-400">Store your SendGrid API key securely in Firebase to send account approval/denial emails automatically.</p>
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
            className={`p-4 rounded-lg flex items-center gap-3 ${
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
              <label className="block text-xs font-medium text-zinc-400 mb-1.5">Twilio SendGrid API Key</label>
              <input
                type="password"
                placeholder="SG.xxxxxxxx..."
                value={sendgridKey}
                onChange={(e) => setSendgridKey(e.target.value)}
                className="w-full bg-zinc-950 border border-zinc-800 rounded-lg px-4 py-2.5 text-white placeholder:text-zinc-600 focus:outline-none focus:border-lime-500 font-mono text-sm"
              />
            </div>
            <div>
              <label className="block text-xs font-medium text-zinc-400 mb-1.5">Sender Email Address</label>
              <input
                type="email"
                placeholder="notifications@onlygigz.app"
                value={senderEmail}
                onChange={(e) => setSenderEmail(e.target.value)}
                className="w-full bg-zinc-950 border border-zinc-800 rounded-lg px-4 py-2.5 text-white placeholder:text-zinc-600 focus:outline-none focus:border-lime-500 font-mono text-sm"
              />
            </div>
          </div>
          <div className="flex justify-end">
            <button
              type="submit"
              disabled={savingSendgrid}
              className="flex items-center gap-2 bg-lime-500 hover:bg-lime-400 text-black px-6 py-2.5 rounded-lg font-semibold transition-colors disabled:opacity-50"
            >
              <Save className="w-4 h-4" />
              {savingSendgrid ? "Saving to Firebase..." : "Save SendGrid Key"}
            </button>
          </div>
        </form>
      </div>

      {/* Facebook Group Sources Section */}
      <div className="bg-zinc-900 border border-zinc-800 rounded-xl p-6 shadow-xl space-y-6">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="p-3 bg-indigo-500/10 rounded-lg text-indigo-400">
              <Globe className="w-6 h-6" />
            </div>
            <div>
              <h2 className="text-xl font-semibold text-white">Facebook Scraper Groups</h2>
              <p className="text-sm text-zinc-400">Add or remove Facebook group URLs tracked by the automated scraper.</p>
            </div>
          </div>
          <button
            onClick={fetchSources}
            className="p-2 hover:bg-zinc-800 rounded-lg text-zinc-400 hover:text-white transition-colors"
          >
            <RefreshCw className="w-5 h-5" />
          </button>
        </div>

        {/* Add Source Form */}
        <form onSubmit={handleAddSource} className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <input
            type="text"
            placeholder="Group Name (e.g. Austin Musician Gigs)"
            value={newName}
            onChange={(e) => setNewName(e.target.value)}
            className="bg-zinc-950 border border-zinc-800 rounded-lg px-4 py-2.5 text-white placeholder:text-zinc-600 focus:outline-none focus:border-indigo-500"
          />
          <input
            type="url"
            placeholder="https://facebook.com/groups/..."
            value={newUrl}
            onChange={(e) => setNewUrl(e.target.value)}
            required
            className="bg-zinc-950 border border-zinc-800 rounded-lg px-4 py-2.5 text-white placeholder:text-zinc-600 focus:outline-none focus:border-indigo-500"
          />
          <button
            type="submit"
            disabled={addingSource}
            className="flex items-center justify-center gap-2 bg-indigo-600 hover:bg-indigo-500 text-white px-5 py-2.5 rounded-lg font-medium transition-colors disabled:opacity-50"
          >
            <Plus className="w-4 h-4" />
            {addingSource ? "Adding..." : "Add Group URL"}
          </button>
        </form>

        {/* Sources List */}
        <div className="divide-y divide-zinc-800/60 border border-zinc-800 rounded-lg bg-zinc-950/50 max-h-96 overflow-y-auto">
          {loadingSources ? (
            <div className="p-8 text-center text-zinc-500">Loading scraper sources...</div>
          ) : sources.length === 0 ? (
            <div className="p-8 text-center text-zinc-500">No scraper sources configured yet.</div>
          ) : (
            sources.map((source) => (
              <div key={source.id} className="p-4 flex items-center justify-between hover:bg-zinc-900/50 transition-colors">
                <div>
                  <div className="font-medium text-white">{source.name}</div>
                  <a
                    href={source.url}
                    target="_blank"
                    rel="noreferrer"
                    className="text-sm text-indigo-400 hover:underline truncate max-w-md block"
                  >
                    {source.url}
                  </a>
                </div>
                <button
                  onClick={() => handleDeleteSource(source.id)}
                  className="p-2 text-zinc-500 hover:text-red-400 hover:bg-red-500/10 rounded-lg transition-colors"
                >
                  <Trash2 className="w-4 h-4" />
                </button>
              </div>
            ))
          )}
        </div>
      </div>

      {/* Facebook Cookies Manager */}
      <div className="bg-zinc-900 border border-zinc-800 rounded-xl p-6 shadow-xl space-y-6">
        <div className="flex items-center gap-3">
          <div className="p-3 bg-amber-500/10 rounded-lg text-amber-400">
            <Key className="w-6 h-6" />
          </div>
          <div>
            <h2 className="text-xl font-semibold text-white">Facebook Session Cookies</h2>
            <p className="text-sm text-zinc-400">Paste exported JSON cookies to update the scraper authentication session remotely.</p>
          </div>
        </div>

        {cookiesMessage && (
          <div
            className={`p-4 rounded-lg flex items-center gap-3 ${
              cookiesMessage.type === "success" ? "bg-emerald-500/10 text-emerald-400 border border-emerald-500/20" : "bg-red-500/10 text-red-400 border border-red-500/20"
            }`}
          >
            {cookiesMessage.type === "success" ? <CheckCircle className="w-5 h-5" /> : <AlertCircle className="w-5 h-5" />}
            <span className="text-sm font-medium">{cookiesMessage.text}</span>
          </div>
        )}

        <div className="space-y-4">
          <textarea
            rows={8}
            placeholder='Paste JSON cookies here (e.g. [{"name": "c_user", "value": "..."}, ...])'
            value={cookiesJson}
            onChange={(e) => setCookiesJson(e.target.value)}
            className="w-full bg-zinc-950 border border-zinc-800 rounded-lg p-4 font-mono text-xs text-zinc-300 placeholder:text-zinc-600 focus:outline-none focus:border-amber-500"
          />

          <div className="flex justify-end">
            <button
              onClick={handleSaveCookies}
              disabled={savingCookies}
              className="flex items-center gap-2 bg-amber-600 hover:bg-amber-500 text-white px-6 py-2.5 rounded-lg font-medium transition-colors disabled:opacity-50"
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
