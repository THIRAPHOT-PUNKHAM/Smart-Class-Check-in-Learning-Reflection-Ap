# Product Requirement Document (PRD)

## Smart Class Check-in & Learning Reflection App

**Course:** 1305216 Mobile Application Development
**Date:** 13 March 2026
**Type:** Midterm Lab Exam — Individual
**Platform:** Flutter (Mobile + Web)

---

## 1. Problem Statement

Universities struggle to verify whether students are physically present during class and actively participating. Traditional paper roll calls are tedious, easily manipulated, and provide no insight into student engagement or learning quality. A digital solution is needed that combines location verification, session confirmation, and structured learning reflection in a single lightweight mobile app.

---

## 2. Target Users

| User | Description |
|------|-------------|
| **Students** | Primary users who check in, scan QR, and fill reflections |
| **Instructors** | Secondary users (future scope) who generate QR codes and view attendance data |

---

## 3. Feature List

### 3.1 Class Check-in (Before Class)
- One-tap **Check-in** button
- Automatic **GPS location** capture and timestamp recording
- **QR Code scanning** to confirm classroom identity
- Pre-class reflection form:
  - Previous class topic (short text)
  - Expected topic for today (short text)
  - Mood before class (1–5 emoji scale)

### 3.2 Class Completion (After Class)
- One-tap **Finish Class** button
- **QR Code scan again** (end-of-session confirmation)
- **GPS location** re-captured at finish time
- Post-class reflection form:
  - What I learned today (short text)
  - Feedback about class/instructor (short text)

### 3.3 Data Storage
- All check-in and check-out data saved locally (SQLite / localStorage for MVP)
- Optional: sync to Firebase Firestore

### 3.4 Deployment
- Flutter Web version deployed via **Firebase Hosting**
- Accessible public URL

---

## 4. User Flow

```
[App Launch]
     │
     ▼
[Home Screen]
  ├── [Check-in Button]
  │       │
  │       ▼
  │   [GPS Captured + Timestamp]
  │       │
  │       ▼
  │   [Scan QR Code]
  │       │
  │       ▼
  │   [Pre-class Reflection Form]
  │   - Previous topic
  │   - Expected topic today
  │   - Mood (1–5)
  │       │
  │       ▼
  │   [Data Saved → Home Screen]
  │
  └── [Finish Class Button]
          │
          ▼
      [Scan QR Code Again]
          │
          ▼
      [GPS Re-captured]
          │
          ▼
      [Post-class Reflection Form]
      - What I learned
      - Feedback
          │
          ▼
      [Data Saved → Home Screen]
```

---

## 5. Data Fields

### Check-in Record

| Field | Type | Description |
|-------|------|-------------|
| `student_id` | String | Unique student identifier |
| `checkin_time` | DateTime | Timestamp when check-in pressed |
| `checkin_gps_lat` | Double | Latitude at check-in |
| `checkin_gps_lng` | Double | Longitude at check-in |
| `qr_code_checkin` | String | QR code value scanned at check-in |
| `prev_topic` | String | Topic covered in previous class |
| `expected_topic` | String | Topic expected today |
| `mood_before` | Int (1–5) | Mood score before class |

### Check-out Record

| Field | Type | Description |
|-------|------|-------------|
| `checkout_time` | DateTime | Timestamp when Finish Class pressed |
| `checkout_gps_lat` | Double | Latitude at check-out |
| `checkout_gps_lng` | Double | Longitude at check-out |
| `qr_code_checkout` | String | QR code value scanned at check-out |
| `learned_today` | String | What the student learned |
| `feedback` | String | Feedback on class/instructor |

---

## 6. Mood Scale Reference

| Score | Emoji | Label |
|-------|-------|-------|
| 1 | 😡 | Very Negative |
| 2 | 🙁 | Negative |
| 3 | 😐 | Neutral |
| 4 | 🙂 | Positive |
| 5 | 😄 | Very Positive |

---

## 7. Tech Stack

| Layer | Technology |
|-------|-----------|
| **Frontend / Mobile** | Flutter (Dart) |
| **QR Scanning** | `mobile_scanner` or `qr_code_scanner` package |
| **GPS / Location** | `geolocator` package |
| **Local Storage (MVP)** | `sqflite` (SQLite) or `shared_preferences` |
| **Cloud Storage** | Firebase Firestore (optional for MVP) |
| **Hosting / Deployment** | Firebase Hosting (Flutter Web) |
| **Authentication** | Firebase Auth (optional — student ID input for MVP) |

---

## 8. Screens (Minimum)

| # | Screen | Description |
|---|--------|-------------|
| 1 | **Home Screen** | Shows check-in / finish class buttons and current session status |
| 2 | **Check-in Screen** | QR scan + GPS capture + pre-class reflection form |
| 3 | **Finish Class Screen** | QR scan + GPS capture + post-class reflection form |

---

## 9. Non-Functional Requirements

- App must request **location permissions** at runtime
- GPS must be obtained before form submission
- QR scan must succeed before proceeding
- All form fields are **required** (validation enforced)
- Data must persist across app sessions (local storage)

---

## 10. Deliverables Summary

| # | Deliverable | Format |
|---|------------|--------|
| 1 | This PRD | `.md` file |
| 2 | Flutter source code | GitHub Repository |
| 3 | Firebase deployment | Public URL |
| 4 | README | In repository |
| 5 | AI Usage Report | Short description in README or separate file |

---

*Document prepared for Midterm Lab Exam — 1305216 Mobile Application Development*
