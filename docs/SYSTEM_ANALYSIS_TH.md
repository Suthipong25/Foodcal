# เอกสารวิเคราะห์ระบบ Foodcal

เอกสารนี้สรุปภาพรวมของแอป Foodcal จากโค้ดปัจจุบันในโปรเจกต์ เพื่อใช้เป็นฐานสำหรับรายงาน วิชาโปรเจกต์ หรือพรีเซนต์งานระบบ

## 1. Data Flow Diagram

```mermaid
flowchart TD
    U["ผู้ใช้งาน"] --> A["Flutter App UI"]
    A --> B["AuthService"]
    A --> C["FirestoreService"]
    A --> D["StorageService"]
    A --> E["AIService"]

    B --> F["Firebase Authentication"]
    C --> G["Cloud Firestore"]
    D --> H["Firebase Storage"]
    E --> I["AI Backend / Gemini API"]

    G --> G1["users"]
    G --> G2["daily_logs"]
    G --> G3["weight_logs"]
    G --> G4["custom_foods"]
    G --> G5["workout_sessions"]
    G --> G6["feedback"]
    G --> G7["workout_videos"]

    F --> A
    H --> A
    I --> A
    G --> A
```

### คำอธิบายย่อ

- ผู้ใช้โต้ตอบผ่านแอป Flutter
- ระบบยืนยันตัวตนผ่าน Firebase Authentication
- ข้อมูลหลักเก็บใน Cloud Firestore
- รูปโปรไฟล์เก็บใน Firebase Storage
- การวิเคราะห์อาหารด้วยรูปหรือข้อความเชื่อมกับ AI backend

## 2. Use Case Diagram

```mermaid
flowchart LR
    User["ผู้ใช้ทั่วไป"]
    Admin["ผู้ดูแลระบบ"]

    UC1["สมัครสมาชิก"]
    UC2["เข้าสู่ระบบ"]
    UC3["กรอกข้อมูลสุขภาพเริ่มต้น"]
    UC4["ดูแดชบอร์ดสุขภาพ"]
    UC5["บันทึกอาหาร"]
    UC6["บันทึกน้ำดื่ม"]
    UC7["ใช้ AI วิเคราะห์อาหาร"]
    UC8["เริ่มและจบ workout"]
    UC9["ดูประวัติสุขภาพ"]
    UC10["บันทึกน้ำหนัก"]
    UC11["จัดการอาหารที่สร้างเอง"]
    UC12["แก้ไขโปรไฟล์"]
    UC13["อ่านบทความสุขภาพ"]
    UC14["ส่ง feedback"]
    UC15["ดูผู้ใช้ทั้งหมด"]
    UC16["เปลี่ยนสิทธิ์ admin"]
    UC17["ลบบัญชีผู้ใช้"]

    User --> UC1
    User --> UC2
    User --> UC3
    User --> UC4
    User --> UC5
    User --> UC6
    User --> UC7
    User --> UC8
    User --> UC9
    User --> UC10
    User --> UC11
    User --> UC12
    User --> UC13
    User --> UC14

    Admin --> UC15
    Admin --> UC16
    Admin --> UC17
```

## 3. Entity Relationship Diagram

หมายเหตุ: แอพนี้ใช้ Firestore ซึ่งเป็นฐานข้อมูลแบบ document จึงมีทั้งความสัมพันธ์แบบ collection/subcollection และการฝังข้อมูลบางส่วนไว้ใน document เดียว เช่น `foods` และ `workouts` ภายใน `daily_logs`

```mermaid
erDiagram
    USERS ||--o{ DAILY_LOGS : has
    USERS ||--o{ WEIGHT_LOGS : has
    USERS ||--o{ CUSTOM_FOODS : has
    USERS ||--o{ WORKOUT_SESSIONS : has
    USERS ||--o{ FEEDBACK : sends

    DAILY_LOGS ||--o{ FOOD_ITEMS : contains
    DAILY_LOGS ||--o{ WORKOUT_ITEMS : contains

    USERS {
        string uid PK
        string name
        string gender
        int birthMonth
        int birthYear
        double height
        double weight
        double targetWeight
        string activityLevel
        string goal
        string role
        int tdee
        int targetCalories
        int targetProtein
        int targetCarbs
        int targetFat
        int targetWaterGlasses
        int streak
        string joinedDate
        string lastLoginDate
        string photoUrl
    }

    DAILY_LOGS {
        string date PK
        int caloriesIn
        int caloriesOut
        int protein
        int carbs
        int fat
        int waterGlasses
        string lastUpdated
    }

    FOOD_ITEMS {
        string id PK
        string name
        int calories
        int protein
        int carbs
        int fat
        string time
        string mealType
    }

    WORKOUT_ITEMS {
        int id PK
        string title
        string level
        string duration
        int minutes
        string type
        string completedAt
    }

    WEIGHT_LOGS {
        string date PK
        double weightKg
        string note
    }

    CUSTOM_FOODS {
        string id PK
        string name
        int calories
        int protein
        int carbs
        int fat
        double servingSize
        string servingUnit
        bool isFavorite
    }

    WORKOUT_SESSIONS {
        int workoutId PK
        string title
        string level
        string type
        int minutes
        string dateKey
        string startedAt
        bool completed
        string completedAt
    }

    FEEDBACK {
        string id PK
        string uid FK
        int rating
        string comment
        string favoriteFeature
        string createdAt
    }
```

