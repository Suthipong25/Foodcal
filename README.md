# Foodcal

แอปสำหรับติดตามอาหาร น้ำดื่ม และการออกกำลังกายรายวัน พร้อมฟีเจอร์คำนวณสุขภาพเบื้องต้น, AI Coach และระบบล็อกอินด้วย Firebase Authentication

## Getting Started

### 1. Prerequisites
- Flutter SDK (stable channel)
- Firebase CLI: `npm install -g firebase-tools`
- โฟลเดอร์ `android/app` ต้องมีไฟล์ `google-services.json`
- โฟลเดอร์ `ios/Runner` ต้องมีไฟล์ `GoogleService-Info.plist`

### 2. Environment Variables
สร้างไฟล์ `assets/.env` และอย่าอัปโหลดขึ้น Git:

```env
AI_BACKEND_URL=https://your-api.com
```

### 3. Firebase Authentication Setup
เปิดใช้งาน provider ต่อไปนี้ใน Firebase Console:
- `Email/Password`
- `Google`

สำหรับ Google Sign-In ให้ตั้งค่าเพิ่มตามแพลตฟอร์ม:
- Android: เพิ่ม SHA-1 และ SHA-256 ของ keystore ให้กับ Android app ใน Firebase
- iOS: เพิ่ม `GoogleService-Info.plist` และนำค่า `REVERSED_CLIENT_ID` ไปตั้งใน `Info.plist` เป็น URL Scheme
- Web: ตรวจสอบว่า `authDomain` และ web app config ตรงกับค่าที่อยู่ใน `lib/firebase_options.dart`

หมายเหตุ:
- ถ้า Firebase แจ้งว่าอีเมลเดียวกันถูกใช้กับ provider อื่นอยู่แล้ว แอพจะแจ้งให้ผู้ใช้กลับไปเข้าสู่ระบบด้วยวิธีเดิมก่อน
- ฟีเจอร์ลืมรหัสผ่านใช้ reset email มาตรฐานของ Firebase

### 4. Firebase Deployment
สำหรับนักพัฒนา ใช้คำสั่งต่อไปนี้เพื่อ deploy rules:

```bash
npx firebase-tools use --add
npx firebase-tools deploy --only firestore:rules
npx firebase-tools deploy --only storage:rules
```

### 5. Running the App and Tests

```bash
flutter pub get
flutter test
flutter run
```

### 6. Release Build (Android)
1. สร้าง keystore:
   `keytool -genkey -v -keystore release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias my-alias`
2. สร้างไฟล์ `android/key.properties` และไม่ต้อง commit:

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

## CI/CD
โปรเจกต์นี้รองรับ GitHub Actions สำหรับ `flutter test` และ deploy Firebase Rules

Secrets ที่ควรตั้งใน GitHub Repository:
- `FIREBASE_PROJECT`
- `FIREBASE_TOKEN`
