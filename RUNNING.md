# Running the Project

This document provides the commands necessary to run the various components of the OnlyGigz project.

## 1. Firebase Emulator Suite
Start the local Firebase emulators for development:
```bash
npx -y firebase-tools emulators:start --project demo-onlygigz
```

## 2. Backend (FastAPI)
Run from the project root (`onlygigz`):
```bash
# 1. Create a Python virtual environment (if not created yet)
python3 -m venv .venv

# 2. Activate the virtual environment
source .venv/bin/activate

# 3. Install requirements
pip install -r backend/requirements.txt

# 4. Run the backend server
python3 -m uvicorn backend.main:app --reload
```

## 3. Admin Portal (Next.js)
Run the web-based admin dashboard:
```bash
cd web/admin_portal
npm install
npm run dev
```

## 4. Mobile Applications (Flutter)
You can run the mobile apps using the Flutter CLI. Ensure you have an emulator running or a device connected.

### Musician App
```bash
cd apps/musician
flutter run
```

### Organizer App
```bash
cd apps/organizer
flutter run
```

## 5. Scraper
To run the gig scraper:
```bash
cd scraper
pip install -r requirements.txt
python main.py
```
