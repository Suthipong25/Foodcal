# โครงสร้างไฟล์โปรเจกต์ Foodcal

สรุปหน้าที่ของแต่ละไฟล์ในแอปพลิเคชันเพื่อใช้เป็นคู่มืออ้างอิงครับ

## 📁 Root Directory

- `pubspec.yaml`: ไฟล์กำหนดการตั้งค่าหลักของโปรเจกต์, แพ็กเกจที่ใช้ (Dependencies) และ Assets
- `analysis_options.yaml`: กำหนดกฎการเขียนโค้ด (Linting rules) สำหรับ Dart
- `firebase.json`: การตั้งค่า Firebase สำหรับโปรเจกต์
- `README.md`: ข้อมูลเบื้องต้นของโปรเจกต์

## 📁 lib/ (แกนหลักของแอป)

- `main.dart`: จุดเริ่มต้นของแอป (Entry Point), ตั้งค่า Firebase และ Provider สำหรับจัดการ State
- `main_screen.dart`: หน้าหลักหลังจาก Login, ควบคุม Bottom Navigation และการโหลดข้อมูลโปรไฟล์/Streak
- `app_theme.dart`: กำหนดธีมสี, ฟอนต์, สไตล์การ์ด และเงา (Shadow) ของแอปทั้งหมด
- `firebase_options.dart`: การตั้งค่า Firebase สำหรับแต่ละแพลตฟอร์ม (สร้างโดยอัตโนมัติ)

### 📁 lib/models/ (โมเดลข้อมูล)

- `user_profile.dart`: โครงสร้างข้อมูลโปรไฟล์ผู้ใช้ (น้ำหนัก, ส่วนสูง, เป้าหมาย, แคลอรี่เป้าหมาย)
- `daily_log.dart`: โครงสร้างข้อมูลการบันทึกรายวัน (`FoodItem`, `WorkoutItem`, `DailyLog`)
- `content_model.dart`: โครงสร้างข้อมูลบทความสุขภาพและวิดีโอออกกำลังกาย

### 📁 lib/services/ (ส่วนการจัดการข้อมูลและ API)

- `auth_service.dart`: จัดการการลงทะเบียน, เข้าสู่ระบบ และออกจากระบบ ผ่าน Firebase Auth
- `firestore_service.dart`: จัดการการ อ่าน/เขียน ข้อมูลในฐานข้อมูล Firestore (โปรไฟล์, บันทึกอาหาร, ค่าน้ำ, สถิติ)
- `ai_service.dart`: เชื่อมต่อกับ Google Gemini AI สำหรับการวิเคราะห์รูปภาพอาหารและประมาณแคลอรี่
- `storage_service.dart`: จัดการการเก็บไฟล์รูปภาพ (เช่น รูปโปรไฟล์) ใน Firebase Storage

### 📁 lib/screens/ (หน้า UI ของแอป)

- **การยืนยันตัวตน**:
  - `login_screen.dart`: หน้าเข้าสู่ระบบ
  - `register_screen.dart`: หน้าลงทะเบียนผู้ใช้ใหม่
  - `onboarding_screen.dart`: หน้าสำหรับผู้ใช้ใหม่กรอกข้อมูลร่างกายเพื่อคำนวณเป้าหมายครั้งแรก
- **หน้าหลักและบันทึก**:
  - `home_screen.dart` (Dashboard): แสดงภาพรวมรายวัน, กราฟสัปดาห์, และงบแคลอรี่มื้อถัดไป
  - `tracking_screen.dart`: หน้าบันทึกอาหาร (สแกนรูป/พิมพ์ชื่อ) และบันทึกการดื่มน้ำ มีระบบอาหารล่าสุด
  - `history_screen.dart`: หน้าแสดงประวัติการบันทึกย้อนหลัง
- **เนื้อหาและข้อมูล**:
  - `content_screen.dart`: แหล่งรวมบทความแนะนำและวิดีโอออกกำลังกาย
  - `article_detail_screen.dart`: หน้าแสดงเนื้อหาบทความแบบละเอียด
- **จัดการโปรไฟล์**:
  - `profile_screen.dart`: หน้าดูและแก้ไขข้อมูลส่วนตัว, เป้าหมาย และรูปโปรไฟล์

### 📁 lib/widgets/ (ส่วนประกอบ UI ที่ใช้ซ้ำ)

- `tube_progress_bar.dart`: แถบความคืบหน้าที่ดีไซน์แบบ Tube ใช้สำหรับแสดงการดื่มน้ำและสารอาหาร (Macros)
