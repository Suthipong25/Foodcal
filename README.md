# Foodcal

แอปพลิเคชันสำหรับติดตามการรับประทานอาหาร ปริมาณน้ำดื่ม และการออกกำลังกายรายวัน พร้อมฟีเจอร์คำนวณและประเมินสุขภาพเบื้องต้น

## Getting Started

### 1. Prerequisites
- Flutter SDK (stable channel)
- Firebase CLI (`npm install -g firebase-tools`)
- โฟลเดอร์ `android/app` ต้องมีไฟล์ `google-services.json`
- โฟลเดอร์ `ios/Runner` ต้องมีไฟล์ `GoogleService-Info.plist`

### 2. Environment Variables
สร้างไฟล์ `assets/.env` (และห้ามอัปโหลดขึ้น Git) เพื่อระบุค่าตัวแปร:
```env
AI_BACKEND_URL=https://your-api.com
```

### 3. Firebase Deployment
สำหรับนักพัฒนา ให้ใช้คำสั่งเหล่านี้ในการ Deploy Rules:
```bash
npx firebase-tools use --add  # เลือกโปรเจกต์
npx firebase-tools deploy --only firestore:rules
npx firebase-tools deploy --only storage:rules
```

### 4. Running the Tests
แอปพลิเคชันมาพร้อมกับ Unit Test และ Widget Test:
```bash
flutter test
```

### 5. Release Build (Android)
สำหรับการ Build เพื่อปล่อยแอป:
1. สร้าง Keystore: `keytool -genkey -v -keystore release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias my-alias`
2. สร้างไฟล์ `android/key.properties` (ไม่ต้อง commit ขึ้น Git):
   ```properties
   storePassword=your_password
   keyPassword=your_password
   keyAlias=my-alias
   storeFile=../release.jks
   ```
3. รันคำสั่ง Build:
   ```bash
   flutter build appbundle --release
   ```

## CI/CD
โปรเจกต์นี้รองรับ GitHub Actions ในการรัน `flutter test` และ Deploy Firebase Rules อัตโนมัติ.
คุณต้องเพิ่ม Secrets ใน GitHub Repository ของคุณ:
- `FIREBASE_PROJECT`
- `FIREBASE_TOKEN` (ได้จาก `firebase login:ci`)