## 4. ตารางข้อมูลของระบบ

### ตารางที่ 1 `users`

| ฟิลด์ | ชนิดข้อมูล | รายละเอียด |
|---|---|---|
| `uid` | String | รหัสผู้ใช้จาก Firebase Auth |
| `name` | String | ชื่อผู้ใช้ |
| `gender` | String | เพศ |
| `birthMonth` | int | เดือนเกิด |
| `birthYear` | int | ปีเกิด |
| `height` | double | ส่วนสูง |
| `weight` | double | น้ำหนักปัจจุบัน |
| `targetWeight` | double | น้ำหนักเป้าหมาย |
| `activityLevel` | String | ระดับกิจกรรม |
| `goal` | String | เป้าหมายสุขภาพ |
| `role` | String | สิทธิ์ผู้ใช้ เช่น `user`, `admin` |
| `tdee` | int | พลังงานที่ใช้ต่อวัน |
| `targetCalories` | int | แคลอรีเป้าหมายต่อวัน |
| `targetProtein` | int | โปรตีนเป้าหมาย |
| `targetCarbs` | int | คาร์บเป้าหมาย |
| `targetFat` | int | ไขมันเป้าหมาย |
| `targetWaterGlasses` | int | เป้าหมายน้ำดื่มต่อวัน |
| `streak` | int | จำนวนวันใช้งานต่อเนื่อง |
| `joinedDate` | String/Date | วันที่เริ่มใช้งาน |
| `lastLoginDate` | String/Date | วันที่เข้าใช้งานครั้งล่าสุด |
| `photoUrl` | String | URL รูปโปรไฟล์ |

### ตารางที่ 2 `daily_logs`

ตำแหน่งจัดเก็บ: `users/{uid}/daily_logs/{date}`

| ฟิลด์ | ชนิดข้อมูล | รายละเอียด |
|---|---|---|
| `date` | String | วันที่รูปแบบ `YYYY-MM-DD` |
| `caloriesIn` | int | แคลอรีที่รับเข้า |
| `caloriesOut` | int | แคลอรีที่เผาผลาญ |
| `protein` | int | โปรตีนรวมทั้งวัน |
| `carbs` | int | คาร์บรวมทั้งวัน |
| `fat` | int | ไขมันรวมทั้งวัน |
| `waterGlasses` | int | จำนวนแก้วน้ำ |
| `foods` | Array | รายการอาหารที่บันทึก |
| `workouts` | Array | รายการออกกำลังกายที่จบแล้ว |
| `lastUpdated` | Timestamp/String | วันที่อัปเดตล่าสุด |

### ตารางที่ 3 `foods` แบบ embedded ใน `daily_logs`

| ฟิลด์ | ชนิดข้อมูล | รายละเอียด |
|---|---|---|
| `id` | String | รหัสอาหาร |
| `name` | String | ชื่ออาหาร |
| `calories` | int | แคลอรี |
| `protein` | int | โปรตีน |
| `carbs` | int | คาร์บ |
| `fat` | int | ไขมัน |
| `time` | String/Date | เวลาที่รับประทาน |
| `mealType` | String | ประเภทมื้อ เช่น breakfast, lunch, dinner, snack |

### ตารางที่ 4 `workouts` แบบ embedded ใน `daily_logs`

| ฟิลด์ | ชนิดข้อมูล | รายละเอียด |
|---|---|---|
| `id` | int | รหัส workout |
| `title` | String | ชื่อ workout |
| `level` | String | ระดับความยาก |
| `duration` | String | ระยะเวลาแบบข้อความ |
| `minutes` | int | จำนวนเวลาจริงเป็นนาที |
| `type` | String | ประเภทการออกกำลังกาย |
| `completedAt` | String/Date | เวลาที่ทำเสร็จ |

### ตารางที่ 5 `workout_sessions`

ตำแหน่งจัดเก็บ: `users/{uid}/workout_sessions/{workoutId}`

| ฟิลด์ | ชนิดข้อมูล | รายละเอียด |
|---|---|---|
| `workoutId` | int | รหัส workout |
| `title` | String | ชื่อ workout |
| `level` | String | ระดับความยาก |
| `type` | String | ประเภท workout |
| `minutes` | int | เวลาที่ต้องทำ |
| `dateKey` | String | วันที่ของ session |
| `startedAt` | String/Date | เวลาเริ่ม |
| `completed` | bool | สถานะจบหรือยัง |
| `completedAt` | String/Date | เวลาจบ |
| `updatedAt` | Timestamp | เวลาที่ระบบอัปเดต |

