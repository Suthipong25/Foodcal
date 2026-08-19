# Foodcal

Foodcal คือแอป Flutter สำหรับช่วยผู้ใช้ดูแลสุขภาพรายวันในที่เดียว: บันทึกอาหารและน้ำ, ติดตามแคลอรี่/สารอาหาร, ดูวิดีโอออกกำลังกาย, เก็บน้ำหนัก, และคุยกับ AI Coach เพื่อขอคำแนะนำแบบสั้น ๆ เป็นภาษาไทย

เอกสารนี้เป็นคู่มือสำหรับคนที่เพิ่งเปิดโปรเจกต์ครั้งแรก ให้เห็นภาพรวมการทำงาน วิธีติดตั้ง วิธีตั้งค่า และวิธีรันแอปจนใช้งานได้

---

## สารบัญ

1. [ฟีเจอร์หลัก](#ฟีเจอร์หลัก)
2. [Tech Stack](#tech-stack)
3. [สิ่งที่ต้องติดตั้ง](#สิ่งที่ต้องติดตั้ง)
4. [ติดตั้งโปรเจกต์](#ติดตั้งโปรเจกต์)
5. [ตั้งค่า Firebase](#ตั้งค่า-firebase)
6. [ตั้งค่า AI](#ตั้งค่า-ai)
7. [รันแอป](#รันแอป)
8. [ทดสอบและตรวจโค้ด](#ทดสอบและตรวจโค้ด)
9. [ภาพรวมการทำงาน](#ภาพรวมการทำงาน)
10. [โครงสร้างโปรเจกต์](#โครงสร้างโปรเจกต์)
11. [Cloud Functions และ Deploy](#cloud-functions-และ-deploy)
12. [Build Release](#build-release)
13. [Troubleshooting](#troubleshooting)
14. [เอกสารเพิ่มเติม](#เอกสารเพิ่มเติม)

---

## ฟีเจอร์หลัก

- สมัครสมาชิก / เข้าสู่ระบบด้วย Firebase Auth
- Onboarding เพื่อกรอกข้อมูลร่างกายและคำนวณเป้าหมายสุขภาพ
- Dashboard รายวัน: แคลอรี่, สารอาหาร, น้ำดื่ม, streak, กราฟ 7 วัน
- บันทึกอาหารด้วยตัวเอง, ใช้อาหารที่เคยบันทึก, หรือให้ AI ช่วยประมาณ
- วิเคราะห์อาหารจากรูปภาพด้วย Gemini API
- บันทึกน้ำแบบ quick actions
- คลังบทความและวิดีโอออกกำลังกาย
- Profile สำหรับแก้ไขน้ำหนัก ส่วนสูง เป้าหมาย รูปโปรไฟล์ และ reminder settings
- AI Coach สำหรับถามคำแนะนำเรื่องอาหาร น้ำหนัก โปรตีน น้ำดื่ม และพฤติกรรมสุขภาพ
- Admin dashboard สำหรับผู้ใช้ที่มี role เป็น `admin`

---

## Tech Stack

| ส่วน | เทคโนโลยี |
| --- | --- |
| App | Flutter / Dart SDK `^3.5.3` |
| State Management | Provider |
| Backend | Firebase Auth, Cloud Firestore, Firebase Storage |
| Serverless | Firebase Cloud Functions, Node.js |
| AI | Google Gemini API |
| UI | Material 3, Bai Jamjuree, Lucide Icons |
| Chart | `fl_chart` |
| Local config | `flutter_dotenv` |

---

## สิ่งที่ต้องติดตั้ง

ติดตั้งเครื่องมือเหล่านี้ก่อนเริ่ม:

- Flutter SDK: [Flutter installation guide](https://docs.flutter.dev/get-started/install)
- Git
- Android Studio หรือ VS Code พร้อม Flutter extension
- Android SDK และ emulator/device สำหรับรัน Android
- Xcode และ CocoaPods ถ้าจะรัน iOS บน macOS
- Node.js และ npm ถ้าจะ deploy Cloud Functions
- Firebase CLI ถ้าจะ deploy rules/functions

ติดตั้ง Firebase CLI:

```bash
npm install -g firebase-tools
```

ตรวจ environment:

```bash
flutter doctor
```

---

## ติดตั้งโปรเจกต์

Clone โปรเจกต์:

```bash
git clone <repo-url>
cd Foodcal
```

ติดตั้ง dependencies:

```bash
flutter pub get
```

ถ้ามีปัญหา dependency/cache:

```bash
flutter clean
flutter pub get
```

---

## ตั้งค่า Firebase

โปรเจกต์นี้ใช้ Firebase เป็น backend หลัก ต้องมี config ของ Firebase ก่อนรันแอปจริง

### ไฟล์ที่ต้องมี

ไฟล์เหล่านี้มักไม่ควรถูก commit ขึ้น Git ให้ขอจากทีม หรือดาวน์โหลดจาก Firebase Console:

| Platform | ไฟล์ | ตำแหน่ง |
| --- | --- | --- |
| Android | `google-services.json` | `android/app/google-services.json` |
| iOS | `GoogleService-Info.plist` | `ios/Runner/GoogleService-Info.plist` |

ไฟล์ Dart config อยู่ที่:

```text
lib/firebase_options.dart
```

### เปิด Authentication Providers

ใน Firebase Console ให้เปิด:

- Email/Password
- Google Sign-In

สำหรับ Google Sign-In:

- Android: เพิ่ม SHA-1 / SHA-256 ของ debug/release keystore ใน Firebase Console
- iOS: ตรวจ URL Scheme จาก `REVERSED_CLIENT_ID`
- Web: ตรวจ `authDomain` ให้ตรงกับ Firebase project

### Firestore / Storage Rules

Rules อยู่ที่:

```text
firestore.rules
storage.rules
```

Deploy rules:

```bash
firebase login
firebase use <firebase-project-id>
firebase deploy --only firestore:rules
firebase deploy --only storage:rules
```

---

## ตั้งค่า AI

ฟีเจอร์ AI ใช้ Gemini API key

สร้างไฟล์:

```text
assets/.env
```

ใส่ค่า:

```env
GEMINI_API_KEY=your_gemini_api_key_here
```

หรือส่งผ่าน build flag:

```bash
flutter run --dart-define=GEMINI_API_KEY=your_gemini_api_key_here
```

ถ้าไม่ได้ตั้งค่า API key ฟีเจอร์เหล่านี้จะไม่ทำงานหรือทำงานแบบจำกัด:

- ประมาณแคลอรี่ด้วย AI
- วิเคราะห์อาหารจากรูปภาพ
- AI Coach

หมายเหตุ: `docs/AI_BACKEND_SETUP.md` เป็นเอกสารแนวทางสำหรับย้าย AI key ไปไว้ที่ backend/proxy ในอนาคต แต่โค้ด Flutter ปัจจุบันยังอ่าน `GEMINI_API_KEY` จาก client ผ่าน `flutter_dotenv` หรือ `--dart-define`

---

## รันแอป

ดู device ที่พร้อมใช้งาน:

```bash
flutter devices
```

รันบน device/emulator:

```bash
flutter run
```

รันพร้อม Gemini key:

```bash
flutter run --dart-define=GEMINI_API_KEY=your_gemini_api_key_here
```

รันบน Chrome:

```bash
flutter run -d chrome
```

รันบน Windows desktop:

```bash
flutter run -d windows
```

---

## ทดสอบและตรวจโค้ด

Format โค้ด:

```bash
dart format lib test
```

Analyze:

```bash
flutter analyze
```

รัน tests ทั้งหมด:

```bash
flutter test
```

รัน test เฉพาะไฟล์:

```bash
flutter test test/nutrition_service_test.dart
flutter test test/input_validator_test.dart
```

---

## ภาพรวมการทำงาน

Flow เริ่มต้น:

```text
main.dart
  -> โหลด assets/.env
  -> Firebase.initializeApp()
  -> AuthWrapper
       -> ยังไม่ login: LoginScreen / RegisterScreen
       -> login แล้ว: MainScreen
```

ถ้าผู้ใช้ login แล้วแต่ยังไม่มี profile ใน Firestore แอปจะเปิด Onboarding เพื่อเก็บข้อมูลพื้นฐาน:

- ชื่อ
- เพศ
- วันเกิด
- ส่วนสูง / น้ำหนัก / น้ำหนักเป้าหมาย
- ระดับกิจกรรม
- เป้าหมายสุขภาพ

จากนั้นระบบคำนวณ:

- TDEE
- Target calories
- Protein / carbs / fat target
- Target water glasses

### Main Tabs

| Tab | ไฟล์ | หน้าที่ |
| --- | --- | --- |
| หน้าแรก | `lib/screens/home_screen.dart` | Dashboard, แคลอรี่, macro, น้ำ, trend |
| บันทึก | `lib/screens/tracking_screen.dart` | บันทึกอาหาร, สแกนรูป, บันทึกน้ำ |
| เนื้อหา | `lib/screens/content_screen.dart` | บทความและวิดีโอ workout |
| โปรไฟล์ | `lib/screens/profile_screen.dart` | ข้อมูลส่วนตัว เป้าหมาย reminder รูปโปรไฟล์ |

ถ้า `users/{uid}.role == "admin"` ผู้ใช้จะเข้า `AdminScreen` แทนหน้าหลัก

### การประมาณโภชนาการ

หน้า Tracking เรียก:

```text
NutritionService.lookupFood(foodName)
NutritionService.analyzeImage(imageBytes)
```

ลำดับการทำงานโดยย่อ:

```text
ชื่ออาหาร
  -> FoodDatabaseService / cache
  -> AI enrichment หรือ AI fallback
  -> NutritionResult
```

รูปภาพ:

```text
รูปอาหาร
  -> Gemini Vision
  -> JSON nutrition result
  -> NutritionResult
```

AI Coach เรียก:

```text
AIService.askCoach(message, history)
```

### การเก็บข้อมูล

ข้อมูลหลักเก็บใน Firestore:

```text
users/{uid}
  daily_logs/{YYYY-MM-DD}
  custom_foods/{id}
  weight_logs/{id}
  workout_sessions/{id}

food_cache/{normalized_name}
workout_videos/{id}
feedback/{id}
```

วันที่ใช้ `dateKey` ตามเวลาไทยผ่าน `DateTimeUtils`

---

## โครงสร้างโปรเจกต์

```text
Foodcal/
├── lib/
│   ├── main.dart
│   ├── main_screen.dart
│   ├── app_theme.dart
│   ├── constants/
│   ├── models/
│   ├── screens/
│   ├── services/
│   ├── utils/
│   └── widgets/
├── test/
├── functions/
├── docs/
├── assets/
├── android/
├── ios/
├── web/
├── firebase.json
├── firestore.rules
├── storage.rules
├── pubspec.yaml
└── README.md
```

ไฟล์สำคัญ:

| ไฟล์/โฟลเดอร์ | ความหมาย |
| --- | --- |
| `lib/app_theme.dart` | Theme, colors, typography, gradients |
| `lib/main_screen.dart` | Shell หลัง login, bottom navigation, routing |
| `lib/screens/` | หน้าจอหลักของแอป |
| `lib/widgets/` | UI components ใช้ซ้ำ |
| `lib/services/auth_service.dart` | Firebase Auth |
| `lib/services/firestore_service.dart` | อ่าน/เขียน Firestore |
| `lib/services/nutrition_service.dart` | ค้นหา/ประมาณโภชนาการ |
| `lib/services/ai_service.dart` | AI Coach |
| `functions/` | Firebase Cloud Functions |
| `test/` | Unit/widget tests |
| `docs/` | เอกสารออกแบบและวิเคราะห์ระบบ |

---

## Cloud Functions และ Deploy

ติดตั้ง dependencies ของ functions:

```bash
cd functions
npm install
cd ..
```

ตั้งค่า Gemini secret สำหรับ functions:

```bash
firebase functions:secrets:set GEMINI_API_KEY
```

Deploy functions:

```bash
firebase deploy --only functions
```

Functions ที่มีในโปรเจกต์ เช่น:

- `estimateFood`
- `analyzeFoodImage`
- `askCoach`
- `recordDailyVisit`
- `appendFood`
- `updateWater`
- admin operations

หมายเหตุ: บาง function เป็น backend capability ที่เตรียมไว้ แต่ client Flutter บางส่วนยังเรียก service/client flow เดิมอยู่ ให้ตรวจโค้ดใน `lib/services/` ก่อนเปลี่ยน architecture

---

## Build Release

### Android App Bundle

สร้าง keystore:

```bash
keytool -genkey -v -keystore release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias foodcal
```

สร้างไฟล์ `android/key.properties`:

```properties
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=foodcal
storeFile=../release.jks
```

Build:

```bash
flutter build appbundle --release
```

### Android APK

```bash
flutter build apk --release
```

---

## Troubleshooting

### `flutter` หรือ `dart` command not found

ติดตั้ง Flutter SDK และเพิ่ม path นี้ใน PATH:

```text
<flutter-sdk>/bin
```

จากนั้นเปิด terminal ใหม่และรัน:

```bash
flutter doctor
```

### `Missing paths to code to format`

แปลว่าเรียก `dart format` โดยไม่ส่ง path ให้ใช้:

```bash
dart format lib test
```

### แอปเริ่มไม่ได้หลัง clone

ตรวจสิ่งเหล่านี้:

- รัน `flutter pub get` แล้ว
- มี `android/app/google-services.json`
- มี `assets/.env` ถ้าต้องใช้ AI
- Firebase project ตรงกับ `lib/firebase_options.dart`

### Google Sign-In ล้มเหลว

- Android: ใส่ SHA-1/SHA-256 ใน Firebase Console
- ดาวน์โหลด `google-services.json` ใหม่หลังแก้ SHA
- ตรวจว่าเปิด Google provider ใน Firebase Authentication แล้ว

### AI ไม่ตอบ / วิเคราะห์รูปไม่ได้

- ตรวจ `assets/.env` มี `GEMINI_API_KEY`
- หรือรันด้วย `--dart-define=GEMINI_API_KEY=...`
- ตรวจ internet connection
- ดู console log จาก `AppLogger`

### Firestore permission denied

- ตรวจว่า login แล้ว
- ตรวจ `firestore.rules`
- Deploy rules ล่าสุด:

```bash
firebase deploy --only firestore:rules
```

---

## เอกสารเพิ่มเติม

| ไฟล์ | รายละเอียด |
| --- | --- |
| `PROJECT_STRUCTURE.md` | อธิบายโครงสร้างไฟล์ในโปรเจกต์ |
| `docs/SYSTEM_ANALYSIS_TH.md` | วิเคราะห์ระบบ use case, data flow, ERD |
| `docs/APP_FLOW_PRESENTATION.md` | สรุป flow แอป |
| `docs/AI_BACKEND_SETUP.md` | แนวทาง backend/proxy สำหรับ AI |
| `docs/UI_DESIGN_SPEC_STYLE_A.md` | สเปก UI/UX Organic & Warm |
| `docs/diagrams/` | ไฟล์ diagram ของระบบ |

---

## Quick Start Checklist

- [ ] ติดตั้ง Flutter และรัน `flutter doctor`
- [ ] Clone repo
- [ ] รัน `flutter pub get`
- [ ] วาง Firebase config files
- [ ] สร้าง `assets/.env` พร้อม `GEMINI_API_KEY`
- [ ] เปิด Firebase Auth providers
- [ ] รัน `flutter run`
- [ ] รัน `flutter analyze`
- [ ] รัน `flutter test`
