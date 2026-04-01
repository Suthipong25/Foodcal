# Foodcal App Flow

ไฟล์นี้ใช้เป็นเวอร์ชันสำหรับสไลด์พรีเซนต์ โดยแยกเป็น `User Flow` และ `System Flow` เพื่ออธิบายทั้งมุมผู้ใช้งานและมุมการทำงานของระบบ

## 1. Overview

```mermaid
flowchart LR
    A["เปิดแอป Foodcal"] --> B["เข้าสู่ระบบ / สมัครสมาชิก"]
    B --> C["ตั้งค่าโปรไฟล์สุขภาพ"]
    C --> D["Home Dashboard"]
    D --> E["Tracking อาหารและน้ำ"]
    D --> F["Learning & Workout"]
    D --> G["Profile และเป้าหมาย"]
    E --> H["บันทึกลง Firestore"]
    F --> H
    G --> H
    H --> D
```

### ประโยคสรุปสำหรับพูด

Foodcal เป็นแอปติดตามสุขภาพที่เริ่มจากการสมัครสมาชิกและตั้งค่าโปรไฟล์สุขภาพ จากนั้นผู้ใช้สามารถบันทึกอาหาร น้ำ ออกกำลังกาย และดูความรู้สุขภาพได้ในแอปเดียว โดยข้อมูลทั้งหมดจะถูกสรุปกลับมาที่หน้า Dashboard

---

## 2. User Flow

```mermaid
flowchart TD
    classDef start fill:#E8F2FF,stroke:#1F6FEB,color:#10233F,stroke-width:2px;
    classDef action fill:#FFFFFF,stroke:#CFE1FF,color:#10233F,stroke-width:1.5px;
    classDef decision fill:#FFF6E8,stroke:#FFA62B,color:#7A4A00,stroke-width:1.5px;
    classDef storage fill:#EAFBF1,stroke:#14AE5C,color:#0E5B31,stroke-width:1.5px;

    A["เปิดแอป"]:::start --> B{"ล็อกอินแล้วหรือยัง"}:::decision

    B -- "ยังไม่ล็อกอิน" --> C["หน้า Login / Register"]:::action
    C --> D["Firebase Authentication"]:::storage
    D --> E{"เข้าสู่ระบบสำเร็จหรือไม่"}:::decision
    E -- "ไม่สำเร็จ" --> C
    E -- "สำเร็จ" --> F{"มีโปรไฟล์สุขภาพแล้วหรือยัง"}:::decision

    B -- "ล็อกอินแล้ว" --> F

    F -- "ยังไม่มี" --> G["Onboarding"]:::action
    G --> G1["กรอกข้อมูลพื้นฐาน\nชื่อ เพศ อายุ"]:::action
    G1 --> G2["กรอกน้ำหนัก ส่วนสูง\nและระดับกิจกรรม"]:::action
    G2 --> G3["เลือกเป้าหมาย\nลดน้ำหนัก / รักษา / เพิ่มกล้ามเนื้อ"]:::action
    G3 --> G4["ระบบคำนวณเป้าหมายรายวัน"]:::action
    G4 --> H["บันทึกโปรไฟล์ผู้ใช้"]:::storage

    F -- "มีแล้ว" --> I["เข้าสู่ Main Screen"]:::start
    H --> I

    I --> J["Home Dashboard"]:::action
    I --> K["Tracking"]:::action
    I --> L["Learning"]:::action
    I --> M["Profile"]:::action

    K --> K1["เพิ่มอาหารเอง"]:::action
    K --> K2["ใช้ AI ช่วยวิเคราะห์อาหาร"]:::action
    K --> K3["บันทึกน้ำดื่ม"]:::action
    K1 --> N["อัปเดต Daily Log"]:::storage
    K2 --> N
    K3 --> N

    L --> L1["อ่านบทความสุขภาพ"]:::action
    L --> L2["ดูวิดีโอออกกำลังกาย"]:::action
    L2 --> L3["กดจบ workout"]:::action
    L3 --> N

    M --> M1["แก้ไขข้อมูลร่างกาย"]:::action
    M --> M2["แก้ไขเป้าหมาย"]:::action
    M --> M3["เปลี่ยนรูปโปรไฟล์"]:::action
    M1 --> O["คำนวณค่าใหม่และบันทึก"]:::storage
    M2 --> O
    M3 --> O

    N --> J
    O --> J
```

