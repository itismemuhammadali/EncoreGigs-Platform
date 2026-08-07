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
  Loader2,
  Smartphone,
  Mail,
  Plus,
  Trash2,
  X,
  UserPlus
} from "lucide-react";
import { Toast } from "@/components/ui/Toast";
import { useMediaQuery } from "@/hooks/useMediaQuery";
import { apiRequest } from "@/lib/api";

// --- Types ---
type SettingsTab = "profile" | "access" | "payment" | "scraper" | "notifications" | "security" | "security_2fa";

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
  const [twoFA, setTwoFA] = useState({
    is2FAEnabled: false,
    method: "email" as "email" | "sms",
    phoneNumber: ""
  });

  // Team Member Management State
  const [teamMembers, setTeamMembers] = useState<Array<{
    uid: string;
    name: string;
    firstName: string;
    lastName: string;
    email: string;
    role: string;
    is2FAEnabled: boolean;
    joinedAt: string;
  }>>([]);
  const [isTeamLoading, setIsTeamLoading] = useState(false);
  const [isAddMemberModalOpen, setIsAddMemberModalOpen] = useState(false);
  const [newMember, setNewMember] = useState({
    firstName: "",
    lastName: "",
    email: "",
    password: "",
    role: "admin" as "super_admin" | "admin" | "support"
  });
  const [isSubmittingMember, setIsSubmittingMember] = useState(false);

  // Fetch initial data
  useEffect(() => {
    const userStr = localStorage.getItem("admin_user");
    if (userStr) {
      try {
        const userData = JSON.parse(userStr);
        const uid = userData.localId || userData.uid;

        // Immediately sync 2FA state from stored user data
        if (userData.is2FAEnabled !== undefined || userData.is_2fa_enabled !== undefined) {
          const isEnabled = userData.is2FAEnabled === true || userData.is_2fa_enabled === true;
          const rawMethod = userData.twoFactorMethod || userData.two_factor_method || "email";
          const normMethod = (rawMethod === "email_link" || rawMethod === "email") ? "email" : "sms";
          setTwoFA({
            is2FAEnabled: isEnabled,
            method: normMethod as "email" | "sms",
            phoneNumber: userData.phoneNumber || userData.phone_number || ""
          });
        }

        if (uid) {
          fetchProfile(uid);
        }
      } catch (e) {
        console.error("Failed to parse admin_user", e);
      }
    }
    fetchTeamMembers();
    fetchPaymentConfig();
    fetchScraperConfig();
    fetchNotificationPreferences();
  }, []);

  const fetchNotificationPreferences = async () => {
    try {
      const data = await apiRequest("/admin/notifications/preferences");
      if (data) {
        if (data.emailPrefs) setEmailPrefs(data.emailPrefs);
        if (data.systemPrefs) setSystemPrefs(data.systemPrefs);
      }
    } catch (err) {
      console.error("Failed to fetch notification preferences:", err);
    }
  };

  const handleSaveNotificationPreferences = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    try {
      await apiRequest("/admin/notifications/preferences", {
        method: "POST",
        body: JSON.stringify({
          emailPrefs,
          systemPrefs
        })
      });
      setToast({ show: true, message: "Notification preferences saved successfully to database!", type: "success" });
    } catch (err: any) {
      setToast({ show: true, message: "Failed to save preferences: " + err.message, type: "error" });
    } finally {
      setIsLoading(false);
    }
  };

  const [scraperConfig, setScraperConfig] = useState({
    scheduleFrequency: "Daily",
    duplicateThreshold: "85"
  });
  const [platformToggles, setPlatformToggles] = useState({
    Facebook: true,
    Craigslist: true,
    GigSalad: true,
    Eventbrite: true
  });
  const [realScraperSources, setRealScraperSources] = useState<Array<{ id: string; name: string; url: string; type: string; enabled: boolean }>>([]);
  const [isScraperLoading, setIsScraperLoading] = useState(false);
  const [newSourceUrl, setNewSourceUrl] = useState("");
  const [newSourceName, setNewSourceName] = useState("");
  const [isAddingSource, setIsAddingSource] = useState(false);

  const fetchScraperConfig = async () => {
    setIsScraperLoading(true);
    try {
      const data = await apiRequest("/scraper/config");
      if (data) {
        setScraperConfig({
          scheduleFrequency: data.scheduleFrequency || "Daily",
          duplicateThreshold: String(data.duplicateThreshold !== undefined ? data.duplicateThreshold : 85)
        });
        if (data.activePlatforms) {
          setPlatformToggles(data.activePlatforms);
        }
      }
      const sourcesData = await apiRequest("/scraper/sources");
      if (Array.isArray(sourcesData)) {
        setRealScraperSources(sourcesData);
      }
    } catch (err) {
      console.error("Failed to fetch scraper config:", err);
    } finally {
      setIsScraperLoading(false);
    }
  };

  const handleSaveScraper = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    try {
      await apiRequest("/scraper/config", {
        method: "POST",
        body: JSON.stringify({
          scheduleFrequency: scraperConfig.scheduleFrequency,
          duplicateThreshold: Number(scraperConfig.duplicateThreshold),
          activePlatforms: platformToggles
        })
      });
      setToast({ show: true, message: "Scraper configuration updated successfully!", type: "success" });
    } catch (err: any) {
      setToast({ show: true, message: "Failed to save scraper config: " + err.message, type: "error" });
    } finally {
      setIsLoading(false);
    }
  };

  const handleAddSource = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newSourceUrl) return;
    setIsAddingSource(true);
    try {
      await apiRequest("/scraper/sources", {
        method: "POST",
        body: JSON.stringify({
          url: newSourceUrl,
          name: newSourceName || "Facebook Group",
          type: "facebook_group"
        })
      });
      setToast({ show: true, message: "Scraper target source added successfully!", type: "success" });
      setNewSourceUrl("");
      setNewSourceName("");
      fetchScraperConfig();
    } catch (err: any) {
      setToast({ show: true, message: "Failed to add source: " + err.message, type: "error" });
    } finally {
      setIsAddingSource(false);
    }
  };

  const handleDeleteSource = async (sourceId: string, sourceName: string) => {
    if (!window.confirm(`Are you sure you want to remove target source '${sourceName}'?`)) return;
    try {
      await apiRequest(`/scraper/sources/${sourceId}`, {
        method: "DELETE"
      });
      setToast({ show: true, message: "Source removed successfully.", type: "success" });
      fetchScraperConfig();
    } catch (err: any) {
      setToast({ show: true, message: "Failed to delete source: " + err.message, type: "error" });
    }
  };

  const fetchPaymentConfig = async () => {
    try {
      const data = await apiRequest("/payments/config");
      if (data) {
        setPayment({
          provider: "Stripe",
          apiKey: "",
          webhookSecret: "",
          holdPeriod: String(data.holdPeriod !== undefined ? data.holdPeriod : 24),
          fee: String(data.platformFee !== undefined ? data.platformFee : 12)
        });
      }
    } catch (err) {
      console.error("Failed to fetch payment config:", err);
    }
  };

  const fetchTeamMembers = async () => {
    setIsTeamLoading(true);
    try {
      const data = await apiRequest("/auth/admin/members");
      if (Array.isArray(data)) {
        setTeamMembers(data);
      }
    } catch (err: any) {
      console.error("Failed to fetch team members:", err);
    } finally {
      setIsTeamLoading(false);
    }
  };

  const handleCreateMember = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newMember.firstName || !newMember.lastName || !newMember.email || !newMember.password) {
      setToast({ show: true, message: "Please fill in all fields", type: "error" });
      return;
    }

    setIsSubmittingMember(true);
    try {
      await apiRequest("/auth/admin/create-member", {
        method: "POST",
        body: JSON.stringify(newMember),
      });

      setToast({ show: true, message: `Team member ${newMember.firstName} created successfully as ${newMember.role.replace('_', ' ').toUpperCase()}!`, type: "success" });
      setIsAddMemberModalOpen(false);
      setNewMember({
        firstName: "",
        lastName: "",
        email: "",
        password: "",
        role: "admin"
      });
      fetchTeamMembers();
    } catch (err: any) {
      setToast({ show: true, message: "Failed to create team member: " + err.message, type: "error" });
    } finally {
      setIsSubmittingMember(false);
    }
  };

  const handleDeleteMember = async (memberUid: string, memberName: string) => {
    if (!window.confirm(`Are you sure you want to remove ${memberName} from the admin team?`)) {
      return;
    }

    try {
      await apiRequest(`/auth/admin/members/${memberUid}`, {
        method: "DELETE"
      });
      setToast({ show: true, message: `${memberName} has been removed.`, type: "success" });
      fetchTeamMembers();
    } catch (err: any) {
      setToast({ show: true, message: "Failed to delete team member: " + err.message, type: "error" });
    }
  };

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

      const isEnabled = data.is2FAEnabled === true || data.is_2fa_enabled === true;
      const rawMethod = data.twoFactorMethod || data.two_factor_method || "email";
      const normMethod = (rawMethod === "email_link" || rawMethod === "email") ? "email" : "sms";

      setTwoFA({
        is2FAEnabled: isEnabled,
        method: normMethod as "email" | "sms",
        phoneNumber: data.phoneNumber || data.phone_number || ""
      });

      const computedName = `${data.firstName || ''} ${data.lastName || ''}`.trim() || data.name || data.displayName || data.email;
      const userStr = localStorage.getItem("admin_user");
      const currentLocal = userStr ? JSON.parse(userStr) : {};
      const updatedUser = {
        ...currentLocal,
        ...data,
        displayName: computedName,
      };
      localStorage.setItem("admin_user", JSON.stringify(updatedUser));
      window.dispatchEvent(new Event("admin_user_updated"));
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

  const handleSavePayment = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    try {
      await apiRequest("/payments/config", {
        method: "POST",
        body: JSON.stringify({
          holdPeriod: Number(payment.holdPeriod),
          platformFee: Number(payment.fee)
        })
      });
      setToast({ show: true, message: "Payment & Escrow configuration saved successfully!", type: "success" });
    } catch (err: any) {
      setToast({ show: true, message: "Failed to save payment config: " + err.message, type: "error" });
    } finally {
      setIsLoading(false);
    }
  };

  const handleSave2FA = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    try {
      const userStr = localStorage.getItem("admin_user");
      if (!userStr) {
        setToast({ show: true, message: "User not found", type: "error" });
        setIsLoading(false);
        return;
      }
      const userData = JSON.parse(userStr);
      const uid = userData.localId;
      const email = userData.email;

      // Make API request to save 2FA settings
      await apiRequest("/auth/2fa/enable", {
        method: "POST",
        body: JSON.stringify({
          uid: uid,
          enabled: twoFA.is2FAEnabled,
          userType: "admin"
        })
      });

      if (twoFA.is2FAEnabled && twoFA.method === "sms") {
        if (!twoFA.phoneNumber) {
          setToast({ show: true, message: "Please enter a phone number for SMS 2FA", type: "error" });
          setIsLoading(false);
          return;
        }
        // Save phone number
        await apiRequest("/auth/2fa/save-phone", {
          method: "POST",
          body: JSON.stringify({
            uid: uid,
            phoneNumber: twoFA.phoneNumber,
            userType: "admin"
          })
        });
      }

      // Save method
      if (twoFA.is2FAEnabled) {
        await apiRequest("/auth/2fa/set-method", {
          method: "POST",
          body: JSON.stringify({
            uid: uid,
            method: twoFA.method,
            userType: "admin"
          })
        });

        // If email method, send verification link
        if (twoFA.method === "email") {
          await apiRequest("/auth/send-email-link-2fa", {
            method: "POST",
            body: JSON.stringify({
              uid: uid,
              email: email,
              userType: "admin"
            })
          });
          setToast({ show: true, message: "Email verification link sent! Check your email. Click the link to verify.", type: "success" });
        } else {
          setToast({ show: true, message: "Two-Factor Authentication settings saved successfully.", type: "success" });
        }
      } else {
        setToast({ show: true, message: "Two-Factor Authentication disabled.", type: "success" });
      }

      // Update local storage so UI state persists immediately
      const updatedUserData = {
        ...userData,
        is2FAEnabled: twoFA.is2FAEnabled,
        twoFactorMethod: twoFA.method,
      };
      localStorage.setItem("admin_user", JSON.stringify(updatedUserData));
    } catch (err: any) {
      setToast({ show: true, message: "Failed to save 2FA settings: " + err.message, type: "error" });
    } finally {
      setIsLoading(false);
    }
  };

  // --- Sidebar Items ---
  const sidebarItems = [
    { id: "profile", label: "Admin Profile", icon: User },
    { id: "access", label: "Access Control", icon: Shield },
    { id: "payment", label: "Payment Gateway", icon: CreditCard },
    { id: "scraper", label: "Scraper Settings", icon: Bot },
    { id: "notifications", label: "Notifications", icon: Bell },
    { id: "security_2fa", label: "Security & 2FA", icon: Smartphone },
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
            <div className="p-6 sm:p-8 space-y-8">
              <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-4 border-b border-[#2A2A2A]">
                <div>
                  <h2 className="text-[18px] sm:text-[20px] font-bold text-white mb-1">Role-Based Access Control</h2>
                  <p className="text-[#999999] text-[13px] sm:text-[14px]">Manage administrative permission tiers and invite team members</p>
                </div>
                <button
                  type="button"
                  onClick={() => setIsAddMemberModalOpen(true)}
                  className="h-[44px] px-5 bg-[#A2F301] text-black font-bold rounded-[8px] flex items-center justify-center gap-2 hover:bg-[#8ed601] transition-all shadow-[0_4px_14px_rgba(162,243,1,0.25)] flex-shrink-0"
                >
                  <UserPlus size={18} />
                  <span>Add Team Member</span>
                </button>
              </div>

              {/* Role Definition Cards */}
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

              {/* Admin Team Members Table */}
              <div className="pt-6 border-t border-[#2A2A2A]">
                <div className="flex items-center justify-between mb-4">
                  <h3 className="text-[16px] font-bold text-white">Active Team Members ({teamMembers.length})</h3>
                  {isTeamLoading && <Loader2 size={18} className="animate-spin text-[#A2F301]" />}
                </div>

                {teamMembers.length === 0 ? (
                  <div className="p-8 text-center bg-[#1A1A1A] border border-[#2A2A2A] rounded-[12px]">
                    <User size={32} className="mx-auto text-[#666666] mb-2" />
                    <p className="text-[#999999] text-[14px]">No team members registered yet.</p>
                  </div>
                ) : (
                  <div className="overflow-x-auto bg-[#1A1A1A] border border-[#2A2A2A] rounded-[12px]">
                    <table className="w-full text-left text-[14px]">
                      <thead className="bg-[#0F0F0F] text-[#999999] border-b border-[#2A2A2A]">
                        <tr>
                          <th className="px-6 py-4 font-semibold">User</th>
                          <th className="px-6 py-4 font-semibold">Role</th>
                          <th className="px-6 py-4 font-semibold">2FA Status</th>
                          <th className="px-6 py-4 font-semibold">Joined</th>
                          <th className="px-6 py-4 font-semibold text-right">Actions</th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-[#2A2A2A] text-white">
                        {teamMembers.map((member) => (
                          <tr key={member.uid} className="hover:bg-white/[0.02] transition-colors">
                            <td className="px-6 py-4">
                              <div>
                                <p className="font-bold text-white">{member.name || `${member.firstName} ${member.lastName}`}</p>
                                <p className="text-[12px] text-[#999999]">{member.email}</p>
                              </div>
                            </td>
                            <td className="px-6 py-4">
                              <span className={`px-2.5 py-1 rounded-full text-[11px] font-bold uppercase tracking-wider ${
                                member.role === "super_admin" 
                                  ? "bg-[#10B981]/10 text-[#10B981]" 
                                  : member.role === "admin" 
                                  ? "bg-[#A2F301]/10 text-[#A2F301]" 
                                  : "bg-blue-500/10 text-blue-400"
                              }`}>
                                {member.role.replace("_", " ")}
                              </span>
                            </td>
                            <td className="px-6 py-4">
                              <span className={`text-[12px] font-medium ${member.is2FAEnabled ? "text-[#10B981]" : "text-[#999999]"}`}>
                                {member.is2FAEnabled ? "✓ Enabled" : "Disabled"}
                              </span>
                            </td>
                            <td className="px-6 py-4 text-[#999999] text-[13px]">
                              {member.joinedAt || "Recent"}
                            </td>
                            <td className="px-6 py-4 text-right">
                              <button
                                type="button"
                                onClick={() => handleDeleteMember(member.uid, member.name || member.email)}
                                className="p-2 text-red-400 hover:text-red-300 hover:bg-red-500/10 rounded-[6px] transition-colors"
                                title="Remove team member"
                              >
                                <Trash2 size={16} />
                              </button>
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                )}
              </div>

              {/* Add Team Member Modal */}
              {isAddMemberModalOpen && (
                <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-sm animate-fadeIn">
                  <div className="w-full max-w-[500px] bg-[#141414] border border-[#2A2A2A] rounded-[16px] p-6 sm:p-8 shadow-2xl space-y-6">
                    <div className="flex items-center justify-between pb-4 border-b border-[#2A2A2A]">
                      <div className="flex items-center gap-3">
                        <div className="w-10 h-10 rounded-full bg-[#A2F301]/10 flex items-center justify-center text-[#A2F301]">
                          <UserPlus size={20} />
                        </div>
                        <div>
                          <h3 className="text-[18px] font-bold text-white">Add Team Member</h3>
                          <p className="text-[#999999] text-[12px]">Create a new portal administrative account</p>
                        </div>
                      </div>
                      <button 
                        onClick={() => setIsAddMemberModalOpen(false)}
                        className="p-2 text-[#999999] hover:text-white hover:bg-white/10 rounded-full transition-all"
                      >
                        <X size={18} />
                      </button>
                    </div>

                    <form onSubmit={handleCreateMember} className="space-y-4">
                      <div className="grid grid-cols-2 gap-4">
                        <div>
                          <label className="block text-[#999999] text-[12px] font-medium mb-1.5">First Name</label>
                          <input 
                            type="text"
                            required
                            value={newMember.firstName}
                            onChange={(e) => setNewMember({...newMember, firstName: e.target.value})}
                            placeholder="John"
                            className="w-full h-[44px] bg-[#1A1A1A] border border-[#2A2A2A] rounded-[8px] px-3.5 text-white text-[14px] focus:border-[#A2F301] outline-none"
                          />
                        </div>
                        <div>
                          <label className="block text-[#999999] text-[12px] font-medium mb-1.5">Last Name</label>
                          <input 
                            type="text"
                            required
                            value={newMember.lastName}
                            onChange={(e) => setNewMember({...newMember, lastName: e.target.value})}
                            placeholder="Doe"
                            className="w-full h-[44px] bg-[#1A1A1A] border border-[#2A2A2A] rounded-[8px] px-3.5 text-white text-[14px] focus:border-[#A2F301] outline-none"
                          />
                        </div>
                      </div>

                      <div>
                        <label className="block text-[#999999] text-[12px] font-medium mb-1.5">Email Address</label>
                        <input 
                          type="email"
                          required
                          value={newMember.email}
                          onChange={(e) => setNewMember({...newMember, email: e.target.value})}
                          placeholder="admin@example.com"
                          className="w-full h-[44px] bg-[#1A1A1A] border border-[#2A2A2A] rounded-[8px] px-3.5 text-white text-[14px] focus:border-[#A2F301] outline-none"
                        />
                      </div>

                      <div>
                        <label className="block text-[#999999] text-[12px] font-medium mb-1.5">Temporary Password</label>
                        <input 
                          type="password"
                          required
                          value={newMember.password}
                          onChange={(e) => setNewMember({...newMember, password: e.target.value})}
                          placeholder="••••••••"
                          className="w-full h-[44px] bg-[#1A1A1A] border border-[#2A2A2A] rounded-[8px] px-3.5 text-white text-[14px] focus:border-[#A2F301] outline-none"
                        />
                      </div>

                      <div>
                        <label className="block text-[#999999] text-[12px] font-medium mb-1.5">Assign Role</label>
                        <div className="relative">
                          <select 
                            value={newMember.role}
                            onChange={(e) => setNewMember({...newMember, role: e.target.value as any})}
                            className="w-full h-[44px] bg-[#1A1A1A] border border-[#2A2A2A] rounded-[8px] px-3.5 text-white text-[14px] focus:border-[#A2F301] outline-none appearance-none cursor-pointer"
                          >
                            <option value="super_admin">Super Admin (All Permissions)</option>
                            <option value="admin">Admin (User & Gig Management)</option>
                            <option value="support">Support (View-only & Disputes)</option>
                          </select>
                          <ChevronDown size={16} className="absolute right-3.5 top-1/2 -translate-y-1/2 text-[#999999] pointer-events-none" />
                        </div>
                      </div>

                      <div className="pt-4 flex items-center justify-end gap-3 border-t border-[#2A2A2A]">
                        <button
                          type="button"
                          onClick={() => setIsAddMemberModalOpen(false)}
                          className="h-[44px] px-5 bg-[#1A1A1A] border border-[#2A2A2A] text-[#999999] hover:text-white font-semibold rounded-[8px] transition-all text-[14px]"
                        >
                          Cancel
                        </button>
                        <button
                          type="submit"
                          disabled={isSubmittingMember}
                          className="h-[44px] px-6 bg-[#A2F301] text-black font-bold rounded-[8px] hover:bg-[#8ed601] transition-all flex items-center gap-2 text-[14px] disabled:opacity-70"
                        >
                          {isSubmittingMember ? <Loader2 size={16} className="animate-spin" /> : <UserPlus size={16} />}
                          <span>Create Account</span>
                        </button>
                      </div>
                    </form>
                  </div>
                </div>
              )}
            </div>
          )}

          {/* Payment Gateway Tab */}
          {activeTab === "payment" && (
            <div className="p-6 sm:p-8 space-y-6">
              <div>
                <h2 className="text-[18px] sm:text-[20px] font-bold text-white mb-1">Payment Gateway Configuration</h2>
                <p className="text-[#999999] text-[13px] sm:text-[14px]">Configure active payment processing & platform revenue fee settings</p>
              </div>

              <form onSubmit={handleSavePayment} className="space-y-6">
                {/* Active Gateway Badge Display */}
                <div>
                  <label className="block text-[#999999] text-[13px] sm:text-[14px] mb-2 font-medium">Payment Provider</label>
                  <div className="bg-[#1A1A1A] border border-[#2A2A2A] rounded-[12px] p-5 sm:p-6 flex items-center justify-between shadow-lg">
                    <div className="flex items-center gap-4">
                      <div className="w-12 h-12 rounded-[10px] bg-[#635BFF]/10 border border-[#635BFF]/30 flex items-center justify-center text-[#635BFF]">
                        <CreditCard size={24} />
                      </div>
                      <div>
                        <div className="flex items-center gap-3 mb-1">
                          <h3 className="text-white font-bold text-[16px]">Stripe Payment Engine</h3>
                          <span className="px-2.5 py-0.5 bg-[#10B981]/10 text-[#10B981] text-[10px] sm:text-[11px] font-bold uppercase rounded-full tracking-wider border border-[#10B981]/20">
                            Active & Integrated
                          </span>
                        </div>
                        <p className="text-[#999999] text-[13px]">
                          Stripe is active for processing organizer deposits, holding escrow funds, and issuing automated musician payouts.
                        </p>
                      </div>
                    </div>
                  </div>
                </div>
                
                <h3 className="text-[16px] font-bold pt-4 pb-2 border-t border-[#2A2A2A]">Escrow & Revenue Fee Settings</h3>
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-6">
                  <div>
                    <label className="block text-[#999999] text-[13px] sm:text-[14px] mb-1.5 font-medium">Auto-Release Hold Period (hours)</label>
                    <input 
                      type="number"
                      min="0"
                      max="720"
                      required
                      value={payment.holdPeriod}
                      onChange={(e) => setPayment({...payment, holdPeriod: e.target.value})}
                      className="w-full h-[48px] bg-[#1A1A1A] border border-[#2A2A2A] rounded-[8px] px-4 text-white focus:border-[#A2F301] outline-none text-[14px]"
                    />
                    <p className="text-[12px] text-[#666666] mt-2">
                      Hours after a gig completes before held escrow funds are automatically released to the musician if not manually released by the organizer.
                    </p>
                  </div>
                  <div>
                    <label className="block text-[#999999] text-[13px] sm:text-[14px] mb-1.5 font-medium">Platform Fee (%)</label>
                    <input 
                      type="number"
                      step="0.1"
                      min="0"
                      max="100"
                      required
                      value={payment.fee}
                      onChange={(e) => setPayment({...payment, fee: e.target.value})}
                      className="w-full h-[48px] bg-[#1A1A1A] border border-[#2A2A2A] rounded-[8px] px-4 text-white focus:border-[#A2F301] outline-none text-[14px]"
                    />
                    <p className="text-[12px] text-[#666666] mt-2">
                      The percentage fee OnlyGigz retains on every completed gig transaction (regulated dynamically between 0% and 100%).
                    </p>
                  </div>
                </div>

                <div className="pt-4">
                  <button 
                    type="submit"
                    disabled={isLoading}
                    className="h-[48px] px-8 bg-[#A2F301] text-black font-bold rounded-[8px] flex items-center justify-center gap-2 hover:bg-[#8ed601] transition-all w-full sm:w-auto shadow-[0_8px_20px_-6px_rgba(162,243,1,0.4)] disabled:opacity-70"
                  >
                    {isLoading ? <Loader2 size={18} className="animate-spin" /> : <Save size={18} />}
                    <span>Save Configuration</span>
                  </button>
                </div>
              </form>
            </div>
          )}

          {/* Security & 2FA Tab */}
          {activeTab === "security_2fa" && (
            <div className="p-6 sm:p-8">
              <h2 className="text-[18px] sm:text-[20px] font-bold mb-8">Two-Factor Authentication</h2>
              <form onSubmit={handleSave2FA} className="space-y-8">
                {/* 2FA Toggle */}
                <div className="bg-[#0F0F0F] border border-[#2A2A2A] rounded-[12px] p-6 sm:p-8">
                  <div className="flex items-center justify-between">
                    <div className="flex-1">
                      <h3 className="text-white font-bold text-[16px] mb-2">Enable Two-Factor Authentication</h3>
                      <p className="text-[#999999] text-[14px]">Add an extra layer of security to your account</p>
                    </div>
                    <button
                      type="button"
                      onClick={() => setTwoFA({...twoFA, is2FAEnabled: !twoFA.is2FAEnabled})}
                      className={`ml-4 w-14 h-8 rounded-full transition-all ${twoFA.is2FAEnabled ? 'bg-[#A2F301]' : 'bg-[#2A2A2A]'}`}
                    >
                      <div className={`w-7 h-7 rounded-full bg-white transition-transform ${twoFA.is2FAEnabled ? 'translate-x-7' : 'translate-x-0.5'}`}/>
                    </button>
                  </div>
                </div>

                {twoFA.is2FAEnabled && (
                  <>
                    <div className="bg-[#0F0F0F] border border-[#2A2A2A] rounded-[12px] p-6 sm:p-8">
                      <h3 className="text-white font-bold text-[16px] mb-6">Select Verification Method</h3>
                      <div className="space-y-4">
                        <button
                          type="button"
                          onClick={() => setTwoFA({...twoFA, method: "email"})}
                          className={`w-full p-5 rounded-[12px] border-2 transition-all flex items-start gap-4 ${twoFA.method === "email" ? 'border-[#A2F301] bg-[#A2F301]/5' : 'border-[#2A2A2A] bg-[#1A1A1A] hover:border-[#A2F301]/30'}`}
                        >
                          <div className={`w-6 h-6 rounded-full border-2 flex items-center justify-center flex-shrink-0 mt-0.5 ${twoFA.method === "email" ? 'border-[#A2F301] bg-[#A2F301]' : 'border-[#999999]'}`}>
                            {twoFA.method === "email" && <Check size={16} className="text-black" strokeWidth={3} />}
                          </div>
                          <div className="text-left">
                            <div className="flex items-center gap-2 mb-1">
                              <Mail size={18} className="text-[#A2F301]" />
                              <span className="font-bold text-white">Email Verification Link</span>
                            </div>
                            <p className="text-[#999999] text-[13px]">Receive a secure sign-in link via email</p>
                          </div>
                        </button>

                        <button
                          type="button"
                          onClick={() => setTwoFA({...twoFA, method: "sms"})}
                          className={`w-full p-5 rounded-[12px] border-2 transition-all flex items-start gap-4 ${twoFA.method === "sms" ? 'border-[#A2F301] bg-[#A2F301]/5' : 'border-[#2A2A2A] bg-[#1A1A1A] hover:border-[#A2F301]/30'}`}
                        >
                          <div className={`w-6 h-6 rounded-full border-2 flex items-center justify-center flex-shrink-0 mt-0.5 ${twoFA.method === "sms" ? 'border-[#A2F301] bg-[#A2F301]' : 'border-[#999999]'}`}>
                            {twoFA.method === "sms" && <Check size={16} className="text-black" strokeWidth={3} />}
                          </div>
                          <div className="text-left">
                            <div className="flex items-center gap-2 mb-1">
                              <Smartphone size={18} className="text-[#A2F301]" />
                              <span className="font-bold text-white">SMS OTP Code</span>
                            </div>
                            <p className="text-[#999999] text-[13px]">Receive a 6-digit code via SMS</p>
                          </div>
                        </button>
                      </div>
                    </div>

                    {twoFA.method === "sms" && (
                      <div className="bg-[#0F0F0F] border border-[#2A2A2A] rounded-[12px] p-6 sm:p-8">
                        <label className="block text-white font-bold text-[15px] mb-4">Phone Number</label>
                        <input
                          type="tel"
                          value={twoFA.phoneNumber}
                          onChange={(e) => setTwoFA({...twoFA, phoneNumber: e.target.value})}
                          placeholder="+1 (555) 123-4567"
                          className="w-full h-[48px] bg-[#1A1A1A] border border-[#2A2A2A] rounded-[8px] px-4 text-white focus:border-[#A2F301] outline-none transition-all"
                        />
                        <p className="text-[#999999] text-[13px] mt-3">Enter your phone number to receive SMS OTP codes</p>
                      </div>
                    )}
                  </>
                )}

                <div className="pt-6 border-t border-[#2A2A2A]">
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
                    Save 2FA Settings
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
              
              <form onSubmit={handleSaveNotificationPreferences} className="space-y-8">
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
                    type="submit"
                    disabled={isLoading}
                    className="h-[48px] px-8 bg-[#A2F301] text-black font-bold rounded-[8px] flex items-center justify-center gap-2 hover:bg-[#8ed601] transition-all w-full sm:w-auto shadow-[0_8px_20px_-6px_rgba(162,243,1,0.4)] disabled:opacity-70"
                  >
                    {isLoading ? <Loader2 size={18} className="animate-spin" /> : <Save size={18} />}
                    <span>Save Preferences</span>
                  </button>
                </div>
              </form>
            </div>
          )}

          {/* Scraper Settings Tab */}
          {activeTab === "scraper" && (
            <div className="p-6 sm:p-8 space-y-6">
              <div>
                <h2 className="text-[18px] sm:text-[20px] font-bold text-white mb-1">Scraper Schedule & Configuration</h2>
                <p className="text-[#999999] text-[13px] sm:text-[14px]">Configure automated scraper frequency, target sources, and duplicate detection thresholds</p>
              </div>

              <form onSubmit={handleSaveScraper} className="space-y-6">
                <div>
                  <label className="block text-[#999999] text-[13px] sm:text-[14px] mb-2 font-medium">Schedule Frequency</label>
                  <div className="relative">
                    <select 
                      value={scraperConfig.scheduleFrequency}
                      onChange={(e) => setScraperConfig({...scraperConfig, scheduleFrequency: e.target.value})}
                      className="w-full h-[48px] bg-[#1A1A1A] border border-[#2A2A2A] rounded-[8px] px-4 text-white appearance-none focus:border-[#A2F301] outline-none text-[14px]"
                    >
                      <option value="Manual">Manual Only</option>
                      <option value="Hourly">Hourly (Every 1 hr)</option>
                      <option value="Daily">Daily (Once per day)</option>
                      <option value="Weekly">Weekly (Every Monday)</option>
                    </select>
                    <ChevronDown size={18} className="absolute right-4 top-1/2 -translate-y-1/2 text-[#999999] pointer-events-none" />
                  </div>
                </div>

                <div>
                  <label className="block text-[#999999] text-[13px] sm:text-[14px] mb-1.5 font-medium">Duplicate Detection Threshold (%)</label>
                  <input 
                    type="number"
                    min="50"
                    max="100"
                    required
                    value={scraperConfig.duplicateThreshold}
                    onChange={(e) => setScraperConfig({...scraperConfig, duplicateThreshold: e.target.value})}
                    className="w-full h-[48px] bg-[#1A1A1A] border border-[#2A2A2A] rounded-[8px] px-4 text-white focus:border-[#A2F301] outline-none text-[14px]"
                  />
                  <p className="text-[#666666] text-[12px] mt-2">
                    Similarity threshold percentage used by string matching algorithms to detect duplicate gig posts across scrapers and flag them in the moderation queue.
                  </p>
                </div>

                <div className="pt-4">
                  <button 
                    type="submit"
                    disabled={isLoading}
                    className="h-[48px] px-8 bg-[#A2F301] text-black font-bold rounded-[8px] flex items-center justify-center gap-2 hover:bg-[#8ed601] transition-all w-full sm:w-auto shadow-[0_8px_20px_-6px_rgba(162,243,1,0.4)] disabled:opacity-70"
                  >
                    {isLoading ? <Loader2 size={18} className="animate-spin" /> : <Save size={18} />}
                    <span>Save Scraper Settings</span>
                  </button>
                </div>
              </form>

              {/* Active Scraper Platforms Section */}
              <div className="bg-[#1A1A1A] border border-[#2A2A2A] rounded-[12px] p-6 space-y-4">
                <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2">
                  <div>
                    <h3 className="text-white font-bold text-[16px]">Active Scraper Platforms</h3>
                    <p className="text-[#999999] text-[13px]">Enable or disable main scraper platform engines for automatic gig extraction</p>
                  </div>
                </div>
                <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
                  {[
                    { name: "Facebook Groups", key: "Facebook", sub: "Group & Page Posts" },
                    { name: "Craigslist", key: "Craigslist", sub: "Gigs & Event Postings" },
                    { name: "GigSalad", key: "GigSalad", sub: "Musician Listings & Requests" },
                    { name: "Eventbrite", key: "Eventbrite", sub: "Live Concerts & Events" }
                  ].map((platform) => {
                    const active = platformToggles[platform.key as keyof typeof platformToggles];
                    return (
                      <div
                        key={platform.key}
                        onClick={() => setPlatformToggles(prev => ({ ...prev, [platform.key]: !prev[platform.key as keyof typeof platformToggles] }))}
                        className={`p-4 rounded-[10px] border-2 cursor-pointer transition-all flex items-start gap-3 ${
                          active ? "border-[#A2F301] bg-[#A2F301]/5" : "border-[#2A2A2A] bg-[#0F0F0F] hover:border-[#333333]"
                        }`}
                      >
                        <div className={`w-5 h-5 rounded-full flex items-center justify-center transition-all shrink-0 mt-0.5 ${
                          active ? "bg-[#A2F301]" : "border-2 border-[#444444] bg-transparent"
                        }`}>
                          {active && <Check size={12} strokeWidth={3} className="text-black" />}
                        </div>
                        <div>
                          <span className={`text-[14px] font-bold block ${active ? "text-white" : "text-[#888888]"}`}>
                            {platform.name}
                          </span>
                          <span className="text-[11px] text-[#666666] block mt-0.5">{platform.sub}</span>
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>

              {/* Active Target Sources Section */}
              <div className="bg-[#1A1A1A] border border-[#2A2A2A] rounded-[12px] p-6 space-y-6">
                <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2">
                  <div>
                    <h3 className="text-white font-bold text-[16px]">Registered Target Groups & URLs ({realScraperSources.length})</h3>
                    <p className="text-[#999999] text-[13px]">Specific target URLs and Facebook Groups stored in database for scraper extraction</p>
                  </div>
                  {isScraperLoading && <Loader2 size={18} className="animate-spin text-[#A2F301]" />}
                </div>

                {/* Form to Add New Target Source */}
                <form onSubmit={handleAddSource} className="grid grid-cols-1 sm:grid-cols-3 gap-3 bg-[#0F0F0F] p-4 rounded-[8px] border border-[#2A2A2A]">
                  <div>
                    <input 
                      type="text"
                      placeholder="Source Name (e.g. Texas Musicians FB)"
                      value={newSourceName}
                      onChange={(e) => setNewSourceName(e.target.value)}
                      className="w-full h-[40px] bg-[#1A1A1A] border border-[#2A2A2A] rounded-[6px] px-3 text-white text-[13px] outline-none focus:border-[#A2F301]"
                    />
                  </div>
                  <div>
                    <input 
                      type="url"
                      required
                      placeholder="https://facebook.com/groups/..."
                      value={newSourceUrl}
                      onChange={(e) => setNewSourceUrl(e.target.value)}
                      className="w-full h-[40px] bg-[#1A1A1A] border border-[#2A2A2A] rounded-[6px] px-3 text-white text-[13px] outline-none focus:border-[#A2F301]"
                    />
                  </div>
                  <button
                    type="submit"
                    disabled={isAddingSource || !newSourceUrl}
                    className="h-[40px] px-4 bg-[#A2F301] text-black font-bold rounded-[6px] hover:bg-[#8ed601] transition-all flex items-center justify-center gap-2 text-[13px] disabled:opacity-50"
                  >
                    {isAddingSource ? <Loader2 size={14} className="animate-spin" /> : <Plus size={14} />}
                    <span>Add Scraper Target</span>
                  </button>
                </form>

                {/* Target Sources Grid */}
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 max-h-[300px] overflow-y-auto pr-1">
                  {realScraperSources.map((source) => (
                    <div 
                      key={source.id} 
                      className="flex items-center justify-between p-3.5 bg-[#0F0F0F] border border-[#2A2A2A] rounded-[8px] hover:border-[#A2F301]/30 transition-all"
                    >
                      <div className="overflow-hidden pr-2">
                        <div className="flex items-center gap-2 mb-0.5">
                          <Check size={14} className="text-[#A2F301] flex-shrink-0" />
                          <span className="text-white font-bold text-[13px] truncate">{source.name || "Target Source"}</span>
                        </div>
                        <a 
                          href={source.url} 
                          target="_blank" 
                          rel="noreferrer"
                          className="text-[11px] text-[#999999] hover:text-[#A2F301] truncate block underline underline-offset-2"
                        >
                          {source.url}
                        </a>
                      </div>
                      <button
                        type="button"
                        onClick={() => handleDeleteSource(source.id, source.name)}
                        className="p-1.5 text-red-400 hover:text-red-300 hover:bg-red-500/10 rounded-[6px] transition-all flex-shrink-0"
                        title="Remove target source"
                      >
                        <Trash2 size={14} />
                      </button>
                    </div>
                  ))}
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
