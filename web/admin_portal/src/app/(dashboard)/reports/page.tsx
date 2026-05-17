"use client";

import React, { useState, useEffect } from "react";
import { 
  Users, 
  Briefcase, 
  DollarSign, 
  TrendingUp, 
  ArrowUpRight,
  Search,
  Calendar,
  ChevronDown,
  Loader2
} from "lucide-react";
import { 
  LineChart, 
  Line, 
  XAxis, 
  YAxis, 
  CartesianGrid, 
  Tooltip, 
  ResponsiveContainer, 
  AreaChart, 
  Area,
  BarChart,
  Bar,
  Legend,
  Cell
} from "recharts";
import { useMediaQuery } from "@/hooks/useMediaQuery";
import { apiRequest } from "@/lib/api";

// --- Types & Interfaces ---
interface GrowthData {
  month: string;
  musicians: number;
  organizers: number;
  total: number;
}

interface GigTrendData {
  month: string;
  manual: number;
  scraped: number;
}

interface RevenueData {
  month: string;
  revenue: number;
  bookings: number;
}

interface PerformanceMetric {
  label: string;
  value: string;
  subtext: string;
  color?: string;
}

interface MainStat {
  label: string;
  value: string;
  growth: string;
}

export default function ReportsPage() {
  const [timeframe, setTimeframe] = useState("Last 6 months");
  const [isMounted, setIsMounted] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const isMobile = useMediaQuery("(max-width: 640px)");

  // State for data
  const [growthData, setGrowthData] = useState<GrowthData[]>([]);
  const [gigTrends, setGigTrends] = useState<GigTrendData[]>([]);
  const [revenueData, setRevenueData] = useState<RevenueData[]>([]);
  const [mainStatsData, setMainStatsData] = useState<MainStat[]>([]);
  const [scraperMetrics, setScraperMetrics] = useState<PerformanceMetric[]>([]);

  useEffect(() => {
    setIsMounted(true);
    fetchAnalytics();
  }, []);

  const fetchAnalytics = async () => {
    try {
      setIsLoading(true);
      const data = await apiRequest("/reports/dashboard");
      setGrowthData(data.growthData);
      setGigTrends(data.gigTrends);
      setRevenueData(data.revenueData);
      setMainStatsData(data.mainStats);
      setScraperMetrics(data.scraperMetrics);
      setError(null);
    } catch (err: any) {
      console.error("Failed to fetch analytics:", err);
      setError("Failed to load analytics data. Please try again later.");
    } finally {
      setIsLoading(false);
    }
  };

  if (isLoading) {
    return (
      <div className="w-full h-[60vh] flex items-center justify-center">
        <Loader2 className="w-8 h-8 text-[#A2F301] animate-spin" />
      </div>
    );
  }

  if (error) {
    return (
      <div className="w-full h-[60vh] flex items-center justify-center flex-col gap-4">
        <p className="text-red-500">{error}</p>
        <button 
          onClick={fetchAnalytics}
          className="px-4 py-2 bg-[#A2F301] text-black rounded-md font-medium"
        >
          Retry
        </button>
      </div>
    );
  }

  // Map mainStatsData to include icons and styling
  const iconMap: Record<string, any> = {
    "Total Users": { icon: Users, color: "text-[#A2F301]", bg: "bg-[#A2F301]/10", border: "border-[#A2F301]/20" },
    "Total Gigs Posted": { icon: Briefcase, color: "text-[#3B82F6]", bg: "bg-[#3B82F6]/10", border: "border-[#3B82F6]/20" },
    "Total Revenue": { icon: DollarSign, color: "text-[#10B981]", bg: "bg-[#10B981]/10", border: "border-[#10B981]/20" },
    "Booking Success": { icon: TrendingUp, color: "text-[#F59E0B]", bg: "bg-[#F59E0B]/10", border: "border-[#F59E0B]/20" }
  };

  const mainStats = mainStatsData.map(stat => ({
    ...stat,
    ...(iconMap[stat.label] || { icon: Briefcase, color: "text-[#3B82F6]", bg: "bg-[#3B82F6]/10", border: "border-[#3B82F6]/20" })
  }));

  return (
    <div className="w-full text-white font-inter pb-20">
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-2xl sm:text-[32px] font-bold mb-2 leading-tight">Reports & Analytics</h1>
        <p className="text-[#999999] text-sm sm:text-[16px]">Comprehensive analytics and data insights</p>
      </div>

      {/* Main Stats Grid */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 sm:gap-6 mb-8">
        {mainStats.map((stat, idx) => (
          <div key={idx} className="bg-[#1A1A1A] border border-[#2A2A2A] rounded-[10px] p-4 sm:p-6 flex flex-col sm:flex-row items-start sm:items-center gap-4 sm:gap-5 group hover:border-white/10 transition-all shadow-xl">
            <div className={`w-12 h-12 sm:w-[56px] sm:h-[56px] rounded-[12px] ${stat.bg} ${stat.border} border flex items-center justify-center shrink-0`}>
              <stat.icon className={stat.color} size={24} />
            </div>
            <div>
              <p className="text-[#999999] text-[12px] sm:text-[14px] mb-0.5">{stat.label}</p>
              <h3 className="text-xl sm:text-[28px] font-bold leading-tight">{stat.value}</h3>
              <p className="text-[#10B981] text-[11px] sm:text-[13px] font-medium flex items-center gap-1 mt-0.5">
                <span className="text-[12px] sm:text-[14px]">↑</span>
                {stat.growth.replace('+ ', '').replace('increase', 'growth')}
              </p>
            </div>
          </div>
        ))}
      </div>


      {/* User Growth Trends Chart */}
      <div className="bg-[#1A1A1A] border border-[#2A2A2A] rounded-[8px] p-6 sm:p-8 mb-8 shadow-2xl">
        <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 mb-8">
          <h2 className="text-[18px] sm:text-[20px] font-bold">User Growth Trends</h2>
          <div className="relative group w-full sm:w-auto">
            <button className="w-full sm:w-auto h-[36px] px-4 bg-[#0D0D0D] border border-[#2A2A2A] rounded-[8px] text-[14px] flex items-center justify-between sm:justify-start gap-2 text-[#999999] hover:text-white transition-all">
              {timeframe}
              <ChevronDown size={16} />
            </button>
          </div>
        </div>
        <div className="h-[300px] sm:h-[320px] w-full min-w-0">
          {isMounted && (
            <ResponsiveContainer width="100%" height="100%" minWidth={0}>
              <LineChart data={growthData}>
                <CartesianGrid strokeDasharray="3 3" stroke="#2A2A2A" vertical={false} />
                <XAxis 
                  dataKey="month" 
                  stroke="#666666" 
                  fontSize={10} 
                  tickLine={false} 
                  axisLine={false} 
                  dy={10}
                />
                <YAxis 
                  stroke="#666666" 
                  fontSize={10} 
                  tickLine={false} 
                  axisLine={false} 
                  tickFormatter={(value) => `${value}`}
                />
                <Tooltip 
                  contentStyle={{ backgroundColor: '#1A1A1A', border: '1px solid #2A2A2A', borderRadius: '8px' }}
                  itemStyle={{ fontSize: '10px' }}
                />
                <Legend 
                  verticalAlign="bottom" 
                  height={36} 
                  iconType="circle"
                  wrapperStyle={{ paddingTop: '20px', fontSize: '10px' }}
                />
                <Line 
                  type="monotone" 
                  dataKey="musicians" 
                  name="Musicians" 
                  stroke="#A2F301" 
                  strokeWidth={2} 
                  dot={{ fill: '#A2F301', r: 3 }} 
                  activeDot={{ r: 5 }} 
                />
                <Line 
                  type="monotone" 
                  dataKey="organizers" 
                  name="Organizers" 
                  stroke="#3B82F6" 
                  strokeWidth={2} 
                  dot={{ fill: '#3B82F6', r: 3 }} 
                />
                <Line 
                  type="monotone" 
                  dataKey="total" 
                  name="Total Users" 
                  stroke="#8B5CF6" 
                  strokeWidth={2} 
                  dot={{ fill: '#8B5CF6', r: 3 }} 
                />
              </LineChart>
            </ResponsiveContainer>
          )}
        </div>
      </div>

      {/* Gig Posting Trends Chart */}
      <div className="bg-[#1A1A1A] border border-[#2A2A2A] rounded-[8px] p-6 sm:p-8 mb-8 shadow-2xl">
        <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 mb-8">
          <h2 className="text-[18px] sm:text-[20px] font-bold">Gig Posting Trends</h2>
          <div className="flex items-center gap-4 flex-wrap">
            <div className="flex items-center gap-2">
              <div className="w-3 h-3 rounded-sm bg-[#A2F301]" />
              <span className="text-[11px] sm:text-[12px] text-[#999999]">Manual Posts</span>
            </div>
            <div className="flex items-center gap-2">
              <div className="w-3 h-3 rounded-sm bg-[#3B82F6]" />
              <span className="text-[11px] sm:text-[12px] text-[#999999]">Scraped Gigs</span>
            </div>
          </div>
        </div>
        <div className="h-[300px] sm:h-[320px] w-full min-w-0">
          {isMounted && (
            <ResponsiveContainer width="100%" height="100%" minWidth={0}>
              <BarChart data={gigTrends}>
                <CartesianGrid strokeDasharray="3 3" stroke="#2A2A2A" vertical={false} />
                <XAxis 
                  dataKey="month" 
                  stroke="#666666" 
                  fontSize={10} 
                  tickLine={false} 
                  axisLine={false} 
                  dy={10}
                />
                <YAxis 
                  stroke="#666666" 
                  fontSize={10} 
                  tickLine={false} 
                  axisLine={false} 
                />
                <Tooltip 
                  contentStyle={{ backgroundColor: '#1A1A1A', border: '1px solid #2A2A2A', borderRadius: '8px' }}
                  cursor={{ fill: 'rgba(255, 255, 255, 0.05)' }}
                />
                <Bar dataKey="manual" name="Manual Posts" fill="#A2F301" radius={[4, 4, 0, 0]} barSize={isMobile ? 15 : 40} />
                <Bar dataKey="scraped" name="Scraped Gigs" fill="#3B82F6" radius={[4, 4, 0, 0]} barSize={isMobile ? 15 : 40} />
              </BarChart>
            </ResponsiveContainer>
          )}
        </div>
      </div>

      {/* Revenue & Booking Analytics Chart */}
      <div className="bg-[#1A1A1A] border border-[#2A2A2A] rounded-[8px] p-6 sm:p-8 mb-8 shadow-2xl">
        <div className="mb-8">
          <h2 className="text-[18px] sm:text-[20px] font-bold">Revenue & Booking Analytics</h2>
        </div>
        <div className="h-[300px] sm:h-[320px] w-full min-w-0">
          {isMounted && (
            <ResponsiveContainer width="100%" height="100%" minWidth={0}>
              <LineChart data={revenueData}>
                <CartesianGrid strokeDasharray="3 3" stroke="#2A2A2A" vertical={false} />
                <XAxis 
                  dataKey="month" 
                  stroke="#666666" 
                  fontSize={10} 
                  tickLine={false} 
                  axisLine={false} 
                  dy={10}
                />
                <YAxis 
                  yAxisId="left"
                  stroke="#666666" 
                  fontSize={10} 
                  tickLine={false} 
                  axisLine={false} 
                  tickFormatter={(value) => `$${value}`}
                />
                <YAxis 
                  yAxisId="right"
                  orientation="right"
                  stroke="#666666" 
                  fontSize={10} 
                  tickLine={false} 
                  axisLine={false} 
                />
                <Tooltip 
                  contentStyle={{ backgroundColor: '#1A1A1A', border: '1px solid #2A2A2A', borderRadius: '8px' }}
                />
                <Legend 
                  verticalAlign="bottom" 
                  height={36} 
                  iconType="circle"
                  wrapperStyle={{ paddingTop: '20px', fontSize: '10px' }}
                />
                <Line 
                  yAxisId="left"
                  type="monotone" 
                  dataKey="revenue" 
                  name="Revenue ($)" 
                  stroke="#F59E0B" 
                  strokeWidth={2} 
                  dot={{ fill: '#F59E0B', r: 3 }} 
                />
                <Line 
                  yAxisId="right"
                  type="monotone" 
                  dataKey="bookings" 
                  name="Bookings" 
                  stroke="#A2F301" 
                  strokeWidth={2} 
                  dot={{ fill: '#A2F301', r: 3 }} 
                />
              </LineChart>
            </ResponsiveContainer>
          )}
        </div>
      </div>

      {/* Scraper Performance Report Grid */}
      <div className="mb-8">
        <h2 className="text-[18px] sm:text-[20px] font-bold mb-6">Scraper Performance Report</h2>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
          {scraperMetrics.map((metric, idx) => (
            <div key={idx} className="bg-[#1A1A1A] border border-[#2A2A2A] rounded-[8px] p-6 sm:p-8 shadow-xl">
              <p className="text-[#999999] text-[13px] sm:text-[14px] mb-2 font-medium">{metric.label}</p>
              <h3 className={`${metric.color || 'text-white'} text-2xl sm:text-[32px] font-bold mb-1`}>{metric.value}</h3>
              <p className="text-[#999999] text-[11px] sm:text-[12px]">{metric.subtext}</p>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
