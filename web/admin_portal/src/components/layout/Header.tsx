"use client";

import { useState, useEffect, useCallback, useRef } from "react";
import { 
  Search, 
  Bell, 
  ChevronDown, 
  User, 
  LogOut, 
  Menu, 
  X, 
  Users, 
  Briefcase, 
  Globe, 
  Sliders, 
  Settings, 
  FileText, 
  AlertTriangle, 
  CreditCard, 
  Star, 
  MessageSquare,
  ArrowRight,
  Loader2
} from "lucide-react";
import { useRouter } from "next/navigation";
import { NotificationPanel } from "./NotificationPanel";
import { ProfileDropdown } from "./ProfileDropdown";
import { apiRequest } from "@/lib/api";

interface HeaderProps {
  onMenuClick: () => void;
}

const ADMIN_PAGES = [
  { title: "User Management", subtitle: "Musicians, Organizers & Approvals", href: "/users", icon: Users },
  { title: "Gigs Management", subtitle: "Active & Scraped Gigs", href: "/gigs", icon: Briefcase },
  { title: "Facebook Scraper Control", subtitle: "Scraper runs & moderation", href: "/scraper", icon: Globe },
  { title: "System Config & Services", subtitle: "SendGrid, FB Groups CSV & Cookies", href: "/system-config", icon: Sliders },
  { title: "Contracts", subtitle: "Signed gig contracts & agreements", href: "/contracts", icon: FileText },
  { title: "Disputes", subtitle: "Dispute resolution center", href: "/disputes", icon: AlertTriangle },
  { title: "Payments & Financials", subtitle: "Escrows & Stripe transactions", href: "/payments", icon: CreditCard },
  { title: "Reviews & Ratings", subtitle: "Moderation of user reviews", href: "/reviews", icon: Star },
  { title: "Messages & Live Chat", subtitle: "Support and direct messages", href: "/messages", icon: MessageSquare },
  { title: "Admin Settings", subtitle: "Profile, 2FA & preferences", href: "/settings", icon: Settings },
];

