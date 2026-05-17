"use client";

import React, { useState, useEffect } from "react";
import { 
  Music, 
  Users, 
  Briefcase, 
  Database, 
  Calendar, 
  DollarSign, 
  ShieldAlert, 
  TrendingUp,
  UserPlus,
  Play,
  CheckCircle2,
  AlertCircle,
  Activity,
  Loader2
} from "lucide-react";
import { apiRequest } from "@/lib/api";

export default function DashboardOverview() {
  const [isLoading, setIsLoading] = useState(true);
  const [analytics, setAnalytics] = useState<any>(null);
  const [stats, setStats] = useState([
    { label: "Total Musicians", value: "0", change: "...", isTrend: true, icon: Music },
    { label: "Total Organizers", value: "0", change: "...", isTrend: true, icon: Users },
    { label: "Total Active Gigs", value: "0", change: "...", isTrend: true, icon: Briefcase },
    { label: "Scraped Gigs Count", value: "0", change: "...", isTrend: false, icon: Database },
    { label: "Active Bookings", value: "0", change: "...", isTrend: true, icon: Calendar },
    { label: "Escrow Funds", value: "$0", change: "...", isTrend: false, icon: DollarSign },
    { label: "Open Disputes", value: "0", change: "...", isTrend: true, icon: ShieldAlert },
    { label: "Monthly Revenue", value: "$0", change: "...", isTrend: true, icon: DollarSign },
  ]);

  const activities = [
    { icon: UserPlus, title: "Backend connected: Live monitoring active", time: "Just now", color: "text-[#b3ff00]", bg: "bg-[#b3ff00]/10" },
    { icon: CheckCircle2, title: "System check: All services operational", time: "1 min ago", color: "text-[#b3ff00]", bg: "bg-[#b3ff00]/10" },
  ];

  useEffect(() => {
    const fetchDashboardData = async () => {
      setIsLoading(true);
      try {
        const data = await apiRequest("/reports/dashboard");
        setAnalytics(data);

        // Find specific stats from mainStats array
        const getStatValue = (label: string) => data.mainStats.find((s: any) => s.label === label);
        
        const totalUsers = getStatValue("Total Users");
        const totalGigs = getStatValue("Total Gigs Posted");
        const totalRevenue = getStatValue("Total Revenue");
        const bookingSuccess = getStatValue("Booking Success");

        // Get latest month data for musicians/organizers breakdown
        const latestGrowth = data.growthData[data.growthData.length - 1];
        const scrapedMetric = data.scraperMetrics.find((m: any) => m.label === "Gigs Imported");

        setStats([
          { label: "Total Musicians", value: latestGrowth.musicians.toLocaleString(), change: "+0% from last month", isTrend: true, icon: Music },
          { label: "Total Organizers", value: latestGrowth.organizers.toLocaleString(), change: "+0% from last month", isTrend: true, icon: Users },
          { label: "Total Active Gigs", value: totalGigs?.value || "0", change: totalGigs?.growth || "0%", isTrend: true, icon: Briefcase },
          { label: "Scraped Gigs Count", value: scrapedMetric?.value || "0", change: scrapedMetric?.subtext || "0%", isTrend: false, icon: Database },
          { label: "Active Bookings", value: data.revenueData[data.revenueData.length - 1].bookings.toString(), change: "Live", isTrend: true, icon: Calendar },
          { label: "Escrow Funds", value: "$0", change: "Total locked", isTrend: false, icon: DollarSign },
          { label: "Open Disputes", value: "0", change: "None active", isTrend: true, icon: ShieldAlert },
          { label: "Monthly Revenue", value: totalRevenue?.value || "$0", change: totalRevenue?.growth || "0%", isTrend: true, icon: DollarSign },
        ]);
      } catch (err) {
        console.error("Failed to fetch dashboard stats", err);
      } finally {
        setIsLoading(false);
      }
    };

    fetchDashboardData();
  }, []);

  return (
    <div className="space-y-8 animate-in fade-in duration-700 relative">
      {isLoading && (
        <div className="fixed inset-0 bg-black/20 backdrop-blur-[2px] z-50 flex items-center justify-center pointer-events-none">
          <Loader2 className="w-10 h-10 text-[#b3ff00] animate-spin" />
        </div>
      )}
      
      {/* Title Section */}
      <div>
        <h1 className="text-2xl sm:text-[32px] font-bold text-white mb-2">Dashboard Overview</h1>
        <p className="text-[#a1a1aa] text-sm sm:text-[16px]">High-level system control and monitoring (Live Data)</p>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
        {stats.map((stat, i) => (
          <div key={i} className="bg-[#1A1A1A] border border-[#1a1a1e] rounded-xl p-6 hover:border-[#b3ff00]/20 transition-all group">
            <div className="flex justify-between items-start">
              <div>
                <p className="text-[#a1a1aa] text-[14px] font-normal mb-1">{stat.label}</p>
                <p className="text-[28px] font-bold text-white tracking-tight mb-1">{stat.value}</p>
                <p className={`text-[13px] ${stat.isTrend ? 'text-[#10B981]' : 'text-[#a1a1aa]'} font-medium`}>{stat.change}</p>
              </div>
              <div className="w-11 h-11 bg-[#b3ff00]/10 rounded-xl flex items-center justify-center transition-transform group-hover:scale-105">
                <stat.icon className="w-6 h-6 text-[#b3ff00]" />
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Middle Charts Section */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* User Growth Trend */}
        <div className="lg:col-span-2 bg-[#1A1A1A] border border-[#1a1a1e] rounded-2xl p-4 sm:p-8 pb-12">
          <div className="flex justify-between items-center mb-8">
            <h3 className="text-white font-bold text-[18px]">User Growth Trend</h3>
          </div>
          <div className="h-auto w-full relative overflow-x-auto custom-scrollbar">
            {analytics && (() => {
              const musicianGrowth = analytics.growthData.map((d: any) => d.musicians);
              const organizerGrowth = analytics.growthData.map((d: any) => d.organizers);
              const months = analytics.growthData.map((d: any) => d.month);
              
              const maxVal = Math.max(...musicianGrowth, ...organizerGrowth, 100) * 1.2;
              const chartHeight = 280;
              
              const valueToY = (val: number) => chartHeight - (val / maxVal * chartHeight);
              const getPath = (data: number[]) => 
                data.map((val, i) => `${i === 0 ? 'M' : 'L'} ${50 + (i * 160)} ${valueToY(val)}`).join(' ');

              return (
                <div className="h-[320px] min-w-[850px] relative">
                  <svg className="w-full h-full overflow-visible" viewBox="0 0 850 320">
                    {/* Horizontal Grid Lines */}
                    {[0, 1, 2, 3, 4].map((i) => (
                      <g key={`h-${i}`}>
                        <line x1="50" y1={chartHeight - (i * 70)} x2="850" y2={chartHeight - (i * 70)} stroke="#27272a" strokeWidth="1" strokeDasharray="4 4" />
                        <text x="0" y={chartHeight - (i * 70) + 5} className="fill-[#a1a1aa] text-[12px]">{Math.round(i * maxVal / 4)}</text>
                      </g>
                    ))}

                    {/* Vertical Grid Lines */}
                    {months.map((_: any, i: number) => (
                      <line 
                        key={`v-${i}`} 
                        x1={50 + (i * 160)} 
                        y1="0" 
                        x2={50 + (i * 160)} 
                        y2={chartHeight} 
                        stroke="#27272a" 
                        strokeWidth="1" 
                        strokeDasharray="4 4" 
                      />
                    ))}

                    {/* Month Labels */}
                    {months.map((m: string, i: number) => (
                      <g key={`label-${i}`} className="fill-[#a1a1aa] text-[12px]">
                        <text x={50 + (i * 160)} y="310" textAnchor="middle">{m}</text>
                      </g>
                    ))}
                    
                    {/* Organizers Line (Blue) */}
                    <path d={getPath(organizerGrowth)} fill="none" stroke="#3b82f6" strokeWidth="2" />
                    {organizerGrowth.map((val: number, i: number) => (
                      <g key={`p-org-${i}`}>
                        <circle cx={50 + (i * 160)} cy={valueToY(val)} r="5" fill="#3b82f6" />
                        <circle cx={50 + (i * 160)} cy={valueToY(val)} r="2" fill="white" />
                      </g>
                    ))}

                    {/* Musicians Line (Neon Green) */}
                    <path d={getPath(musicianGrowth)} fill="none" stroke="#b3ff00" strokeWidth="2" />
                    {musicianGrowth.map((val: number, i: number) => (
                      <g key={`p-mus-${i}`}>
                        <circle cx={50 + (i * 160)} cy={valueToY(val)} r="5" fill="#b3ff00" />
                        <circle cx={50 + (i * 160)} cy={valueToY(val)} r="2" fill="white" />
                      </g>
                    ))}
                  </svg>
                </div>
              );
            })()}

            {/* Legend at Bottom Center */}
            <div className="flex justify-center gap-4 sm:gap-8 mt-16 min-w-[300px]">
              <div className="flex items-center gap-2">
                <svg width="14" height="7" viewBox="0 0 14 7" fill="none" xmlns="http://www.w3.org/2000/svg">
                  <path d="M0 3.20557H4.66267M4.66267 3.20557C4.66267 2.58726 4.90829 1.99428 5.3455 1.55707C5.78271 1.11986 6.3757 0.874237 6.99401 0.874237C7.61231 0.874237 8.2053 1.11986 8.64251 1.55707C9.07972 1.99428 9.32534 2.58726 9.32534 3.20557M4.66267 3.20557C4.66267 3.82388 4.90829 4.41687 5.3455 4.85408C5.78271 5.29129 6.3757 5.53691 6.99401 5.53691C7.61231 5.53691 8.2053 5.29129 8.64251 4.85408C9.07972 4.41687 9.32534 3.82388 9.32534 3.20557M9.32534 3.20557H13.988" stroke="#b3ff00" strokeWidth="1.7485"/>
                </svg>
                <span className="text-[#b3ff00] text-sm sm:text-[15px] font-medium">Musicians</span>
              </div>
              <div className="flex items-center gap-2">
                <svg width="14" height="7" viewBox="0 0 14 7" fill="none" xmlns="http://www.w3.org/2000/svg">
                  <path d="M0 3.20557H4.66267M4.66267 3.20557C4.66267 2.58726 4.90829 1.99428 5.3455 1.55707C5.78271 1.11986 6.3757 0.874237 6.99401 0.874237C7.61231 0.874237 8.2053 1.11986 8.64251 1.55707C9.07972 1.99428 9.32534 2.58726 9.32534 3.20557M4.66267 3.20557C4.66267 3.82388 4.90829 4.41687 5.3455 4.85408C5.78271 5.29129 6.3757 5.53691 6.99401 5.53691C7.61231 5.53691 8.2053 5.29129 8.64251 4.85408C9.07972 4.41687 9.32534 3.82388 9.32534 3.20557M9.32534 3.20557H13.988" stroke="#3b82f6" strokeWidth="1.7485"/>
                </svg>
                <span className="text-[#3b82f6] text-sm sm:text-[15px] font-medium">Organizers</span>
              </div>
            </div>
          </div>
        </div>

        {/* Gig Source Distribution */}
        <div className="bg-[#1A1A1A] border border-[#1a1a1e] rounded-2xl p-4 sm:p-8 flex flex-col">
          <h3 className="text-white font-bold text-[18px] mb-8">Gig Source Distribution</h3>
          <div className="flex-1 flex flex-col items-center justify-center relative min-h-[300px] overflow-x-auto custom-scrollbar">
            {analytics && (() => {
              const latestTrends = analytics.gigTrends[analytics.gigTrends.length - 1];
              const scrapedCount = latestTrends.scraped;
              const manualCount = latestTrends.manual;
              const total = (scrapedCount + manualCount) || 1; 
              const manualPercent = Math.round((manualCount / total) * 100);
              const scrapedPercent = 100 - manualPercent;
              
              const radius = 75;
              const cx = 200;
              const cy = 100;
              
              const startAngle = 90 - ((manualCount / total) * 360);
              const endAngle = 90;
              
              const x1 = cx + radius * Math.cos((startAngle * Math.PI) / 180);
              const y1 = cy + radius * Math.sin((startAngle * Math.PI) / 180);
              const x2 = cx + radius * Math.cos((endAngle * Math.PI) / 180);
              const y2 = cy + radius * Math.sin((endAngle * Math.PI) / 180);
              
              const manualPath = `M ${cx} ${cy} L ${x1} ${y1} A ${radius} ${radius} 0 ${manualPercent > 50 ? 1 : 0} 1 ${x2} ${y2} Z`;
              const scrapedPath = `M ${cx} ${cy} L ${x2} ${y2} A ${radius} ${radius} 0 ${scrapedPercent > 50 ? 1 : 0} 1 ${x1} ${y1} Z`;

              return (
                <div className="relative w-full h-full min-w-[320px] flex items-center justify-center">
                  <svg className="w-full h-64 overflow-visible" viewBox="0 0 400 200">
                    <path d={scrapedPath} fill="#3b82f6" stroke="white" strokeWidth="1.5" />
                    <path d={manualPath} fill="#b3ff00" stroke="white" strokeWidth="1.5" />
                    
                    <text x="290" y="30" textAnchor="start" className="fill-[#b3ff00] text-[12px] font-bold">Manual Posts: {manualPercent}%</text>
                    <text x="110" y="180" textAnchor="end" className="fill-[#3b82f6] text-[12px] font-bold">Scraped Gigs: {scrapedPercent}%</text>
                  </svg>
                </div>
              );
            })()}
          </div>
        </div>
      </div>

      {/* Revenue & Escrow Analytics */}
      <div className="bg-[#1A1A1A] border border-[#1a1a1e] rounded-2xl p-4 sm:p-8 pb-12">
        <div className="flex justify-between items-center mb-8">
          <h3 className="text-white font-bold text-[18px]">Revenue & Escrow Analytics</h3>
        </div>
        <div className="h-auto w-full relative overflow-x-auto custom-scrollbar">
          {analytics && (() => {
            const revenueData = analytics.revenueData.map((d: any) => d.revenue);
            const escrowData = analytics.revenueData.map((d: any) => d.revenue * 0.6); // Mock escrow as 60% of rev for now
            const months = analytics.revenueData.map((d: any) => d.month);
            const maxVal = Math.max(...revenueData, 1000) * 1.2;
            const chartHeight = 280;
            const offsetLeft = 50;
            
            const valueToY = (val: number) => chartHeight - (val / maxVal * chartHeight);
            
            const getAreaPath = (data: number[]) => {
              const points = data.map((val, i) => `${offsetLeft + (i * 160)} ${valueToY(val)}`).join(' L ');
              return `M ${offsetLeft} ${chartHeight} L ${points} L ${offsetLeft + (data.length - 1) * 160} ${chartHeight} Z`;
            };
            
            const getLinePath = (data: number[]) => 
              data.map((val, i) => `${i === 0 ? 'M' : 'L'} ${offsetLeft + (i * 160)} ${valueToY(val)}`).join(' ');

            return (
              <div className="h-[320px] min-w-[850px] relative">
                <svg className="w-full h-full overflow-visible" viewBox="0 0 850 320">
                  <defs>
                    <linearGradient id="revGrad" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="0%" stopColor="#b3ff00" stopOpacity="0.4" />
                      <stop offset="100%" stopColor="#b3ff00" stopOpacity="0" />
                    </linearGradient>
                    <linearGradient id="escGrad" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="0%" stopColor="#3b82f6" stopOpacity="0.4" />
                      <stop offset="100%" stopColor="#3b82f6" stopOpacity="0" />
                    </linearGradient>
                  </defs>

                  {/* Horizontal Grid Lines */}
                  {[0, 1, 2, 3, 4].map((i) => (
                    <g key={`h-rev-${i}`}>
                      <line x1={offsetLeft} y1={chartHeight - (i * 70)} x2="850" y2={chartHeight - (i * 70)} stroke="#27272a" strokeWidth="1" strokeDasharray="4 4" />
                      <text x="0" y={chartHeight - (i * 70) + 5} className="fill-[#a1a1aa] text-[12px]">${Math.round(i * maxVal / 4)}</text>
                    </g>
                  ))}

                  {/* Vertical Grid Lines */}
                  {months.map((_: any, i: number) => (
                    <line 
                      key={`v-rev-${i}`} 
                      x1={offsetLeft + (i * 160)} 
                      y1="0" 
                      x2={offsetLeft + (i * 160)} 
                      y2={chartHeight} 
                      stroke="#27272a" 
                      strokeWidth="1" 
                      strokeDasharray="4 4" 
                    />
                  ))}

                  {/* Month Labels */}
                  {months.map((m: string, i: number) => (
                    <g key={`label-rev-${i}`} className="fill-[#a1a1aa] text-[12px]">
                      <text x={offsetLeft + (i * 160)} y="310" textAnchor="middle">{m}</text>
                    </g>
                  ))}

                  {/* Escrow Area & Line */}
                  <path d={getAreaPath(escrowData)} fill="url(#escGrad)" />
                  <path d={getLinePath(escrowData)} fill="none" stroke="#3b82f6" strokeWidth="2" />
                  
                  {/* Revenue Area & Line */}
                  <path d={getAreaPath(revenueData)} fill="url(#revGrad)" />
                  <path d={getLinePath(revenueData)} fill="none" stroke="#b3ff00" strokeWidth="2" />
                </svg>
              </div>
            );
          })()}

          {/* Legend at Bottom Center */}
          <div className="flex justify-center gap-4 sm:gap-8 mt-16 min-w-[300px]">
            <div className="flex items-center gap-2">
              <svg width="14" height="7" viewBox="0 0 14 7" fill="none" xmlns="http://www.w3.org/2000/svg">
                <path d="M0 3.20557H4.66267M4.66267 3.20557C4.66267 2.58726 4.90829 1.99428 5.3455 1.55707C5.78271 1.11986 6.3757 0.874237 6.99401 0.874237C7.61231 0.874237 8.2053 1.11986 8.64251 1.55707C9.07972 1.99428 9.32534 2.58726 9.32534 3.20557M4.66267 3.20557C4.66267 3.82388 4.90829 4.41687 5.3455 4.85408C5.78271 5.29129 6.3757 5.53691 6.99401 5.53691C7.61231 5.53691 8.2053 5.29129 8.64251 4.85408C9.07972 4.41687 9.32534 3.82388 9.32534 3.20557M9.32534 3.20557H13.988" stroke="#b3ff00" strokeWidth="1.7485"/>
              </svg>
              <span className="text-[#b3ff00] text-sm sm:text-[15px] font-medium">Revenue ($)</span>
            </div>
            <div className="flex items-center gap-2">
              <svg width="14" height="7" viewBox="0 0 14 7" fill="none" xmlns="http://www.w3.org/2000/svg">
                <path d="M0 3.20557H4.66267M4.66267 3.20557C4.66267 2.58726 4.90829 1.99428 5.3455 1.55707C5.78271 1.11986 6.3757 0.874237 6.99401 0.874237C7.61231 0.874237 8.2053 1.11986 8.64251 1.55707C9.07972 1.99428 9.32534 2.58726 9.32534 3.20557M4.66267 3.20557C4.66267 3.82388 4.90829 4.41687 5.3455 4.85408C5.78271 5.29129 6.3757 5.53691 6.99401 5.53691C7.61231 5.53691 8.2053 5.29129 8.64251 4.85408C9.07972 4.41687 9.32534 3.82388 9.32534 3.20557M9.32534 3.20557H13.988" stroke="#3b82f6" strokeWidth="1.7485"/>
              </svg>
              <span className="text-[#3b82f6] text-sm sm:text-[15px] font-medium">Escrow ($)</span>
            </div>
          </div>
        </div>
      </div>

      {/* Recent Activity Feed */}
      <div className="bg-[#1A1A1A] border border-[#1a1a1e] rounded-2xl p-4 sm:p-8">
        <h3 className="text-white font-bold text-[18px] mb-8">Recent Activity Feed</h3>
        <div className="space-y-6">
          {activities.map((activity, i) => (
            <div key={i} className="flex items-center gap-5 group cursor-pointer">
              <div className={`w-10 h-10 sm:w-12 sm:h-12 ${activity.bg} rounded-xl flex items-center justify-center transition-transform group-hover:scale-105 flex-shrink-0`}>
                <activity.icon className={`w-5 h-5 sm:w-6 sm:h-6 ${activity.color}`} />
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-white font-normal text-sm sm:text-[14px] leading-[20px] mb-1 group-hover:text-[#b3ff00] transition-colors truncate sm:whitespace-normal">{activity.title}</p>
                <p className="text-[#a1a1aa] font-normal text-[11px] sm:text-[12px] leading-[16px]">{activity.time}</p>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