### ตารางที่ 6 `weight_logs`

ตำแหน่งจัดเก็บ: `users/{uid}/weight_logs/{date}`

| ฟิลด์ | ชนิดข้อมูล | รายละเอียด |
|---|---|---|
| `date` | String | วันที่บันทึก |
| `weightKg` | double | น้ำหนักเป็นกิโลกรัม |
| `note` | String | หมายเหตุเพิ่มเติม |

### ตารางที่ 7 `custom_foods`

ตำแหน่งจัดเก็บ: `users/{uid}/custom_foods/{foodId}`

| ฟิลด์ | ชนิดข้อมูล | รายละเอียด |
|---|---|---|
| `id` | String | รหัสอาหารกำหนดเอง |
| `name` | String | ชื่ออาหาร |
| `calories` | int | แคลอรี |
| `protein` | int | โปรตีน |
| `carbs` | int | คาร์บ |
| `fat` | int | ไขมัน |
| `servingSize` | double | ปริมาณต่อหนึ่งหน่วย |
| `servingUnit` | String | หน่วย เช่น g |
| `isFavorite` | bool | ถูกปักเป็นรายการโปรดหรือไม่ |

### ตารางที่ 8 `feedback`

| ฟิลด์ | ชนิดข้อมูล | รายละเอียด |
|---|---|---|
| `id` | String | รหัส feedback |
| `uid` | String | ผู้ส่ง feedback |
| `rating` | int | คะแนนความพึงพอใจ |
| `comment` | String | ความเห็นเพิ่มเติม |
| `favoriteFeature` | String | ฟีเจอร์ที่ชอบ |
| `createdAt` | Timestamp | วันเวลาที่ส่ง |

### ตารางที่ 9 `workout_videos`

| ฟิลด์ | ชนิดข้อมูล | รายละเอียด |
|---|---|---|
| `id` | int | รหัสวิดีโอ |
| `title` | String | ชื่อวิดีโอ |
| `level` | String | ระดับความยาก |
| `duration` | String | ระยะเวลา |
| `type` | String | ประเภท |
| `youtubeUrl` | String | ลิงก์ YouTube |

## 5. Gantt Chart แบบใช้นำเสนอ

ด้านล่างเป็น Gantt Chart ตัวอย่างสำหรับอธิบายขั้นตอนพัฒนา Foodcal

```mermaid
gantt
    title แผนการพัฒนาแอป Foodcal
    dateFormat  YYYY-MM-DD
    section วิเคราะห์และออกแบบ
    เก็บความต้องการระบบ           :done, a1, 2026-01-01, 7d
    ออกแบบ Use Case / DFD / ER     :done, a2, after a1, 7d
    ออกแบบหน้าจอและฐานข้อมูล      :done, a3, after a2, 7d

    section พัฒนาแอป
    ระบบสมัครสมาชิกและล็อกอิน     :done, b1, 2026-01-22, 7d
    ระบบ onboarding และโปรไฟล์     :done, b2, after b1, 7d
    ระบบบันทึกอาหารและน้ำ         :done, b3, after b2, 10d
    ระบบ workout และประวัติ        :done, b4, after b3, 8d
    ระบบ AI วิเคราะห์อาหาร        :done, b5, after b4, 7d

    section ทดสอบและส่งมอบ
    ทดสอบการทำงาน                 :active, c1, 2026-03-01, 7d
    แก้ไขข้อผิดพลาด               :c2, after c1, 5d
    จัดทำรายงานและนำเสนอ          :c3, after c2, 5d
```

## 6. ข้อสังเกตสำคัญสำหรับใช้ส่งงาน

- ถ้าจะเขียนรายงานเชิงฐานข้อมูลแบบ relational สามารถอธิบายได้ว่า `daily_logs` เป็น entity หลัก และมี `foods` กับ `workouts` เป็น child records
- แต่ถ้าจะเขียนให้ตรงกับของจริงที่สุด ควรระบุว่าแอพนี้ใช้ Firestore ซึ่งรองรับ nested array และ subcollection
- โครงสร้างที่มีในโค้ดปัจจุบัน ไม่ได้แยก `Meal`, `ConsumedFood`, `Food`, `Exercise`, `WorkoutLog` ตาม relational database แบบเข้มงวด แต่ใช้ `daily_logs`, `foods`, `workouts`, `workout_sessions`, `custom_foods` แทน

## 7. สิ่งที่สามารถทำต่อให้ได้

- ปรับเอกสารนี้ให้เป็นรูปแบบอาจารย์ต้องการ
- แยกเป็นไฟล์ `Data Flow Diagram`, `Use Case Diagram`, `ER Diagram` คนละไฟล์
- แปลงตารางให้เป็นรูปแบบบทที่ 3 หรือบทที่ 4 ของรายงาน
- ทำเวอร์ชันภาษาอังกฤษ
- ทำสไลด์สรุปจากเอกสารนี้ต่อได้