### สิ่งที่อาจารย์ควรเห็นจาก User Flow

- ผู้ใช้เริ่มจากการยืนยันตัวตนก่อนเสมอ
- ถ้าเป็นผู้ใช้ใหม่ จะต้องผ่าน Onboarding เพื่อสร้างเป้าหมายสุขภาพเฉพาะบุคคล
- หลังจากนั้นผู้ใช้จะทำงานหลักอยู่ใน 4 หน้า คือ `Home`, `Tracking`, `Learning`, และ `Profile`
- ทุกกิจกรรมสำคัญจะเชื่อมกลับไปที่การบันทึกข้อมูลและอัปเดตหน้า Dashboard

---

## 3. System Flow

```mermaid
flowchart TD
    classDef ui fill:#E8F2FF,stroke:#1F6FEB,color:#10233F,stroke-width:2px;
    classDef service fill:#FFFFFF,stroke:#CFE1FF,color:#10233F,stroke-width:1.5px;
    classDef firebase fill:#EAFBF1,stroke:#14AE5C,color:#0E5B31,stroke-width:1.5px;
    classDef external fill:#FFF6E8,stroke:#FFA62B,color:#7A4A00,stroke-width:1.5px;

    A["Flutter UI"]:::ui --> B["AuthService"]:::service
    A --> C["FirestoreService"]:::service
    A --> D["StorageService"]:::service
    A --> E["AIService"]:::service

    B --> F["Firebase Authentication"]:::firebase
    C --> G["Cloud Firestore"]:::firebase
    D --> H["Firebase Storage"]:::firebase
    E --> I["Gemini API / AI Provider"]:::external

    G --> J["users/{uid}\nเก็บโปรไฟล์ผู้ใช้"]:::firebase
    G --> K["users/{uid}/daily_logs/{date}\nเก็บอาหาร น้ำ และ workout"]:::firebase
    H --> L["profile_pictures/{uid}\nเก็บรูปโปรไฟล์"]:::firebase

    F --> A
    J --> A
    K --> A
    L --> A
    I --> A
```

### สิ่งที่อาจารย์ควรเห็นจาก System Flow

- ฝั่งแอปพัฒนาด้วย Flutter และแยก service ตามหน้าที่ชัดเจน
- การยืนยันตัวตนใช้ `Firebase Authentication`
- ข้อมูลโปรไฟล์และบันทึกรายวันเก็บใน `Cloud Firestore`
- รูปโปรไฟล์เก็บใน `Firebase Storage`
- การวิเคราะห์อาหารเชื่อมกับ AI service แล้วส่งผลลัพธ์กลับมาแสดงในแอป

---

## 4. Data Flow แบบสั้น

```mermaid
sequenceDiagram
    participant U as User
    participant UI as Flutter UI
    participant AUTH as Firebase Auth
    participant FS as Firestore
    participant ST as Storage
    participant AI as AI Service

    U->>UI: สมัครสมาชิก / เข้าสู่ระบบ
    UI->>AUTH: ตรวจสอบตัวตน
    AUTH-->>UI: สถานะผู้ใช้

    U->>UI: กรอกโปรไฟล์สุขภาพ
    UI->>FS: บันทึก users/{uid}
    FS-->>UI: โปรไฟล์ผู้ใช้

    U->>UI: บันทึกอาหาร น้ำ หรือ workout
    UI->>FS: อัปเดต daily_logs
    FS-->>UI: ข้อมูลล่าสุด

    U->>UI: เปลี่ยนรูปโปรไฟล์
    UI->>ST: อัปโหลดรูป
    ST-->>UI: photoUrl
    UI->>FS: บันทึก photoUrl

    U->>UI: ใช้ AI วิเคราะห์อาหาร
    UI->>AI: ส่งคำขอวิเคราะห์
    AI-->>UI: ผลลัพธ์สารอาหาร
```

---

## 5. ประโยคปิดสไลด์

Foodcal ถูกออกแบบให้ผู้ใช้เห็นภาพสุขภาพของตัวเองได้ในหนึ่งแอป ตั้งแต่การตั้งเป้าหมาย บันทึกพฤติกรรมประจำวัน เรียนรู้ข้อมูลสุขภาพ ไปจนถึงติดตามผลผ่าน Dashboard โดยมี Firebase เป็นแกนหลักในการจัดการข้อมูลและผู้ใช้
