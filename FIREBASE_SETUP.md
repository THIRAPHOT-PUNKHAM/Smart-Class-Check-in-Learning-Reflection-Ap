# Firebase Hosting & Firestore Setup Guide

**Smart Class Check-in — Deployment Instructions**

---

## Part A — Firebase Project Setup (One-time)

### Step 1: Create a Firebase Project

1. Go to [https://console.firebase.google.com](https://console.firebase.google.com)
2. Click **"Add project"** → enter project name (e.g. `smart-class-checkin`)
3. Disable Google Analytics (optional for exam) → **Create project**

---

### Step 2: Add Android App to Firebase

1. In your Firebase project → click the **Android icon** (Add app)
2. **Android package name**: find it in `android/app/build.gradle`
   ```
   applicationId "com.example.smart_class_checkin"
   ```
3. Click **"Register app"**
4. **Download `google-services.json`** → place it in:
   ```
   smart_class_checkin/android/app/google-services.json
   ```
5. Follow the on-screen SDK setup steps (they are already handled by the packages)

---

### Step 3: Enable Firestore

1. Firebase Console → **Build → Firestore Database**
2. Click **"Create database"**
3. Choose **"Start in test mode"** (for exam/dev)
4. Select a region → **Enable**

---

### Step 4: Set Firestore Security Rules (Test Mode)

Firestore → **Rules** tab → paste:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true;   // Open for exam — tighten before production!
    }
  }
}
```

Click **Publish**.

---

## Part B — Flutter Firebase Configuration

### Step 5: Update android/build.gradle

Open `android/build.gradle` and confirm the `google-services` plugin is listed:

```groovy
// android/build.gradle
buildscript {
  dependencies {
    classpath 'com.google.gms:google-services:4.4.2'   // add if missing
  }
}
```

### Step 6: Update android/app/build.gradle

At the **bottom** of `android/app/build.gradle`:

```groovy
apply plugin: 'com.google.gms.google-services'   // add if missing
```

---

### Step 7: Add Permission Declarations (Android)

In `android/app/src/main/AndroidManifest.xml` inside `<manifest>`:

```xml
<!-- Location -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>

<!-- Camera (QR Scanner) -->
<uses-permission android:name="android.permission.CAMERA"/>

<!-- Network -->
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
```

---

### Step 8: Run the App

```bash
flutter pub get
flutter run
```

The app will:
- Store data **locally in SQLite** by default
- **Auto-sync to Firestore** when internet is detected

---

## Part C — Firebase Hosting (Flutter Web)

### Step 9: Install Firebase CLI

```bash
npm install -g firebase-tools
firebase login
```

### Step 10: Build Flutter Web

```bash
flutter build web --release
```

Output generated in: `build/web/`

### Step 11: Initialize Firebase Hosting

In the project root (`smart_class_checkin/`):

```bash
firebase init hosting
```

Prompts and answers:
| Prompt | Answer |
|--------|--------|
| Select project | *(your existing project)* |
| Public directory | `build/web` |
| Single-page app? | **Yes** |
| Overwrite `build/web/index.html`? | **No** |

### Step 12: Deploy

```bash
firebase deploy --only hosting
```

After deploy, Firebase prints a public URL:

```
✔ Hosting URL: https://smart-class-checkin.web.app
```

---

## Part D — Firestore Data Structure

The app writes to two top-level collections:

```
Firestore
├── check_ins/
│   └── {sqlite_id}          ← document ID = SQLite row id
│       student_id: "STD001"
│       checkin_time: "2026-03-13T15:30:00"
│       checkin_gps_lat: 13.84521
│       checkin_gps_lng: 100.56730
│       qr_code_checkin: "CS101-2026-03-13"
│       prev_topic: "Widgets"
│       expected_topic: "State management"
│       mood_before: 4
│       synced_at: <server timestamp>
│
└── check_outs/
    └── {sqlite_id}
        checkin_id: 1
        checkout_time: "2026-03-13T17:30:00"
        checkout_gps_lat: 13.84521
        checkout_gps_lng: 100.56730
        qr_code_checkout: "CS101-2026-03-13-END"
        learned_today: "StatefulWidget lifecycle"
        feedback: "Good examples!"
        synced_at: <server timestamp>
```

---

## Quick Troubleshooting

| Problem | Fix |
|---------|-----|
| `google-services.json not found` | Place file at `android/app/google-services.json` |
| Firestore permission denied | Set rules to test mode (see Step 4) |
| GPS not working on emulator | Use a physical device or set mock location |
| Camera doesn't open | Grant camera permission in device settings |
| `flutter build web` fails | Run `flutter pub get` first |
