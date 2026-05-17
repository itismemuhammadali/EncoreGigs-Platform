"use client";

import React, { useState, useEffect, useRef } from "react";
import { 
  User, 
  Shield, 
  CreditCard, 
  Bot, 
  Bell, 
  Lock,
  Save,
  ChevronDown,
  Check,
  Camera,
  Loader2
} from "lucide-react";
import { Toast } from "@/components/ui/Toast";
import { useMediaQuery } from "@/hooks/useMediaQuery";
import { apiRequest } from "@/lib/api";

// --- Types ---
type SettingsTab = "profile" | "access" | "payment" | "scraper" | "notifications" | "security";

interface SecurityLog {
  id: string;
  action: string;
  email: string;
  date: string;
  status: "success" | "failed" | string;
}

export default function SettingsPage() {
  const [activeTab, setActiveTab] = useState<SettingsTab>("profile");
  const [toast, setToast] = useState({ show: false, message: "", type: "success" as "success" | "error" });
  const [isLoading, setIsLoading] = useState(false);
  const [isUploading, setIsUploading] = useState(false);
  const [isLogsLoading, setIsLogsLoading] = useState(false);
  const [securityLogs, setSecurityLogs] = useState<SecurityLog[]>([]);
  const isMobile = useMediaQuery("(max-width: 640px)");
  const fileInputRef = useRef<HTMLInputElement>(null);

  // Form States
  const [profile, setProfile] = useState({
    uid: "",
    firstName: "",
    lastName: "",
    email: "",
    role: "Admin",
    profileImageUrl: ""
  });

  const [payment, setPayment] = useState({
    provider: "Stripe",
    apiKey: "sk_live_xxxxxxxxxxxxxxxxxxxx",
    webhookSecret: "whsec_xxxxxxxxxxxxxxxxxxxx",
    holdPeriod: "24",
    fee: "12"
  });

  const [scraperSources, setScraperSources] = useState<Record<string, boolean>>({
    Eventbrite: true,
    Bandsintown: true,
    GigSalad: true,
    "The Bash": true,
    Thumbtack: true
  });

  const [emailPrefs, setEmailPrefs] = useState<Record<string, boolean>>({
    "New user registrations": true,
    "Dispute opened": true,
    "Payment issues": true,
    "Scraper failures": true,
    "Security alerts": true
  });

  const [systemPrefs, setSystemPrefs] = useState<Record<string, boolean>>({
    "Dashboard alerts": true,
    "Critical errors": true,
    "Weekly reports": true,
    "Monthly summaries": true
  });

  // Fetch initial data
  useEffect(() => {
    const userStr = localStorage.getItem("admin_user");
    if (userStr) {
      try {
        const userData = JSON.parse(userStr);
        if (userData.localId) {
          fetchProfile(userData.localId);
        }
      } catch (e) {
        console.error("Failed to parse admin_user", e);
      }
    }
  }, []);

  const fetchProfile = async (uid: string) => {
    setIsLoading(true);
    try {
      const data = await apiRequest(`/auth/profile/${uid}`);
      setProfile({
        uid: data.uid || uid,
        firstName: data.firstName || "",
        lastName: data.lastName || "",
        email: data.email || "",
        role: data.role || "Admin",
        profileImageUrl: data.profileImageUrl || ""
      });
    } catch (err: any) {
      setToast({ show: true, message: "Failed to load profile: " + err.message, type: "error" });
    } finally {
      setIsLoading(false);
    }
  };

  const fetchSecurityLogs = async () => {
    setIsLogsLoading(true);
    try {
      const data = await apiRequest("/security/logs?limit=50");
      setSecurityLogs(data);
    } catch (err: any) {
      setToast({ show: true, message: "Failed to load security logs: " + err.message, type: "error" });
    } finally {
      setIsLogsLoading(false);
    }
  };

  useEffect(() => {
    if (activeTab === "security") {
      fetchSecurityLogs();
    }
  }, [activeTab]);

  // --- Handlers ---
  const handleSaveProfile = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    try {
      await apiRequest("/auth/profile/update", {
        method: "POST",
        body: JSON.stringify({
          uid: profile.uid,
          firstName: profile.firstName,
          lastName: profile.lastName,
          email: profile.email,
          profileImageUrl: profile.profileImageUrl
        })
      });

      // Update local storage if name changed
      const userStr = localStorage.getItem("admin_user");
      if (userStr) {
        const userData = JSON.parse(userStr);
        userData.displayName = `${profile.firstName} ${profile.lastName}`.trim();
        userData.profileImageUrl = profile.profileImageUrl;
        localStorage.setItem("admin_user", JSON.stringify(userData));
        
        // Notify other components (Header, ProfileDropdown)
        window.dispatchEvent(new Event("admin_user_updated"));
      }

      setToast({ show: true, message: "Profile settings saved successfully.", type: "success" });
    } catch (err: any) {
      setToast({ show: true, message: "Failed to save profile: " + err.message, type: "error" });
    } finally {
      setIsLoading(false);
    }
  };

  const handleImageUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file || !profile.uid) return;

    setIsUploading(true);
    const formData = new FormData();
    formData.append("file", file);
    
    try {
      const host = window.location.hostname;
      const baseUrl = `http://${host}:8000`;
      const response = await fetch(`${baseUrl}/auth/upload?uid=${profile.uid}&file_type=profile_photo`, {
        method: "POST",
        body: formData,
      });

      if (!response.ok) throw new Error("Upload failed");
      
      const data = await response.json();
      setProfile(prev => ({ ...prev, profileImageUrl: data.url }));

      // Update local storage so header reflects change immediately
      const userStr = localStorage.getItem("admin_user");
      if (userStr) {
        const userData = JSON.parse(userStr);
        userData.profileImageUrl = data.url;
        localStorage.setItem("admin_user", JSON.stringify(userData));
        window.dispatchEvent(new Event("admin_user_updated"));
      }

      setToast({ show: true, message: "Profile picture uploaded successfully.", type: "success" });
    } catch (err: any) {
      setToast({ show: true, message: "Upload failed: " + err.message, type: "error" });
    } finally {
      setIsUploading(false);
    }
  };

  const handleSavePayment = (e: React.FormEvent) => {
    e.preventDefault();
    setToast({ show: true, message: "Payment gateway configuration updated.", type: "success" });
  };

  // --- Sidebar Items ---
  const sidebarItems = [
    { id: "profile", label: "Admin Profile", icon: User },
    { id: "access", label: "Access Control", icon: Shield },
    { id: "payment", label: "Payment Gateway", icon: CreditCard },
    { id: "scraper", label: "Scraper Settings", icon: Bot },
    { id: "notifications", label: "Notifications", icon: Bell },
    { id: "security", label: "Security Logs", icon: Lock },
  ];

  return (
    <div className="w-full text-white font-inter pb-20">
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-2xl sm:text-[32px] font-bold mb-2 leading-tight">Settings</h1>
        <p className="text-[#999999] text-sm sm:text-[16px]">Manage system settings and configurations</p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 lg:gap-8 items-start">
        {/* Settings Navigation Sidebar */}
        <div className="col-span-1 lg:col-span-4 bg-[#1A1A1A] border border-[#2A2A2A] rounded-[8px] p-2 sm:p-4 flex flex-row lg:flex-col gap-2 overflow-x-auto lg:overflow-visible custom-scrollbar whitespace-nowrap lg:whitespace-normal">
          {sidebarItems.map((item) => {
            const isActive = activeTab === item.id;
            return (
              <button
                key={item.id}
                onClick={() => setActiveTab(item.id as SettingsTab)}
                className={`flex items-center gap-3.5 px-4 sm:px-5 py-3 sm:py-4 rounded-[8px] transition-all duration-200 border shrink-0 ${
                  isActive
                    ? "bg-[#A2F301] border-[#A2F301] text-black font-bold shadow-[0_0_15px_-5px_rgba(162,243,1,0.3)]"
                    : "bg-transparent border-transparent text-[#999999] hover:bg-white/5 hover:text-white"
                }`}
              >
                <item.icon size={isMobile ? 18 : 20} strokeWidth={isActive ? 2.5 : 2} />
                <span className="text-[13px] sm:text-[14px] font-medium">{item.label}</span>
              </button>
            );
          })}
        </div>

        {/* Settings Content Area */}
        <div className="col-span-1 lg:col-span-8 bg-[#1A1A1A] border border-[#2A2A2A] rounded-[8px] overflow-hidden min-h-[400px] sm:min-h-[500px] shadow-2xl">
          
          {/* Admin Profile Tab */}
          {activeTab === "profile" && (
            <div className="p-6 sm:p-8">
              <div className="flex justify-between items-center mb-10">
                <h2 className="text-[18px] sm:text-[20px] font-bold">Admin Profile Settings</h2>
                {isLoading && <Loader2 className="w-5 h-5 text-[#A2F301] animate-spin" />}
              </div>

              {/* Profile Photo Section (Floating Effect) */}
              <div className="flex flex-col items-center mb-12 relative">
                <div className="relative group">
                  <div className="w-[120px] h-[120px] rounded-full overflow-hidden border-4 border-[#2A2A2A] bg-[#2A2A2A] shadow-2xl transition-transform duration-300 group-hover:scale-105">
                    {profile.profileImageUrl ? (
                      <img 
                        src={profile.profileImageUrl} 
                        alt="Profile" 
                        className="w-full h-full object-cover"
                      />
                    ) : (
                      <div className="w-full h-full flex items-center justify-center text-4xl font-bold text-white/20">
                        {profile.firstName.charAt(0) || "A"}
                      </div>
                    )}
                    {isUploading && (
                      <div className="absolute inset-0 bg-black/60 flex items-center justify-center">
                        <Loader2 className="w-8 h-8 text-[#A2F301] animate-spin" />
                      </div>
                    )}
                  </div>
                  
                  {/* Floating Edit Button */}
                  <button 
                    onClick={() => fileInputRef.current?.click()}
                    disabled={isUploading}
                    className="absolute bottom-1 right-1 w-9 h-9 bg-[#A2F301] rounded-full flex items-center justify-center text-black shadow-lg hover:scale-110 active:scale-95 transition-all border-4 border-[#1A1A1A] disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    <Camera size={18} strokeWidth={2.5} />
                  </button>
                </div>
                <input 
                  type="file"
                  ref={fileInputRef}
                  onChange={handleImageUpload}
                  accept="image/*"
                  className="hidden"
                />
                <p className="mt-4 text-[#666666] text-xs font-medium uppercase tracking-widest">Profile Picture</p>
              </div>

              <form onSubmit={handleSaveProfile} className="space-y-6">
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-6">
                  <div>
                    <label className="block text-[#999999] text-[13px] sm:text-[14px] mb-2 font-medium">First Name</label>
                    <input 
                      type="text"
                      required
                      value={profile.firstName}
                      onChange={(e) => setProfile({...profile, firstName: e.target.value})}
                      className="w-full h-[48px] bg-[#1A1A1A] border border-[#2A2A2A] rounded-[8px] px-4 text-white focus:border-[#A2F301] outline-none transition-all"
                      placeholder="John"
                    />
                  </div>
                  <div>
                    <label className="block text-[#999999] text-[13px] sm:text-[14px] mb-2 font-medium">Last Name</label>
                    <input 
                      type="text"
                      required
                      value={profile.lastName}
                      onChange={(e) => setProfile({...profile, lastName: e.target.value})}
                      className="w-full h-[48px] bg-[#1A1A1A] border border-[#2A2A2A] rounded-[8px] px-4 text-white focus:border-[#A2F301] outline-none transition-all"
                      placeholder="Doe"
                    />
                  </div>
                </div>

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-6">
                  <div>
                    <label className="block text-[#999999] text-[13px] sm:text-[14px] mb-2 font-medium">Email Address</label>
                    <input 
                      type="email"
                      required
                      value={profile.email}
                      onChange={(e) => setProfile({...profile, email: e.target.value})}
                      className="w-full h-[48px] bg-[#1A1A1A] border border-[#2A2A2A] rounded-[8px] px-4 text-white focus:border-[#A2F301] outline-none transition-all"
                    />
                  </div>
                  <div>
                    <label className="block text-[#999999] text-[13px] sm:text-[14px] mb-2 font-medium">Role</label>
                    <div className="w-full h-[48px] bg-white/[0.03] border border-[#2A2A2A] rounded-[8px] px-4 flex items-center text-[#666666] cursor-not-allowed text-[14px] font-medium capitalize">
                      {profile.role}
                    </div>
                  </div>
                </div>

                <div className="pt-6">
                  <button 
                    type="submit"
                    disabled={isLoading}
                    className="h-[54px] px-10 bg-[#A2F301] text-black font-bold rounded-[8px] flex items-center justify-center gap-2 hover:bg-[#8ed601] active:scale-[0.98] transition-all w-full sm:w-auto shadow-[0_8px_20px_-6px_rgba(162,243,1,0.4)] disabled:opacity-70 disabled:cursor-not-allowed"
                  >
                    {isLoading ? (
                      <Loader2 size={20} className="animate-spin" />
                    ) : (
                      <Save size={20} />
                    )}
                    Save Profile Changes
                  </button>
                </div>
              </form>
            </div>
          )}

          {/* Access Control Tab */}
          {activeTab === "access" && (
            <div className="p-6 sm:p-8">
              <h2 className="text-[18px] sm:text-[20px] font-bold mb-8">Role-Based Access Control</h2>
              <div className="space-y-4">
                {/* Super Admin */}
                <div className="bg-[#1A1A1A] border border-[#2A2A2A] rounded-[8px] p-5 sm:p-6 shadow-lg hover:border-[#A2F301]/20 transition-all">
                  <div className="flex flex-col sm:flex-row justify-between items-start gap-3 mb-2">
                    <h3 className="text-white font-bold text-[16px]">Super Admin</h3>
                    <span className="px-2.5 py-1 bg-[#10B981]/10 text-[#10B981] rounded-full text-[10px] sm:text-[11px] font-bold uppercase tracking-wider">
                      ALL PERMISSIONS
                    </span>
                  </div>
                  <p className="text-[#999999] text-[13px] sm:text-[14px]">Full system access and control</p>
                </div>

                {/* Admin */}
                <div className="bg-[#1A1A1A] border border-[#2A2A2A] rounded-[8px] p-5 sm:p-6 shadow-lg hover:border-[#A2F301]/20 transition-all">
                  <div className="flex flex-col sm:flex-row justify-between items-start gap-4 mb-3">
                    <h3 className="text-white font-bold text-[16px]">Admin</h3>
                    <div className="flex flex-wrap gap-2">
                      <span className="px-2.5 py-1 bg-[#A2F301]/10 text-[#A2F301] rounded-full text-[10px] sm:text-[11px] font-bold uppercase tracking-wider">USER MGMT</span>
                      <span className="px-2.5 py-1 bg-[#A2F301]/10 text-[#A2F301] rounded-full text-[10px] sm:text-[11px] font-bold uppercase tracking-wider">GIG MGMT</span>
                      <span className="px-2.5 py-1 bg-[#A2F301]/10 text-[#A2F301] rounded-full text-[10px] sm:text-[11px] font-bold uppercase tracking-wider">REVIEWS</span>
                    </div>
                  </div>
                  <p className="text-[#999999] text-[13px] sm:text-[14px]">Limited administrative access</p>
                </div>

                {/* Support */}
                <div className="bg-[#1A1A1A] border border-[#2A2A2A] rounded-[8px] p-5 sm:p-6 shadow-lg hover:border-[#A2F301]/20 transition-all">
                  <div className="flex flex-col sm:flex-row justify-between items-start gap-4 mb-3">
                    <h3 className="text-white font-bold text-[16px]">Support</h3>
                    <div className="flex flex-wrap gap-2">
                      <span className="px-2.5 py-1 bg-blue-500/10 text-blue-500 rounded-full text-[10px] sm:text-[11px] font-bold uppercase tracking-wider">VIEW USERS</span>
                      <span className="px-2.5 py-1 bg-blue-500/10 text-blue-500 rounded-full text-[10px] sm:text-[11px] font-bold uppercase tracking-wider">VIEW GIGS</span>
                      <span className="px-2.5 py-1 bg-blue-500/10 text-blue-500 rounded-full text-[10px] sm:text-[11px] font-bold uppercase tracking-wider">DISPUTES</span>
                    </div>
                  </div>
                  <p className="text-[#999999] text-[13px] sm:text-[14px]">Customer support access only</p>
                </div>
              </div>
            </div>
          )}

          {/* Payment Gateway Tab */}
          {activeTab === "payment" && (
            <div className="p-6 sm:p-8">
              <h2 className="text-[18px] sm:text-[20px] font-bold mb-8">Payment Gateway Configuration</h2>
              <form onSubmit={handleSavePayment} className="space-y-6">
                <div>
                  <label className="block text-[#999999] text-[13px] sm:text-[14px] mb-2 font-medium">Payment Provider</label>
                  <div className="relative">
                    <select 
                      value={payment.provider}
                      onChange={(e) => setPayment({...payment, provider: e.target.value})}
                      className="w-full h-[48px] bg-[#1A1A1A] border border-[#2A2A2A] rounded-[8px] px-4 text-white appearance-none focus:border-[#A2F301] outline-none text-[14px]"
                    >
                      <option>Stripe</option>
                      <option>PayPal</option>
                      <option>Crypto (Escrow)</option>
                    </select>
                    <ChevronDown size={18} className="absolute right-4 top-1/2 -translate-y-1/2 text-[#999999] pointer-events-none" />
                  </div>
                </div>
                <div>
                  <label className="block text-[#999999] text-[13px] sm:text-[14px] mb-2 font-medium">API Key</label>
                  <input 
                    type="password"
                    value={payment.apiKey}
                    onChange={(e) => setPayment({...payment, apiKey: e.target.value})}
                    className="w-full h-[48px] bg-[#1A1A1A] border border-[#2A2A2A] rounded-[8px] px-4 text-white focus:border-[#A2F301] outline-none transition-all text-[14px]"
                    placeholder="sk_live_..."
                  />
                </div>
                <div>
                  <label className="block text-[#999999] text-[13px] sm:text-[14px] mb-2 font-medium">Webhook Secret</label>
                  <input 
                    type="password"
                    value={payment.webhookSecret}
                    onChange={(e) => setPayment({...payment, webhookSecret: e.target.value})}
                    className="w-full h-[48px] bg-[#1A1A1A] border border-[#2A2A2A] rounded-[8px] px-4 text-white focus:border-[#A2F301] outline-none transition-all text-[14px]"
                    placeholder="whsec_..."
                  />
                </div>
                
                <h3 className="text-[16px] font-bold pt-4 pb-2">Escrow Settings</h3>
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-6">
                  <div>
                    <label className="block text-[#999999] text-[13px] sm:text-[14px] mb-2 font-medium">Hold Period (hours)</label>
                    <input 
                      type="number"
                      value={payment.holdPeriod}
                      onChange={(e) => setPayment({...payment, holdPeriod: e.target.value})}
                      className="w-full h-[48px] bg-[#1A1A1A] border border-[#2A2A2A] rounded-[8px] px-4 text-white focus:border-[#A2F301] outline-none text-[14px]"
                    />
                  </div>
                  <div>
                    <label className="block text-[#999999] text-[13px] sm:text-[14px] mb-2 font-medium">Platform Fee (%)</label>
                    <input 
                      type="number"
                      value={payment.fee}
                      onChange={(e) => setPayment({...payment, fee: e.target.value})}
                      className="w-full h-[48px] bg-[#1A1A1A] border border-[#2A2A2A] rounded-[8px] px-4 text-white focus:border-[#A2F301] outline-none text-[14px]"
                    />
                  </div>
                </div>

                <div className="pt-4">
                  <button 
                    type="submit"
                    className="h-[48px] px-8 bg-[#A2F301] text-black font-bold rounded-[8px] flex items-center justify-center gap-2 hover:bg-[#8ed601] transition-all w-full sm:w-auto"
                  >
                    <Save size={18} />
                    Save Configuration
                  </button>
                </div>
              </form>
            </div>
          )}

          {/* Security Logs Tab */}
          {activeTab === "security" && (
            <div className="p-6 sm:p-8">
              <div className="flex justify-between items-center mb-8">
                <h2 className="text-[18px] sm:text-[20px] font-bold">Security Activity Logs</h2>
                <button 
                  onClick={fetchSecurityLogs}
                  disabled={isLogsLoading}
                  className="text-[#A2F301] text-sm hover:underline flex items-center gap-2"
                >
                  {isLogsLoading && <Loader2 size={14} className="animate-spin" />}
                  Refresh
                </button>
              </div>

              <div className="space-y-4">
                {isLogsLoading && securityLogs.length === 0 ? (
                  <div className="flex flex-col items-center justify-center py-20 bg-[#1A1A1A] border border-[#2A2A2A] border-dashed rounded-[8px]">
                    <Loader2 className="w-8 h-8 text-[#A2F301] animate-spin mb-4" />
                    <p className="text-[#999999]">Fetching security logs...</p>
                  </div>
                ) : securityLogs.length === 0 ? (
                  <div className="flex flex-col items-center justify-center py-20 bg-[#1A1A1A] border border-[#2A2A2A] border-dashed rounded-[8px]">
                    <Lock className="w-8 h-8 text-[#52525b] mb-4" />
                    <p className="text-[#999999]">No security logs found.</p>
                  </div>
                ) : (
                  securityLogs.map((log) => (
                    <div key={log.id} className="bg-[#1A1A1A] border border-[#2A2A2A] rounded-[8px] p-5 sm:p-6 flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 group hover:border-white/10 transition-all shadow-lg">
                      <div>
                        <h3 className="text-white font-bold text-[15px] sm:text-[16px] mb-1">{log.action}</h3>
                        <div className="flex flex-col sm:flex-row sm:items-center gap-2 text-[#999999] text-[12px] sm:text-[13px]">
                          <span>{log.email}</span>
                          <span className="hidden sm:inline w-1 h-1 rounded-full bg-[#333333]" />
                          <span>{log.date}</span>
                        </div>
                      </div>
                      <span className={`px-2.5 py-1 rounded-[4px] text-[10px] sm:text-[11px] font-bold uppercase tracking-wider ${
                        log.status === "success" 
                          ? "bg-[#10B981]/10 text-[#10B981]" 
                          : "bg-[#EF4444]/10 text-[#EF4444]"
                      }`}>
                        {log.status}
                      </span>
                    </div>
                  ))
                )}
              </div>
            </div>
          )}

          {/* Notifications Tab */}
          {activeTab === "notifications" && (
            <div className="p-6 sm:p-8">
              <h2 className="text-[18px] sm:text-[20px] font-bold mb-8">Notification Preferences</h2>
              
              <div className="space-y-8">
                {/* Email Notifications Section */}
                <div>
                  <h3 className="text-[#999999] text-[12px] sm:text-[14px] font-medium mb-4 uppercase tracking-wider">Email Notifications</h3>
                  <div className="space-y-3">
                    {Object.keys(emailPrefs).map((pref) => (
                      <div 
                        key={pref} 
                        onClick={() => setEmailPrefs(prev => ({ ...prev, [pref]: !prev[pref] }))}
                        className="flex items-center gap-3 px-4 sm:px-5 py-4 bg-[#1A1A1A] border border-[#2A2A2A] rounded-[8px] group hover:border-white/10 cursor-pointer transition-all shadow-md"
                      >
                        <div className={`w-5 h-5 rounded-full flex items-center justify-center transition-all shrink-0 ${
                          emailPrefs[pref] ? "bg-[#A2F301]" : "border-2 border-[#333333] bg-transparent"
                        }`}>
                          {emailPrefs[pref] && (
                            <Check size={12} strokeWidth={3} className="text-black" />
                          )}
                        </div>
                        <span className={`text-[13px] sm:text-[14px] font-medium transition-colors ${
                          emailPrefs[pref] ? "text-white" : "text-[#666666]"
                        }`}>
                          {pref}
                        </span>
                      </div>
                    ))}
                  </div>
                </div>

                {/* System Notifications Section */}
                <div>
                  <h3 className="text-[#999999] text-[12px] sm:text-[14px] font-medium mb-4 uppercase tracking-wider">System Notifications</h3>
                  <div className="space-y-3">
                    {Object.keys(systemPrefs).map((pref) => (
                      <div 
                        key={pref} 
                        onClick={() => setSystemPrefs(prev => ({ ...prev, [pref]: !prev[pref] }))}
                        className="flex items-center gap-3 px-4 sm:px-5 py-4 bg-[#1A1A1A] border border-[#2A2A2A] rounded-[8px] group hover:border-white/10 cursor-pointer transition-all shadow-md"
                      >
                        <div className={`w-5 h-5 rounded-full flex items-center justify-center transition-all shrink-0 ${
                          systemPrefs[pref] ? "bg-[#A2F301]" : "border-2 border-[#333333] bg-transparent"
                        }`}>
                          {systemPrefs[pref] && (
                            <Check size={12} strokeWidth={3} className="text-black" />
                          )}
                        </div>
                        <span className={`text-[13px] sm:text-[14px] font-medium transition-colors ${
                          systemPrefs[pref] ? "text-white" : "text-[#666666]"
                        }`}>
                          {pref}
                        </span>
                      </div>
                    ))}
                  </div>
                </div>

                <div className="pt-4">
                  <button 
                    onClick={() => setToast({ show: true, message: "Notification preferences saved.", type: "success" })}
                    className="h-[48px] px-8 bg-[#A2F301] text-black font-bold rounded-[8px] flex items-center justify-center gap-2 hover:bg-[#8ed601] transition-all w-full sm:w-auto"
                  >
                    <Save size={18} />
                    Save Preferences
                  </button>
                </div>
              </div>
            </div>
          )}

          {/* Scraper Settings Tab */}
          {activeTab === "scraper" && (
            <div className="p-6 sm:p-8">
              <h2 className="text-[18px] sm:text-[20px] font-bold mb-8">Scraper Schedule & Configuration</h2>
              
              <div className="space-y-6">
                <div>
                  <label className="block text-[#999999] text-[13px] sm:text-[14px] mb-2 font-medium">Schedule Frequency</label>
                  <div className="relative">
                    <select className="w-full h-[48px] bg-[#1A1A1A] border border-[#2A2A2A] rounded-[8px] px-4 text-white appearance-none focus:border-[#A2F301] outline-none text-[14px]">
                      <option>Daily</option>
                      <option>Twice Daily</option>
                      <option>Weekly</option>
                      <option>Manual Only</option>
                    </select>
                    <ChevronDown size={18} className="absolute right-4 top-1/2 -translate-y-1/2 text-[#999999] pointer-events-none" />
                  </div>
                </div>

                <div className="bg-[#1A1A1A] border border-[#2A2A2A] rounded-[8px] p-5 sm:p-6 shadow-lg">
                  <h3 className="text-white font-bold text-[14px] mb-4">Active Sources</h3>
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    {Object.keys(scraperSources).map((source) => (
                      <div 
                        key={source} 
                        onClick={() => setScraperSources(prev => ({ ...prev, [source]: !prev[source] }))}
                        className="flex items-center gap-3 group cursor-pointer"
                      >
                        <div className={`w-5 h-5 rounded-full flex items-center justify-center transition-all shrink-0 ${
                          scraperSources[source] ? "bg-[#A2F301]" : "border-2 border-[#333333] bg-transparent"
                        }`}>
                          {scraperSources[source] && (
                            <Check size={12} strokeWidth={3} className="text-black" />
                          )}
                        </div>
                        <span className={`text-[13px] sm:text-[14px] font-medium transition-colors ${
                          scraperSources[source] ? "text-white" : "text-[#666666]"
                        }`}>
                          {source}
                        </span>
                      </div>
                    ))}
                  </div>
                </div>

                <div>
                  <label className="block text-[#999999] text-[13px] sm:text-[14px] mb-2 font-medium">Duplicate Detection Threshold</label>
                  <input 
                    type="number"
                    defaultValue={85}
                    className="w-full h-[48px] bg-[#1A1A1A] border border-[#2A2A2A] rounded-[8px] px-4 text-white focus:border-[#A2F301] outline-none text-[14px]"
                  />
                  <p className="text-[#666666] text-[11px] sm:text-[12px] mt-2 italic">Similarity percentage to flag as duplicate</p>
                </div>

                <div className="pt-4">
                  <button 
                    onClick={() => setToast({ show: true, message: "Scraper configurations updated.", type: "success" })}
                    className="h-[48px] px-8 bg-[#A2F301] text-black font-bold rounded-[8px] flex items-center justify-center gap-2 hover:bg-[#8ed601] transition-all w-full sm:w-auto"
                  >
                    <Save size={18} />
                    Save Settings
                  </button>
                </div>
              </div>
            </div>
          )}
        </div>
      </div>

      <Toast 
        show={toast.show}
        message={toast.message}
        onClose={() => setToast({ ...toast, show: false })}
      />
    </div>
  );
}