export function Header({ onMenuClick }: HeaderProps) {
  const router = useRouter();
  const [isNotificationsOpen, setIsNotificationsOpen] = useState(false);
  const [isProfileOpen, setIsProfileOpen] = useState(false);
  const [adminUser, setAdminUser] = useState<{ displayName?: string; email?: string; profileImageUrl?: string } | null>(null);
  const [unreadCount, setUnreadCount] = useState(0);

  // Global Search State
  const [searchQuery, setSearchQuery] = useState("");
  const [isSearchOpen, setIsSearchOpen] = useState(false);
  const [isSearching, setIsSearching] = useState(false);
  const [userResults, setUserResults] = useState<any[]>([]);
  const [gigResults, setGigResults] = useState<any[]>([]);
  const searchContainerRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const loadUser = () => {
      const userStr = localStorage.getItem("admin_user");
      if (userStr) {
        try {
          setAdminUser(JSON.parse(userStr));
        } catch (e) {
          console.error("Failed to parse admin_user", e);
        }
      }
    };

    loadUser();
    fetchUnreadCount();

    const interval = setInterval(fetchUnreadCount, 30000);

    const handleClickOutside = (e: MouseEvent) => {
      if (searchContainerRef.current && !searchContainerRef.current.contains(e.target as Node)) {
        setIsSearchOpen(false);
      }
    };

    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === "Escape") {
        setIsSearchOpen(false);
      }
    };

    window.addEventListener("storage", loadUser);
    window.addEventListener("admin_user_updated", loadUser);
    document.addEventListener("mousedown", handleClickOutside);
    document.addEventListener("keydown", handleKeyDown);

    return () => {
      clearInterval(interval);
      window.removeEventListener("storage", loadUser);
      window.removeEventListener("admin_user_updated", loadUser);
      document.removeEventListener("mousedown", handleClickOutside);
      document.removeEventListener("keydown", handleKeyDown);
    };
  }, []);

  const fetchUnreadCount = useCallback(async () => {
    try {
      const data = await apiRequest("/admin/notifications/unread-count");
      setUnreadCount(data.count || 0);
    } catch (error) {
      // silent fail
    }
  }, []);

  // Cache for instant partial-word search without network lag
  const searchCacheRef = useRef<{
    musicians: any[];
    organizers: any[];
    gigs: any[];
    loaded: boolean;
  }>({
    musicians: [],
    organizers: [],
    gigs: [],
    loaded: false,
  });

  const loadSearchCache = useCallback(async () => {
    if (searchCacheRef.current.loaded) return;
    try {
      const [musiciansData, organizersData, gigsData] = await Promise.allSettled([
        apiRequest("/auth/musicians"),
        apiRequest("/auth/organizers"),
        apiRequest("/gigs/list")
      ]);

      const musicians = musiciansData.status === "fulfilled" && Array.isArray(musiciansData.value) ? musiciansData.value : [];
      const organizers = organizersData.status === "fulfilled" && Array.isArray(organizersData.value) ? organizersData.value : [];
      const gigs = gigsData.status === "fulfilled" && Array.isArray(gigsData.value) ? gigsData.value : [];

      searchCacheRef.current = {
        musicians,
        organizers,
        gigs,
        loaded: true
      };
    } catch (err) {
      console.error("Failed to preload search cache:", err);
    }
  }, []);

  // Preload on mount in background
  useEffect(() => {
    loadSearchCache();
  }, [loadSearchCache]);

  // Instant partial-word search across pages, users, and gigs
  useEffect(() => {
    const q = searchQuery.trim().toLowerCase();
    if (!q) {
      setUserResults([]);
      setGigResults([]);
      setIsSearching(false);
      return;
    }

    const performFilter = () => {
      const { musicians, organizers, gigs } = searchCacheRef.current;

      const matchedMusicians = musicians
        .filter((m: any) => 
          (m.fullName && m.fullName.toLowerCase().includes(q)) || 
          (m.email && m.email.toLowerCase().includes(q))
        )
        .slice(0, 4)
        .map((m: any) => ({
          id: m.id,
          name: m.fullName || "Musician",
          email: m.email,
          role: "Musician",
          href: `/users?q=${encodeURIComponent(m.email || m.fullName)}&tab=musicians`
        }));

      const matchedOrganizers = organizers
        .filter((o: any) => 
          (o.name && o.name.toLowerCase().includes(q)) || 
          (o.email && o.email.toLowerCase().includes(q))
        )
        .slice(0, 4)
        .map((o: any) => ({
          id: o.id,
          name: o.name || "Organizer",
          email: o.email,
          role: "Organizer",
          href: `/users?q=${encodeURIComponent(o.email || o.name)}&tab=organizers`
        }));

      const matchedGigs = gigs
        .filter((g: any) => 
          (g.title && g.title.toLowerCase().includes(q)) || 
          (g.venue && g.venue.toLowerCase().includes(q)) || 
          (g.location && g.location.toLowerCase().includes(q))
        )
        .slice(0, 4)
        .map((g: any) => ({
          id: g.id || g.uid,
          title: g.title || "Gig",
          venue: g.venue || g.location || "Venue",
          href: `/gigs?q=${encodeURIComponent(g.title)}`
        }));

      setUserResults([...matchedMusicians, ...matchedOrganizers]);
      setGigResults(matchedGigs);
      setIsSearching(false);
    };

    if (searchCacheRef.current.loaded) {
      performFilter();
    } else {
      setIsSearching(true);
      loadSearchCache().then(() => {
        performFilter();
      });
    }
  }, [searchQuery, loadSearchCache]);

  const filteredPages = searchQuery.trim()
    ? ADMIN_PAGES.filter(p => 
        p.title.toLowerCase().includes(searchQuery.toLowerCase()) || 
        p.subtitle.toLowerCase().includes(searchQuery.toLowerCase())
      )
    : ADMIN_PAGES.slice(0, 5);

  const handleSearchSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!searchQuery.trim()) return;

    // If there's an exact or close page match, go there
    if (filteredPages.length > 0 && searchQuery.length > 2) {
      const directMatch = ADMIN_PAGES.find(p => p.title.toLowerCase() === searchQuery.trim().toLowerCase());
      if (directMatch) {
        router.push(directMatch.href);
        setIsSearchOpen(false);
        return;
      }
    }

    // Default: search in users
    router.push(`/users?q=${encodeURIComponent(searchQuery.trim())}`);
    setIsSearchOpen(false);
  };

  const handleSelectResult = (href: string) => {
    router.push(href);
    setIsSearchOpen(false);
    setSearchQuery("");
  };

  return (
    <header className="h-[80px] bg-[#0F0F0F] border-b border-[#1a1a1e] fixed top-0 right-0 left-0 xl:left-[280px] z-40 flex items-center justify-between px-4 sm:px-10 transition-all duration-300">
      <div className="flex items-center gap-4 flex-1">
        <button 
          onClick={onMenuClick}
          className="xl:hidden p-2 text-[#a1a1aa] hover:text-white transition-colors"
        >
          <Menu size={24} />
        </button>

        {/* Global Search Bar */}
        <div ref={searchContainerRef} className="relative w-full max-w-[340px] group hidden sm:block">
          <form onSubmit={handleSearchSubmit} className="relative">
            <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-[18px] h-[18px] text-[#52525b] group-focus-within:text-[#b3ff00] transition-colors" />
            <input
              type="text"
              placeholder="Search users, gigs, pages..."
              value={searchQuery}
              onChange={(e) => {
                setSearchQuery(e.target.value);
                setIsSearchOpen(true);
              }}
              onFocus={() => setIsSearchOpen(true)}
              className="w-full h-[42px] bg-[#1A1A1A] border border-[#27272a] rounded-xl pl-11 pr-10 text-[14px] text-white focus:outline-none focus:border-[#b3ff00]/50 focus:ring-1 focus:ring-[#b3ff00]/30 transition-all placeholder:text-[#52525b]"
            />
            {searchQuery && (
              <button
                type="button"
                onClick={() => {
                  setSearchQuery("");
                  setUserResults([]);
                  setGigResults([]);
                }}
                className="absolute right-3 top-1/2 -translate-y-1/2 p-1 text-[#71717a] hover:text-white transition-colors"
              >
                <X className="w-4 h-4" />
              </button>
            )}
          </form>

          {/* Search Results Dropdown */}
          {isSearchOpen && (
            <div className="absolute top-full left-0 mt-2 w-[420px] max-w-[90vw] bg-[#141416] border border-[#27272a] rounded-xl shadow-2xl overflow-hidden z-50 animate-in fade-in duration-150">
              <div className="max-h-[460px] overflow-y-auto divide-y divide-zinc-800/50 p-2 text-xs">
                {/* Pages & Navigation Results */}
                {filteredPages.length > 0 && (
                  <div className="py-1.5">
                    <p className="px-3 py-1 text-[10px] font-bold text-[#71717a] uppercase tracking-wider">
                      {searchQuery ? "Pages & Navigation" : "Quick Links"}
                    </p>
                    {filteredPages.map((page, i) => {
                      const Icon = page.icon;
                      return (
                        <button
                          key={i}
                          type="button"
                          onClick={() => handleSelectResult(page.href)}
                          className="w-full px-3 py-2 flex items-center justify-between rounded-lg hover:bg-zinc-800/70 text-left transition-colors group"
                        >
                          <div className="flex items-center gap-2.5">
                            <div className="p-1.5 rounded-md bg-zinc-900 text-[#b3ff00] group-hover:bg-[#b3ff00]/10">
                              <Icon className="w-3.5 h-3.5" />
                            </div>
                            <div>
                              <div className="font-semibold text-white group-hover:text-[#b3ff00] transition-colors text-xs">
                                {page.title}
                              </div>
                              <div className="text-[11px] text-zinc-500">{page.subtitle}</div>
                            </div>
                          </div>
                          <ArrowRight className="w-3.5 h-3.5 text-zinc-600 group-hover:text-white group-hover:translate-x-0.5 transition-all" />
                        </button>
                      );
                    })}
                  </div>
                )}

                {/* Users Results */}
                {userResults.length > 0 && (
                  <div className="py-1.5">
                    <p className="px-3 py-1 text-[10px] font-bold text-[#71717a] uppercase tracking-wider">
                      Users Found
                    </p>
                    {userResults.map((u, i) => (
                      <button
                        key={i}
                        type="button"
                        onClick={() => handleSelectResult(u.href)}
                        className="w-full px-3 py-2 flex items-center justify-between rounded-lg hover:bg-zinc-800/70 text-left transition-colors group"
                      >
                        <div className="flex items-center gap-2.5">
                          <div className="w-7 h-7 rounded-full bg-zinc-800 text-[#b3ff00] flex items-center justify-center font-bold text-[10px]">
                            {u.role === "Musician" ? "M" : "O"}
                          </div>
                          <div>
                            <div className="font-semibold text-white group-hover:text-[#b3ff00] transition-colors text-xs">
                              {u.name}
                            </div>
                            <div className="text-[11px] text-zinc-500">{u.email}</div>
                          </div>
                        </div>
                        <span className="text-[10px] px-2 py-0.5 rounded bg-zinc-800 text-zinc-400 group-hover:text-white">
                          {u.role}
                        </span>
                      </button>
                    ))}
                  </div>
                )}

                {/* Gigs Results */}
                {gigResults.length > 0 && (
                  <div className="py-1.5">
                    <p className="px-3 py-1 text-[10px] font-bold text-[#71717a] uppercase tracking-wider">
                      Gigs Found
                    </p>
                    {gigResults.map((g, i) => (
                      <button
                        key={i}
                        type="button"
                        onClick={() => handleSelectResult(g.href)}
                        className="w-full px-3 py-2 flex items-center justify-between rounded-lg hover:bg-zinc-800/70 text-left transition-colors group"
                      >
                        <div className="flex items-center gap-2.5">
                          <div className="p-1.5 rounded-md bg-zinc-900 text-indigo-400">
                            <Briefcase className="w-3.5 h-3.5" />
                          </div>
                          <div>
                            <div className="font-semibold text-white group-hover:text-[#b3ff00] transition-colors text-xs">
                              {g.title}
                            </div>
                            <div className="text-[11px] text-zinc-500">{g.venue}</div>
                          </div>
                        </div>
                        <ArrowRight className="w-3.5 h-3.5 text-zinc-600 group-hover:text-white" />
                      </button>
                    ))}
                  </div>
                )}

                {/* Loading indicator */}
                {isSearching && (
                  <div className="py-3 flex items-center justify-center gap-2 text-zinc-400 text-xs">
                    <Loader2 className="w-3.5 h-3.5 animate-spin text-[#b3ff00]" />
                    <span>Searching database...</span>
                  </div>
                )}

                {/* No results message */}
                {searchQuery.trim().length >= 2 && !isSearching && filteredPages.length === 0 && userResults.length === 0 && gigResults.length === 0 && (
                  <div className="py-6 text-center text-zinc-500 text-xs">
                    No matching users, gigs, or pages found for &ldquo;{searchQuery}&rdquo;
                  </div>
                )}

                {/* Search in Users action footer */}
                {searchQuery.trim().length > 0 && (
                  <div className="pt-2 px-2 pb-1 flex items-center justify-between text-[11px] text-zinc-400 border-t border-zinc-800/60 mt-1">
                    <span>Press <strong className="text-white">Enter</strong> to search in Users</span>
                    <button
                      type="button"
                      onClick={() => handleSelectResult(`/users?q=${encodeURIComponent(searchQuery.trim())}`)}
                      className="text-[#b3ff00] hover:underline font-semibold"
                    >
                      Search Users &rarr;
                    </button>
                  </div>
                )}
              </div>
            </div>
          )}
        </div>
      </div>

      <div className="flex items-center gap-4 sm:gap-8 relative">
        <button 
          onClick={() => {
            setIsNotificationsOpen(!isNotificationsOpen);
            if (isProfileOpen) setIsProfileOpen(false);
          }}
          className={`relative p-2 transition-colors ${isNotificationsOpen ? "text-[#b3ff00]" : "text-[#a1a1aa] hover:text-white"}`}
        >
          <Bell className="w-[22px] h-[22px]" />
          {unreadCount > 0 && (
            <span className="absolute -top-0.5 -right-0.5 min-w-[18px] h-[18px] bg-[#A2F301] text-black text-[10px] font-bold flex items-center justify-center rounded-full border-2 border-[#0A0A0A] px-1">
              {unreadCount > 99 ? "99+" : unreadCount}
            </span>
          )}
        </button>

        <NotificationPanel 
          isOpen={isNotificationsOpen} 
          onClose={() => setIsNotificationsOpen(false)}
          onUnreadCountChange={setUnreadCount}
        />

        <div 
          onClick={() => {
            setIsProfileOpen(!isProfileOpen);
            if (isNotificationsOpen) setIsNotificationsOpen(false);
          }}
          className="flex items-center gap-2 sm:gap-4 cursor-pointer group relative"
        >
          <div className="text-right flex flex-col justify-center hidden sm:flex">
            <p className="text-[14px] font-bold text-white leading-none mb-1 group-hover:text-[#b3ff00] transition-colors">
              {(adminUser as any)?.displayName && (adminUser as any).displayName !== "Admin User"
                ? (adminUser as any).displayName
                : (adminUser as any)?.name || ((adminUser as any)?.firstName || (adminUser as any)?.lastName
                    ? `${(adminUser as any)?.firstName || ''} ${(adminUser as any)?.lastName || ''}`.trim()
                    : "Muhammad Ali")}
            </p>
            <p className="text-[11px] text-[#52525b] font-medium leading-none">Super Admin</p>
          </div>
          <div className={`w-[36px] h-[36px] sm:w-[40px] sm:h-[40px] rounded-full overflow-hidden bg-[#b3ff00] flex items-center justify-center border border-white/10 shadow-lg transition-all ${isProfileOpen ? "ring-2 ring-[#b3ff00]/50" : "group-hover:scale-105"}`}>
            {adminUser?.profileImageUrl ? (
              <img src={adminUser.profileImageUrl} alt="Admin" className="w-full h-full object-cover" />
            ) : (
              <User className="w-4 h-4 sm:w-5 sm:h-5 text-black" />
            )}
          </div>
          <ChevronDown className={`w-3.5 h-3.5 sm:w-4 sm:h-4 text-[#52525b] transition-all duration-300 ${isProfileOpen ? "rotate-180 text-white" : "group-hover:text-white"}`} />
          
          <ProfileDropdown 
            isOpen={isProfileOpen} 
            onClose={() => setIsProfileOpen(false)} 
          />
        </div>
      </div>
    </header>
  );
}
