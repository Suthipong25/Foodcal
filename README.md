# Foodcal

แอป Flutter สำหรับติดตามอาหาร น้ำดื่ม การออกกำลังกาย และเป้าหมายสุขภาพรายวัน พร้อมฟีเจอร์ AI ช่วยประมาณแคลอรี่และ AI Coach

เอกสารนี้เขียนสำหรับ **นักพัฒนาที่มาทำต่อ** — ครอบคลุมสิ่งที่ต้องติดตั้ง วิธีรันแอป และภาพรวมว่าระบบทำงานอย่างไร

---

## สารบัญ

1. [Tech Stack](#tech-stack)
2. [สิ่งที่ต้องติดตั้ง](#สิ่งที่ต้องติดตั้ง)
3. [Setup โปรเจกต์ครั้งแรก](#setup-โปรเจกต์ครั้งแรก)
4. [รันแอปและเทส](#รันแอปและเทส)
5. [แอปทำงานอย่างไร](#แอปทำงานอย่างไร)
6. [โครงสร้างโปรเจกต์](#โครงสร้างโปรเจกต์)
7. [Firebase และ Cloud Functions](#firebase-และ-cloud-functions)
8. [CI/CD](#cicd)
9. [Build Release (Android)](#build-release-android)
10. [เอกสารอ้างอิงเพิ่มเติม](#เอกสารอ้างอิงเพิ่มเติม)
11. [ปัญหาที่พบบ่อย](#ปัญหาที่พบบ่อย)

---

## Tech Stack

| ชั้น | เทคโนโลยี |
|------|-----------|
| Frontend | Flutter (Dart SDK `^3.5.3`) |
| State | Provider |
| Backend | Firebase Auth, Cloud Firestore, Firebase Storage |
| Serverless | Cloud Functions (Node.js 20) |
| AI | Google Gemini API |
| Charts / UI | fl_chart, lucide_icons, google_fonts |

---

## สิ่งที่ต้องติดตั้ง

### จำเป็น

- **Flutter SDK** (stable channel) — [https://docs.flutter.dev/get-started/install](https://docs.flutter.dev/get-started/install)
- **Git**
- **Android Studio** หรือ **VS Code** + Flutter extension
- สำหรับ Android: Android SDK + emulator/device
- สำหรับ iOS (macOS เท่านั้น): Xcode + CocoaPods

### สำหรับ Firebase

- **Firebase CLI**: `npm install -g firebase-tools`
- สิทธิ์เข้าถึง Firebase project `foodcal-b63fc` (หรือ project ที่ทีมใช้จริง)
- ไฟล์ config จาก Firebase Console (ดูด้านล่าง — **ไม่ commit ขึ้น Git**)

### สำหรับ AI (ฟีเจอร์ประมาณแคลอรี่ / AI Coach)

- **Gemini API Key** จาก [Google AI Studio](https://aistudio.google.com/)

---

## Setup โปรเจกต์ครั้งแรก

### 1. Clone และติดตั้ง dependencies

```bash
git clone <repo-url>
cd Foodcal
flutter pub get
```

### 2. ไฟล์ Firebase (ต้องมีก่อนรัน)

ไฟล์เหล่านี้อยู่ใน `.gitignore` — ต้องขอจากทีมหรือดาวน์โหลดจาก Firebase Console

| ไฟล์ | ตำแหน่ง |
|------|---------|
| `google-services.json` | `android/app/google-services.json` |
| `GoogleService-Info.plist` | `ios/Runner/GoogleService-Info.plist` |

Config ฝั่ง Dart ถูก generate ไว้แล้วที่ `lib/firebase_options.dart` (project id: `foodcal-b63fc`)

### 3. Environment variables

สร้างไฟล์ `assets/.env` (อย่า commit):

```env
GEMINI_API_KEY=your_gemini_api_key_here
```

แอปโหลดไฟล์นี้ตอน startup ใน `lib/main.dart` ผ่าน `flutter_dotenv`

**ทางเลือก:** ส่ง key ผ่าน build flag แทนได้

```bash
flutter run --dart-define=GEMINI_API_KEY=your_key_here
```

ถ้าไม่มี key ฟีเจอร์ต่อไปนี้จะใช้งานไม่ได้หรือจำกัด:

- ค้นหาแคลอรี่จากชื่ออาหาร (AI fallback)
- วิเคราะห์อาหารจากรูปภาพ
- AI Coach

เมนูไทยที่รู้จัก (เช่น กะเพรา, ข้าวผัด) ยังประมาณได้จาก baseline ใน `NutritionService` แม้ไม่มี API key

### 4. Firebase Authentication

เปิด provider ใน Firebase Console:

- Email/Password
- Google Sign-In

**Google Sign-In เพิ่มเติม:**

- **Android:** ใส่ SHA-1 / SHA-256 ของ keystore ใน Firebase Console
- **iOS:** ตั้ง URL Scheme จาก `REVERSED_CLIENT_ID` ใน `GoogleService-Info.plist`
- **Web:** ตรวจ `authDomain` ให้ตรงกับ `firebase_options.dart`

### 5. (Optional) Firebase CLI login

```bash
firebase login
firebase use foodcal-b63fc
```

---

## รันแอปและเทส

```bash
# ตรวจว่า environment พร้อม
flutter doctor

# รันแอป (เลือก device/emulator)
flutter run

# วิเคราะห์โค้ด
flutter analyze

# รัน unit/widget tests ทั้งหมด
flutter test

# รันเฉพาะ nutrition tests
flutter test test/nutrition_service_test.dart
```

---

## แอปทำงานอย่างไร

### Flow เริ่มต้น

```
main.dart
  → โหลด assets/.env
  → Firebase.initializeApp()
  → AuthWrapper (StreamBuilder จาก Firebase Auth)
       ├─ ไม่ login → LoginScreen / RegisterScreen
       └─ login แล้ว → MainScreen
```

### หน้าหลัก (MainScreen)

Bottom navigation 4 แท็บ:

| แท็บ | ไฟล์ | หน้าที่ |
|------|------|--------|
| หน้าแรก | `home_screen.dart` | Dashboard แคลอรี่วันนี้, กราฟ 7 วัน, streak |
| บันทึก | `tracking_screen.dart` | บันทึกอาหาร, น้ำ, สแกนรูป, ค้นหาแคลอรี่ |
| เนื้อหา | `content_screen.dart` | บทความสุขภาพ + วิดีโอ workout |
| โปรไฟล์ | `profile_screen.dart` | แก้ไขข้อมูลส่วนตัว, เป้าหมาย, รูปโปรไฟล์ |

**ผู้ใช้ใหม่:** ถ้ายังไม่มีโปรไฟล์ใน Firestore → ไป `onboarding_screen.dart` เพื่อกรอกข้อมูลร่างกายและคำนวณเป้าแคลอรี่

**Admin:** ถ้า `users/{uid}.role == "admin"` → เข้า `admin_screen.dart` โดยตรง

### การคำนวณเป้าหมายสุขภาพ

Logic อยู่ใน `lib/utils/health_profile_stats.dart`:

- คำนวณ BMR → TDEE จาก activity level
- ปรับตาม goal (ลดน้ำหนัก / รักษา / เพิ่มกล้ามเนื้อ)
- ก distrib macros (protein, fat, carbs)

### การประมาณแคลอรี่ (สำคัญ)

หน้า Tracking เรียก `NutritionService` — **ไม่ใช่** `AIService` โดยตรง

```
NutritionService.lookupFood(ชื่ออาหาร)
  1. Thai baseline (_estimateThaiFoodBaseline)     ← เมนูไทยที่รู้จัก เช่น กะเพรา, ข้าวผัด
  2. FoodDatabaseService (Open Food Facts + Firestore cache)
  3. Gemini AI estimate (fallback)
  4. clamp ถ้า AI ให้ค่าสูงเกิน baseline มากกว่า ~30%
```

```
NutritionService.analyzeImage(รูป)
  → Gemini Vision + Thai food prompt
  → clamp ด้วย baseline ถ้ามี
```

**AI Coach** ใช้ `AIService.askCoach()` แยกต่างหาก (เรียก Gemini จาก client)

> **หมายเหตุด้านสถาปัตยกรรม:** โฟลเดอร์ `functions/` มี Cloud Functions สำหรับ `estimateFood`, `analyzeFoodImage`, `askCoach` อยู่แล้ว แต่ **แอป Flutter ปัจจุบันยังเรียก Gemini จาก client** ผ่าน `NutritionService` / `AIService` โดยตรง ไม่ได้เรียก functions เหล่านี้ ถ้าจะย้าย key ไปฝั่ง server ให้ดู `docs/AI_BACKEND_SETUP.md` เป็นทิศทาง (เอกสารนั้นอธิบายแนว backend proxy — ยังไม่ได้ wire เข้าแอปเต็มรูปแบบ)

### การบันทึกข้อมูล

`FirestoreService` เป็นชั้นกลางอ่าน/เขียน Firestore:

| การกระทำ | วิธีเก็บ |
|----------|----------|
| บันทึกอาหาร | Transaction ที่ `users/{uid}/daily_logs/{dateKey}` |
| บันทึกน้ำ | อัปเดต `waterGlasses` ใน daily log |
| Workout | `workout_sessions` + อัปเดต `caloriesOut` |
| โปรไฟล์ | `users/{uid}` |
| อาหารที่สร้างเอง | `users/{uid}/custom_foods` |
| น้ำหนัก | `users/{uid}/weight_logs` |
| Feedback | collection `feedback` |

**Timezone:** ใช้เวลาไทย (UTC+7) สำหรับ `dateKey` ผ่าน `DateTimeUtils` / `AppConfig.bangkokUtcOffsetHours`

**Admin-only operations** เรียก Cloud Functions:

- `setAdminRole`
- `deleteUserAccount`

### โครงสร้างข้อมูล Firestore (ย่อ)

```
users/{uid}
  ├── name, gender, height, weight, goal, targetCalories, streak, role, ...
  ├── daily_logs/{YYYY-MM-DD}
  │     ├── caloriesIn, caloriesOut, protein, carbs, fat, waterGlasses
  │     ├── foods: [FoodItem]
  │     └── workouts: [WorkoutItem]
  ├── custom_foods/{id}
  ├── weight_logs/{id}
  └── workout_sessions/{id}

food_cache/{normalized_name}     ← cache จาก Open Food Facts (TTL 30 วัน)
workout_videos/{id}              ← วิดีโอ workout
feedback/{id}                    ← feedback จากผู้ใช้
```

Security rules อยู่ที่ `firestore.rules` และ `storage.rules`

---

## โครงสร้างโปรเจกต์

```
Foodcal/
├── lib/
│   ├── main.dart                 # Entry point
│   ├── main_screen.dart          # Bottom nav + routing หลัง login
│   ├── models/                   # Data models
│   ├── screens/                  # UI แต่ละหน้า
│   ├── services/                 # Business logic / API
│   │   ├── auth_service.dart
│   │   ├── firestore_service.dart
│   │   ├── nutrition_service.dart   ← ประมาณแคลอรี่ (หลัก)
│   │   ├── ai_service.dart          ← AI Coach
│   │   ├── food_database_service.dart
│   │   └── storage_service.dart
│   ├── widgets/                  # UI components ใช้ซ้ำ
│   ├── utils/                    # Helpers, validators
│   └── constants/                # AppConfig, enums
├── test/                         # Unit / widget tests
├── functions/                    # Firebase Cloud Functions (Node.js)
├── docs/                         # เอกสารระบบ + diagrams
├── assets/.env                   # Secret (local only, ไม่ commit)
├── firebase.json
├── firestore.rules
└── storage.rules
```

รายละเอียดไฟล์แต่ละตัว → ดู `PROJECT_STRUCTURE.md`

---

## Firebase และ Cloud Functions

### Deploy rules

```bash
firebase deploy --only firestore:rules
firebase deploy --only storage:rules
```

### Deploy Cloud Functions

```bash
cd functions
npm install
cd ..
firebase deploy --only functions
```

Functions ใช้ secret `GEMINI_API_KEY` (ตั้งผ่าน Firebase CLI):

```bash
firebase functions:secrets:set GEMINI_API_KEY
```

---

## CI/CD

GitHub Actions (`.github/workflows/flutter.yml`) รันเมื่อ push/PR ไป `main`:

1. `flutter pub get`
2. `flutter analyze`
3. `flutter test`
4. Deploy Firestore + Storage rules

**Secrets ที่ต้องตั้งใน GitHub Repository:**

| Secret | 用途 |
|--------|------|
| `FIREBASE_PROJECT` | Project ID |
| `FIREBASE_TOKEN` | Token จาก `firebase login:ci` |

---

## Build Release (Android)

1. สร้าง keystore:

```bash
keytool -genkey -v -keystore release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias my-alias
```

2. สร้าง `android/key.properties` (ไม่ commit):

```properties
storePassword=your_password
keyPassword=your_password
keyAlias=my-alias
storeFile=../release.jks
```

3. Build:

```bash
flutter build appbundle --release
```

---

## เอกสารอ้างอิงเพิ่มเติม

| ไฟล์ | เนื้อหา |
|------|---------|
| `PROJECT_STRUCTURE.md` | อธิบายไฟล์ใน `lib/` ทีละไฟล์ |
| `docs/SYSTEM_ANALYSIS_TH.md` | Data flow, use case, วิเคราะห์ระบบ |
| `docs/AI_BACKEND_SETUP.md` | แนวทางย้าย AI ไป backend (legacy/planned) |
| `docs/diagrams/` | ERD, use case, data flow diagrams |

---

## ปัญหาที่พบบ่อย

### แอปขึ้น "เกิดข้อผิดพลาดในการเริ่มต้นระบบ"

- ตรวจว่ามี `android/app/google-services.json`
- รัน `flutter clean && flutter pub get`

### ฟีเจอร์ AI ไม่ทำงาน

- ตรวจ `assets/.env` มี `GEMINI_API_KEY=...`
- ตรวจว่า `pubspec.yaml` มี `assets/.env` ใน `flutter.assets`
- ดู log ใน console (`AppLogger`)

### แคลอรี่อาหารไทยสูง/ต่ำผิดปกติ

- ดู flow ใน `NutritionService.lookupFood()`
- เมนูไทยที่รู้จักใช้ `_estimateThaiFoodBaseline()` ก่อน AI
- แก้ค่า baseline หรือ prompt ใน `_thaiFoodBaseline` ที่ `lib/services/nutrition_service.dart`
- มี tests ใน `test/nutrition_service_test.dart`

### Google Sign-In ล้มเหลว (Android)

- ใส่ SHA-1 debug/release keystore ใน Firebase Console
- ดาวน์โหลด `google-services.json` ใหม่

### `flutter` command not found

- ติดตั้ง Flutter SDK แล้วเพิ่ม `flutter/bin` ใน PATH
- รัน `flutter doctor` ตรวจสภาพ environment

---

## Quick checklist สำหรับ dev ใหม่

- [ ] ติดตั้ง Flutter SDK + รัน `flutter doctor` ผ่าน
- [ ] `flutter pub get`
- [ ] วาง `google-services.json` (และ `GoogleService-Info.plist` ถ้าทำ iOS)
- [ ] สร้าง `assets/.env` พร้อม `GEMINI_API_KEY`
- [ ] เปิด Firebase Auth (Email + Google)
- [ ] `flutter run` ทดสอบ login + บันทึกอาหาร
- [ ] `flutter test` ผ่านก่อน push
