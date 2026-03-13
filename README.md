# Smart Class Check-in & Learning Reflection App

> Midterm Lab Exam — 1305216 Mobile Application Development
> Platform: Flutter (Android + Web)

---

## 📌 Project Overview

A mobile application that allows students to **check in to class** and **reflect on their learning experience**. The system verifies physical presence through GPS location and QR code scanning, and captures pre/post-class reflection data.

### Key Features
- ✅ One-tap **Check-in** with automatic GPS capture
- ✅ **QR Code scanning** to confirm classroom identity
- ✅ **Pre-class reflection** (previous topic, expected topic, mood scale 1–5)
- ✅ **Finish Class** flow with end-of-session QR scan and GPS
- ✅ **Post-class reflection** (what I learned, feedback)
- ✅ Local persistence with **SQLite** (sqflite)
- ✅ Background sync to **Firebase Firestore** when online

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter (Dart) |
| Local Storage | sqflite (SQLite) |
| GPS / Location | geolocator |
| QR Scanning | mobile_scanner |
| Cloud Sync | Firebase Firestore |
| Hosting | Firebase Hosting (Flutter Web) |

---

## 📁 Project Structure

```
lib/
├── main.dart                       # App entry point & routing
├── app.dart                        # Barrel exports
├── theme/
│   └── app_theme.dart              # Global theme (dark mode)
├── models/
│   ├── check_in_record.dart        # CheckInRecord data model
│   └── check_out_record.dart       # CheckOutRecord data model
├── services/
│   ├── database_service.dart       # SQLite CRUD
│   ├── location_service.dart       # GPS & permissions
│   ├── qr_scanner_service.dart     # Camera & QR scan
│   └── firebase_sync_service.dart  # Firestore sync
└── screens/
    ├── home_screen.dart            # Dashboard & navigation
    ├── checkin_screen.dart         # Check-in flow
    └── finish_class_screen.dart    # Finish class flow
```

---

## ⚙️ Setup & Installation

### Prerequisites

| Tool | Minimum Version |
|---|---|
| Flutter SDK | 3.x |
| Dart SDK | 3.x |
| Android Studio | Hedgehog or later |
| Java JDK | 17+ |

### 1. Clone the repository

```bash
git clone https://github.com/<your-username>/smart_class_checkin.git
cd smart_class_checkin
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Enable Windows Developer Mode (Windows only)

Flutter plugins require symlink support on Windows:

```
Settings → Privacy & Security → For Developers → Developer Mode → ON
```

Or run: `start ms-settings:developers`

---

## ▶️ How to Run

### Run on Android (physical device or emulator)

```bash
flutter run
```

> Make sure the device has **Location** and **Camera** permissions enabled.

### Run on Chrome (Web)

```bash
flutter run -d chrome
```

> Note: GPS and camera access depend on browser permissions.

---

## 🔥 Firebase Configuration

### Step 1 — Create Firebase Project

1. Go to [https://console.firebase.google.com](https://console.firebase.google.com)
2. Create a new project → Enable **Firestore Database** in test mode

### Step 2 — Add Android App

1. Register your app with package name `com.example.smart_class_checkin`
2. Download **`google-services.json`**
3. Place it at: `android/app/google-services.json`

### Step 3 — Add Permissions to AndroidManifest.xml

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
```

### Step 4 — Deploy to Firebase Hosting (Web)

```bash
flutter build web --release
firebase login
firebase init hosting     # public dir: build/web  |  SPA: yes
firebase deploy --only hosting
```

> See [`FIREBASE_SETUP.md`](./FIREBASE_SETUP.md) for the full step-by-step guide.

---

## 📡 Firestore Data Structure

```
check_ins/
  └── {id}  →  student_id, checkin_time, gps_lat/lng, qr_code, prev_topic, expected_topic, mood_before

check_outs/
  └── {id}  →  checkin_id (FK), checkout_time, gps_lat/lng, qr_code, learned_today, feedback
```

---

## 📋 Permissions Required

| Permission | Purpose |
|---|---|
| Location (Fine) | GPS capture at check-in and check-out |
| Camera | QR Code scanning |
| Internet | Firebase Firestore sync |

---

## 🔒 Academic Integrity Notice

This project was developed individually for **Midterm Lab Exam — 1305216**.
AI tools were used as assistance only. See [`AI_USAGE_REPORT.md`](./AI_USAGE_REPORT.md) for details.

---

*Course: 1305216 Mobile Application Development — Midterm Lab Exam, 13 March 2026*
