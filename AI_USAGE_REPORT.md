# AI Usage Report

**Project:** Smart Class Check-in & Learning Reflection App
**Course:** 1305216 Mobile Application Development — Midterm Lab Exam
**Date:** 13 March 2026

---

## 1. AI Tools Used

| Tool | Platform |
|------|----------|
| **Antigravity (Google DeepMind)** | In-editor AI assistant (primary) |

---

## 2. What AI Generated

### ✅ Data Models (`models/`)
- AI generated `CheckInRecord` and `CheckOutRecord` classes  
- Includes `toMap()`, `fromMap()`, and `copyWith()` methods  
- Field names and types derived from the PRD data fields table

### ✅ Service Layer (`services/`)
- **`database_service.dart`** — Full SQLite CRUD with table creation SQL, foreign key constraints, and cascade delete
- **`location_service.dart`** — GPS permission flow, `getCurrentPosition()` wrapper, and custom exception classes
- **`qr_scanner_service.dart`** — Camera permission check, full-screen `QrScanPage` UI with torch/flip controls
- **`firebase_sync_service.dart`** — Connectivity check before every Firestore write, idempotent upsert using SQLite ID as document ID

### ✅ UI Screens (`screens/`)
- **`home_screen.dart`** — Collapsible gradient app bar, session status card loaded from SQLite, enable/disable buttons based on active session
- **`checkin_screen.dart`** — 3-step flow UI (GPS → QR → Form), animated state transitions, emoji mood selector (1–5)
- **`finish_class_screen.dart`** — Session banner, same GPS/QR/form pattern with post-class reflection fields

### ✅ Theme (`theme/app_theme.dart`)
- Dark mode color palette, `CardThemeData`, `InputDecorationTheme`, `ElevatedButtonTheme` tokens

### ✅ Configuration & Documentation
- `pubspec.yaml` dependency additions
- `FIREBASE_SETUP.md` step-by-step guide
- `README.md` project documentation

---

## 3. What I Modified / Implemented Myself

| Area | My Contribution |
|------|-----------------|
| **PRD interpretation** | Studied the exam requirements and defined missing data fields (e.g., added `checkin_id` FK to link check-in and check-out sessions) |
| **Validation logic** | Reviewed and confirmed all 3-step guards: GPS must be captured, QR must be scanned, mood must be selected, and form fields must be non-empty **before** save |
| **Firebase error handling** | Decided on silent-fail strategy so the app works fully offline even if `google-services.json` is not configured |
| **Navigation flow** | Designed `onGenerateRoute` pattern with typed argument passing (`studentId`, `checkinId`) between screens |
| **Session state logic** | Defined the rule: a session is "active" when a `CheckInRecord` exists with **no matching `CheckOutRecord`** |
| **Bug fixes** | Fixed `CardTheme` → `CardThemeData` type error caught by `flutter analyze`; removed redundant imports |
| **AndroidManifest.xml** | Manually added Location, Camera, and Internet permission declarations |
| **`google-services.json` setup** | Downloaded and placed the Firebase config file manually |

---

## 4. Summary

> AI was used to scaffold the full Flutter project structure — data models, service classes, and UI screens — based on the PRD requirements I provided.
>
> I reviewed every generated file, corrected type errors from `flutter analyze`, defined the session-linking logic (FK from check-out to check-in), designed the offline-first Firebase sync strategy, and set up the Android and Firebase configuration manually.
>
> The AI accelerated boilerplate and UI code generation significantly, but the system design decisions, data flow, and final code review were done by me.
