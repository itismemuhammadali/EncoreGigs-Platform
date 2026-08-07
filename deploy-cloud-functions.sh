#!/bin/bash

# Firebase Cloud Functions Deployment Script for OnlyGigz OTP Email
# This script helps deploy the OTP email Cloud Functions

set -e

echo "🚀 OnlyGigz Cloud Functions Deployment"
echo "======================================"
echo ""

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI not found. Install it first:"
    echo "   npm install -g firebase-tools"
    exit 1
fi

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js not found. Install it first:"
    echo "   https://nodejs.org/"
    exit 1
fi

echo "✅ Prerequisites found"
echo ""

# Navigate to functions directory
cd functions

# Check if .env.local exists
if [ ! -f ".env.local" ]; then
    echo "⚠️  .env.local not found"
    echo ""
    echo "Follow these steps to set up Gmail credentials:"
    echo ""
    echo "1. Go to: https://myaccount.google.com/apppasswords"
    echo "2. Generate a Gmail App Password"
    echo "3. Create functions/.env.local with:"
    echo ""
    echo "   GMAIL_EMAIL=your-email@gmail.com"
    echo "   GMAIL_APP_PASSWORD=xxxx xxxx xxxx xxxx"
    echo ""
    echo "Then run this script again."
    exit 1
fi

echo "✅ .env.local found"
echo ""

# Install dependencies
echo "📦 Installing dependencies..."
npm install
echo "✅ Dependencies installed"
echo ""

# Check Firebase login
echo "🔐 Checking Firebase authentication..."
if ! firebase projects:list &> /dev/null; then
    echo "❌ Not logged in to Firebase"
    echo "   Run: firebase login"
    exit 1
fi
echo "✅ Firebase authenticated"
echo ""

# Get project ID
PROJECT_ID=$(firebase projects:list 2>/dev/null | grep -oP '(?<=\*\s)\S+' | head -1)
if [ -z "$PROJECT_ID" ]; then
    echo "❌ Could not determine Firebase project ID"
    echo "   Make sure you have a default project set"
    exit 1
fi
echo "📍 Project: $PROJECT_ID"
echo ""

# Deploy functions
echo "🚀 Deploying Cloud Functions..."
firebase deploy --only functions

echo ""
echo "======================================"
echo "✅ Deployment Complete!"
echo "======================================"
echo ""
echo "Next steps:"
echo "1. Verify functions deployed: firebase functions:log"
echo "2. Test OTP sending:"
echo "   curl -X POST http://localhost:8000/auth/send-email-otp \\"
echo "     -H 'Content-Type: application/json' \\"
echo "     -d '{\"email\": \"test@example.com\", \"uid\": \"user123\"}'"
echo ""
echo "For more information, see: CLOUD_FUNCTIONS_OTP_SETUP.md"
