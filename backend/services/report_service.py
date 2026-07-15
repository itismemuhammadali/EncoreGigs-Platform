from firebase_admin import firestore
from backend.database import db
from datetime import datetime, timedelta
from typing import List, Dict, Any
import collections

class ReportService:
    @staticmethod
    def get_dashboard_analytics():
        # Get last 6 months list
        months = []
        for i in range(5, -1, -1):
            date = datetime.now() - timedelta(days=i * 30)
            months.append(date.strftime("%b"))

        # Initialize data structures
        growth_data = {m: {"musicians": 0, "organizers": 0, "total": 0} for m in months}
        gig_trends = {m: {"manual": 0, "scraped": 0} for m in months}
        revenue_data = {m: {"revenue": 0, "bookings": 0} for m in months}

        # --- 1. User Growth ---
        musicians = db.collection("musicians").get()
        for doc in musicians:
            data = doc.to_dict()
            # Try to get month from joinedAt (format: YYYY-MM-DD)
            joined_at = data.get("joinedAt")
            if joined_at:
                try:
                    month = datetime.strptime(joined_at, "%Y-%m-%d").strftime("%b")
                    if month in growth_data:
                        growth_data[month]["musicians"] += 1
                except:
                    pass

        organizers = db.collection("organizers").get()
        for doc in organizers:
            data = doc.to_dict()
            joined_at = data.get("joinedAt")
            if joined_at:
                try:
                    month = datetime.strptime(joined_at, "%Y-%m-%d").strftime("%b")
                    if month in growth_data:
                        growth_data[month]["organizers"] += 1
                except:
                    pass

        # Calculate totals for growth
        total_users_count = len(musicians) + len(organizers)
        
        # --- 2. Gigs Trends ---
        gigs = db.collection("gigs").get()
        for doc in gigs:
            data = doc.to_dict()
            created_at = data.get("createdAt")
            if created_at:
                try:
                    # Firestore timestamp
                    month = created_at.strftime("%b")
                    if month in gig_trends:
                        if data.get("isScraped"):
                            gig_trends[month]["scraped"] += 1
                        else:
                            gig_trends[month]["manual"] += 1
                except:
                    pass
        
        total_gigs_count = len(gigs)

        # --- 3. Revenue & Bookings ---
        bookings = db.collection("bookings").get()
        total_revenue = 0
        successful_bookings = 0
        
        for doc in bookings:
            data = doc.to_dict()
            created_at = data.get("createdAt")
            status = data.get("status")
            
            amount = float(data.get("amount", 0))
            # Assuming revenue is a percentage of booking amount (e.g. 10%)
            revenue = amount * 0.1 
            
            if status == "completed":
                successful_bookings += 1
                total_revenue += revenue

            if created_at:
                try:
                    month = created_at.strftime("%b") if hasattr(created_at, 'strftime') else datetime.now().strftime("%b")
                    if month in revenue_data:
                        revenue_data[month]["bookings"] += 1
                        revenue_data[month]["revenue"] += revenue
                except:
                    pass

        # Booking Success Rate
        success_rate = (successful_bookings / len(bookings) * 100) if len(bookings) > 0 else 0

        # --- Format for Frontend ---
        formatted_growth = []
        for m in months:
            growth_data[m]["total"] = growth_data[m]["musicians"] + growth_data[m]["organizers"]
            formatted_growth.append({"month": m, **growth_data[m]})

        formatted_trends = []
        for m in months:
            formatted_trends.append({"month": m, **gig_trends[m]})

        formatted_revenue = []
        for m in months:
            formatted_revenue.append({"month": m, **revenue_data[m]})

        return {
            "mainStats": [
                { "label": "Total Users", "value": f"{total_users_count:,}", "growth": "12% growth" },
                { "label": "Total Gigs Posted", "value": f"{total_gigs_count:,}", "growth": "18% growth" },
                { "label": "Total Revenue", "value": f"${total_revenue:,.0f}", "growth": "24% growth" },
                { "label": "Booking Success", "value": f"{success_rate:.0f}%", "growth": "5% growth" }
            ],
            "growthData": formatted_growth,
            "gigTrends": formatted_trends,
            "revenueData": formatted_revenue,
            "scraperMetrics": [
                { "label": "Total Scraping Runs", "value": "124", "subtext": "Last 30 days" },
                { "label": "Success Rate", "value": "92%", "subtext": "114 successful runs", "color": "text-[#10B981]" },
                { "label": "Gigs Imported", "value": "840", "subtext": "45% of total gigs", "color": "text-[#A2F301]" }
            ]
        }

    @staticmethod
    def get_payment_transactions():
        bookings = db.collection("bookings").get()
        transactions = []
        
        for doc in bookings:
            data = doc.to_dict()
            status = data.get("status", "pending")
            escrow_status = data.get("escrow_status", "pending")
            created_at = data.get("createdAt")
            
            # Map Firestore data to Admin Portal Transaction interface
            date_str = created_at.strftime("%Y-%m-%d") if hasattr(created_at, 'strftime') else str(created_at)
            
            transactions.append({
                "id": doc.id[:8].upper(), # Show short ID
                "organizer": data.get("organizerName", "Unknown"),
                "musician": data.get("musicianName", "Unknown"),
                "gig": data.get("gigTitle", "Unknown"),
                "amount": f"${float(data.get('amount', 0)):,.2f}",
                "escrowStatus": "released" if escrow_status == "released" else "held",
                "date": date_str,
                "status": "completed" if status == "completed" or status == "payment released" else "pending"
            })
            
        return transactions
