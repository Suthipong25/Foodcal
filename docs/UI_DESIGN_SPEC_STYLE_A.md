# 🎨 Foodcal — UI/UX Design Specification
# Style A: "Organic & Warm" 🌿

> **เอกสารนี้เขียนสำหรับ AI ที่จะแก้ไข UX/UI ของแอป Foodcal**
> อ่านเอกสารนี้ทั้งหมดก่อนเริ่มแก้ไข เพื่อให้ได้ผลลัพธ์ที่สอดคล้องกันทั้งแอป

---

## สารบัญ

1. [ภาพรวมโปรเจกต์](#1-ภาพรวมโปรเจกต์)
2. [Design Philosophy](#2-design-philosophy)
3. [Design Tokens — สี](#3-design-tokens--สี)
4. [Design Tokens — Typography](#4-design-tokens--typography)
5. [Design Tokens — Spacing & Radius](#5-design-tokens--spacing--radius)
6. [Design Tokens — Shadows & Effects](#6-design-tokens--shadows--effects)
7. [Design Tokens — Gradients](#7-design-tokens--gradients)
8. [Decorative Elements (ตกแต่ง)](#8-decorative-elements-ตกแต่ง)
9. [Component Library](#9-component-library)
10. [หน้า Login](#10-หน้า-login--loginscreendart)
11. [หน้า Register](#11-หน้า-register--registerscreendart)
12. [หน้า Onboarding](#12-หน้า-onboarding--onboardingscreendart)
13. [หน้า Home Dashboard](#13-หน้า-home-dashboard--homescreendart)
14. [หน้า Tracking](#14-หน้า-tracking--trackingscreendart)
15. [หน้า Content](#15-หน้า-content--contentscreendart)
16. [หน้า Profile](#16-หน้า-profile--profilescreendart)
17. [หน้า AI Coach](#17-หน้า-ai-coach--aicoachscreendart)
18. [Bottom Navigation Bar](#18-bottom-navigation-bar--mainscreendart)
19. [Animation & Micro-interactions](#19-animation--micro-interactions)
20. [ไฟล์ที่ต้องแก้ไข (สรุป)](#20-ไฟล์ที่ต้องแก้ไข-สรุป)

---

## 1. ภาพรวมโปรเจกต์

| รายการ | รายละเอียด |
|--------|-----------|
| **ชื่อแอป** | Foodcal |
| **Framework** | Flutter (Dart SDK ^3.5.3) |
| **State Management** | Provider |
| **Font** | Google Fonts — Bai Jamjuree |
| **Icons** | Lucide Icons (`lucide_icons: ^0.257.0`) |
| **Charts** | fl_chart (`^0.68.0`) |
| **Theme file** | `lib/app_theme.dart` |
| **Screens dir** | `lib/screens/` |
| **Widgets dir** | `lib/widgets/` |
| **Constants dir** | `lib/constants/` |

### โครงสร้างไฟล์ที่เกี่ยวข้อง

```
lib/
├── app_theme.dart              ← Theme หลัก (แก้ไขที่นี่ก่อน)
├── main.dart                   ← Entry point
├── main_screen.dart            ← Bottom nav + AppBar + routing
├── constants/
│   ├── app_config.dart         ← ค่า config ต่างๆ
│   └── enums.dart              ← Enum types
├── screens/
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── onboarding_screen.dart
│   ├── home_screen.dart        ← Dashboard
│   ├── tracking_screen.dart    ← บันทึกอาหาร/น้ำ
│   ├── content_screen.dart     ← บทความ + วิดีโอ
│   ├── profile_screen.dart
│   ├── ai_coach_screen.dart
│   ├── history_screen.dart
│   ├── weight_screen.dart
│   ├── workout_history_screen.dart
│   ├── custom_food_screen.dart
│   ├── feedback_screen.dart
│   ├── article_detail_screen.dart
│   └── admin_screen.dart
├── widgets/
│   ├── animated_page_wrapper.dart
│   ├── app_card.dart
│   ├── app_chip.dart
│   ├── app_icon_bubble.dart
│   ├── app_section_header.dart
│   ├── app_stat_card.dart
│   ├── edit_food_dialog.dart
│   ├── glass_card.dart
│   ├── gradient_button.dart
│   ├── nutrition_source_badge.dart
│   ├── reminder_banner.dart
│   └── tube_progress_bar.dart
├── services/                   ← ไม่ต้องแก้ไข (business logic)
├── models/                     ← ไม่ต้องแก้ไข (data models)
└── utils/                      ← ไม่ต้องแก้ไข (helpers)
```

---

## 2. Design Philosophy

### แนวคิดหลัก: "สุขภาพดี ไม่ต้องเครียด"

สไตล์ **Organic & Warm** ออกแบบให้ผู้ใช้รู้สึก:

- **อบอุ่น (Warm)** — โทนครีมธรรมชาติ ไม่ใช่ขาวจัด
- **เป็นกันเอง (Friendly)** — มุมโค้งมน มีภาพประกอบน่ารัก
- **ธรรมชาติ (Organic)** — ใบไม้ ต้นไม้ อาหาร เป็น decorative elements
- **ไม่กดดัน (Relaxed)** — soft shadow ไม่แรง สีไม่จัดจ้าน
- **Glassmorphism** — การ์ดโปร่งแสงเล็กน้อย มี blur effect

### หลักการออกแบบ

1. **ทุกการ์ดใช้ GlassCard** — ไม่ใช้ Material Card ธรรมดา
2. **ทุกหน้ามีพื้นหลัง gradient** — ไม่ใช่สีพื้นเรียบ
3. **ทุกปุ่มหลักใช้ GradientButton** — ไม่ใช่ ElevatedButton ธรรมดา
4. **ทุกหน้ามี decorative elements** — ใบไม้, plant illustrations อย่างน้อย 1-2 จุด
5. **ทุก icon ใส่ใน AppIconBubble** — ไม่ใช้ icon เปล่า
6. **ทุก section มี header** — ใช้ AppSectionHeader
7. **ทุก progress bar ใช้ TubeProgressBar** — แบบท่อกลม ไม่ใช่เส้นตรง

---

## 3. Design Tokens — สี

### ไฟล์ที่ต้องแก้: `lib/app_theme.dart`

```dart
// ── Primary Palette ──
static const Color primaryColor    = Color(0xFF4CBF83);  // เขียวหลัก
static const Color secondaryColor  = Color(0xFFA7E8C4);  // เขียวอ่อน
static const Color accentColor     = Color(0xFFFF8A7A);  // ส้มอมชมพู (coral)

// ── Ink & Text ──
static const Color ink             = Color(0xFF26362B);  // ตัวอักษรหลัก (เขียวเข้มมาก)
static const Color mutedText       = Color(0xFF758675);  // ตัวอักษรรอง

// ── Surface & Background ──
static const Color surface         = Color(0xFFFFFFFF);  // พื้นการ์ดขาว
static const Color pageBg          = Color(0xFFFBF8F0);  // พื้นหลังครีมอบอุ่น ★
static const Color pageTint        = Color(0xFFFFFCF7);  // ครีมอ่อนมาก
static const Color pageTintStrong  = Color(0xFFEFF8E9);  // เขียวอ่อนมาก

// ── Semantic Macro Colors ──
static const Color proteinColor    = Color(0xFF4CBF83);  // เขียว
static const Color carbsColor      = Color(0xFFFFB066);  // ส้ม
static const Color fatColor        = Color(0xFF8D9BFF);  // ม่วงอ่อน
static const Color waterColor      = Color(0xFF68BDEB);  // ฟ้า
static const Color calorieColor    = Color(0xFF4CBF83);  // เขียว

// ── Status Colors ──
static const Color success         = Color(0xFF39B980);
static const Color warning         = Color(0xFFFFB84D);
static const Color error           = Color(0xFFFF6F7D);

// ── AI Feature Colors ──
static const Color aiColor         = Color(0xFF8B73FF);  // ม่วง AI
static const Color aiBgColor       = Color(0xFFF4F0FF);  // พื้นม่วงอ่อน

// ── Card Border ──
static const Color cardBorder      = Color(0xFFE5F0DE);  // เขียวอ่อนมาก
```

### สีพิเศษสำหรับ Style A (เพิ่มเติม)

```dart
// ── Decorative Colors (ใหม่) ──
static const Color warmPeach       = Color(0xFFFFEEE9);  // พีชอ่อน (hero section)
static const Color warmMint        = Color(0xFFE9F8EF);  // มิ้นท์อ่อน
static const Color leafGreen       = Color(0xFF6BBF8A);  // เขียวใบไม้ตกแต่ง
static const Color leafDark        = Color(0xFF2D8A5E);  // เขียวใบไม้เข้ม
static const Color coralLight      = Color(0xFFFFD4CC);  // coral อ่อน (background accent)
static const Color warmOrange      = Color(0xFFFFA85C);  // ส้มอุ่น (highlight)
```

---

## 4. Design Tokens — Typography

### Font: Bai Jamjuree (Google Fonts)

ใช้ `GoogleFonts.baiJamjuree()` ทุกที่ ห้ามใช้ font อื่น

```dart
// ── Type Scale ──
headlineLarge:   fontSize: 30, fontWeight: w800, color: ink, height: 1.1
headlineMedium:  fontSize: 24, fontWeight: w800, color: ink, height: 1.15
titleLarge:      fontSize: 20, fontWeight: w700, color: ink
titleMedium:     fontSize: 17, fontWeight: w700, color: ink
bodyLarge:       fontSize: 15, fontWeight: w500, color: ink, height: 1.45
bodyMedium:      fontSize: 14, fontWeight: w500, color: ink, height: 1.45
bodySmall:       fontSize: 12, fontWeight: w500, color: mutedText, height: 1.4

// ── Custom Sizes ──
largeTitle:  28px  // ใช้สำหรับ hero title ในหน้าต่างๆ
title:       18px  // ใช้สำหรับ section header
body:        14px  // ใช้สำหรับ body text ทั่วไป
meta:        11px  // ใช้สำหรับ caption, badge label
```

### กฎ Typography

- **ตัวเลขแคลอรี่** ขนาดใหญ่เด่น: `fontSize: 36-48, fontWeight: w800`
- **หน่วย (kcal, กรัม, แก้ว)**: `fontSize: 12-14, fontWeight: w500, color: mutedText`
- **Label ใน input**: `fontSize: 13, fontWeight: w600, color: ink`
- **Placeholder**: `fontSize: 14, fontWeight: w500, color: mutedText.withOpacity(0.9)`
- **Button text**: `fontSize: 15, fontWeight: w700, color: Colors.white`

---

## 5. Design Tokens — Spacing & Radius

```dart
// ── Spacing ──
static const double pagePadding  = 16;   // ขอบซ้ายขวาหน้า
static const double sectionGap   = 18;   // ช่องว่างระหว่าง section
static const double cardPadding  = 20;   // padding ภายในการ์ด
static const double itemGap      = 12;   // ช่องว่างระหว่าง item ในการ์ด

// ── Border Radius ──
static const BorderRadius cardRadius  = BorderRadius.all(Radius.circular(24));   // การ์ดหลัก
static const BorderRadius innerRadius = BorderRadius.all(Radius.circular(18));   // input, button
static const BorderRadius pillRadius  = BorderRadius.all(Radius.circular(999));  // chips, pills, badges

// ── Button ──
static const double buttonHeight = 56;   // ปุ่มหลักสูง 56px
```

### Responsive Rules

```dart
// compact (< 380px): ลด padding, font size เล็กลง
// normal (380-700px): ค่า default
// tablet (>= 700px): เพิ่ม padding, max content width 640-720px

static double horizontalPaddingForWidth(double width) {
  if (width < 360) return 14;
  if (width < 700) return 16;
  return 24;
}

static double maxContentWidth(double width) {
  if (width < 700) return width;
  if (width < 1100) return 640;
  return 720;
}
```

---

## 6. Design Tokens — Shadows & Effects

```dart
// ── Soft Shadow (ใช้กับการ์ดทั่วไป) ──
static List<BoxShadow> softShadow(Color color) => [
  BoxShadow(
    color: color.withValues(alpha: 0.12),
    blurRadius: 28,
    spreadRadius: -4,
    offset: const Offset(0, 14),
  ),
];

// ── Elevated Card Shadow (สำหรับการ์ดที่ต้องการเด่น) ──
BoxShadow(
  color: primaryColor.withValues(alpha: 0.15),
  blurRadius: 32,
  spreadRadius: -6,
  offset: const Offset(0, 16),
)

// ── Glassmorphism Blur ──
// ใช้ BackdropFilter กับ ImageFilter.blur(sigmaX: 12, sigmaY: 12)
// บน Container สี Colors.white.withValues(alpha: 0.10 - 0.20)
```

---

## 7. Design Tokens — Gradients

```dart
// ── Primary Gradient (ปุ่มหลัก, calorie ring) ──
static const LinearGradient primaryGradient = LinearGradient(
  colors: [Color(0xFF4CBF83), Color(0xFFA7E8C4)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// ── Accent Gradient (coral, ไฮไลท์) ──
static const LinearGradient accentGradient = LinearGradient(
  colors: [Color(0xFFFF8A7A), Color(0xFFFFC47C)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// ── AI Gradient (AI Coach features) ──
static const LinearGradient aiGradient = LinearGradient(
  colors: [Color(0xFFA58CFF), Color(0xFF8B73FF)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// ── Calorie Ring Gradient (วงแหวนแคลอรี่ใน dashboard) ──
// ใช้สีจาก เขียว → เขียวอ่อน → ส้ม เพื่อแสดง progress
static const LinearGradient calorieRingGradient = LinearGradient(
  colors: [Color(0xFF4CBF83), Color(0xFFA7E8C4), Color(0xFFFFB066)],
);

// ── Page Background Gradient ──
static LinearGradient pageBackground() {
  return const LinearGradient(
    colors: [
      Color(0xFFFBF8F0),  // ครีม (top)
      Color(0xFFF8F5EC),  // ครีมอ่อน (middle)
      Color(0xFFF2F8ED),  // เขียวอ่อนมาก (bottom)
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

// ── Hero Section Gradient (Login, Onboarding header) ──
static const LinearGradient heroGradient = LinearGradient(
  colors: [Color(0xFFFFEEE9), Color(0xFFEFF8E9)],  // พีช → มิ้นท์
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// ── Glass Card Gradient ──
static LinearGradient glassGradient({double opacity = 0.1}) {
  return LinearGradient(
    colors: [
      Colors.white.withValues(alpha: opacity * 1.5),
      Colors.white.withValues(alpha: opacity),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
```

---

## 8. Decorative Elements (ตกแต่ง)

### แนวคิด
Style A ใช้ **ภาพวาดธรรมชาติ** เป็นองค์ประกอบตกแต่ง ทำได้โดยใช้ **CustomPaint** หรือ **Container shapes** วาดรูปใบไม้/วงกลม abstract

### วิธี Implement: ใช้ Container + ClipPath หรือ Positioned widgets

```dart
/// ใบไม้ตกแต่งมุมการ์ด — ใช้ Container วงรีซ้อนกัน
Widget _buildLeafDecoration({
  required Alignment alignment,
  Color color = const Color(0xFF4CBF83),
  double size = 60,
}) {
  return Positioned(
    top: alignment == Alignment.topRight ? -size * 0.3 : null,
    right: alignment == Alignment.topRight ? -size * 0.3 : null,
    bottom: alignment == Alignment.bottomLeft ? -size * 0.3 : null,
    left: alignment == Alignment.bottomLeft ? -size * 0.3 : null,
    child: Transform.rotate(
      angle: 0.5,
      child: Container(
        width: size,
        height: size * 1.4,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(size),
        ),
      ),
    ),
  );
}
```

### ตำแหน่งที่ต้องมี decorative elements

| หน้า | ตำแหน่ง | ชนิด |
|------|---------|------|
| Login | มุมบนขวาของ hero card | วงรี peach + ใบไม้เขียว |
| Login | มุมล่างขวาของฟอร์ม | ใบไม้เขียว+coral เล็ก |
| Onboarding | ซ้าย-ขวาของ form card | ใบไม้เขียว + แครอทส้ม |
| Home Dashboard | มุมซ้ายของ hero card | ใบไม้เขียวเข้ม |
| Home Dashboard | ระหว่าง sections | ใบไม้เล็กๆ ประปราย |
| Tracking | header banner | ภาพอาหารไทย (ถ้ามี asset) หรือ ใบไม้ |
| Tracking | มุมล่างของหน้า | ใบไม้เขียว |
| Profile | hero card background | วงกลม gradient peach + mint |
| AI Coach | hero card | sparkle particles |
| Content | article card corners | ใบไม้เล็ก |

### สำคัญ: ถ้าไม่มี asset รูปภาพ ให้ใช้ Container + BoxDecoration + Transform.rotate สร้างรูปทรง abstract แทน อย่าอ้างอิงไฟล์ที่ไม่มีอยู่จริง

---

## 9. Component Library

### 9.1 GlassCard (`lib/widgets/glass_card.dart`)

การ์ดกึ่งโปร่งแสงสไตล์ glassmorphism — ใช้เป็น container หลักทุกที่

```
สถานะปัจจุบัน: ✅ มีอยู่แล้ว
แก้ไข: ปรับค่า default opacity ให้อบอุ่นขึ้น
```

**Spec:**
- `BackdropFilter` blur: `sigmaX: 12, sigmaY: 12`
- Background: `Colors.white.withValues(alpha: 0.10 - 0.20)` (ปรับตาม context)
- Border: `Border.all(color: Color(0x3DFFFFFF), width: 1.5)`
- BorderRadius: `24`
- Shadow: `softShadow(primaryColor)`

**การใช้งาน:**
- **opacity: 0.08-0.10** — การ์ดพื้นหลังอ่อน (water card, tip card)
- **opacity: 0.12-0.15** — การ์ดทั่วไป (food card, macro card)
- **opacity: 0.18-0.20** — การ์ดเด่น (hero card, form card)

---

### 9.2 GradientButton (`lib/widgets/gradient_button.dart`)

ปุ่มหลักที่มี gradient + animation กดย่อ

```
สถานะปัจจุบัน: ✅ มีอยู่แล้ว
แก้ไข: ไม่ต้องแก้ไข
```

**Spec:**
- Gradient: `primaryGradient` (เขียว → เขียวอ่อน)
- Height: `56px`
- BorderRadius: `18`
- Text: `fontSize: 15, fontWeight: w700, color: white`
- Animation: `scale 0.97` เมื่อกด
- Icon: optional trailing icon (เช่น `LucideIcons.arrowRight`)
- Loading state: แสดง `CircularProgressIndicator` สีขาว

---

### 9.3 AppIconBubble (`lib/widgets/app_icon_bubble.dart`)

วงกลมใส่ icon — ใช้กับทุก icon ในการ์ด

```
สถานะปัจจุบัน: ✅ มีอยู่แล้ว
แก้ไข: ไม่ต้องแก้ไข
```

**Spec:**
- Shape: `BoxShape.circle`
- Background: `color.withValues(alpha: 0.12)`
- Size: `40-48px` (default 40)
- Icon size: `20-22px`
- Icon color: ใช้สีเดียวกับ background แต่ opacity 1.0

---

### 9.4 TubeProgressBar (`lib/widgets/tube_progress_bar.dart`)

Progress bar แบบท่อกลมมน

```
สถานะปัจจุบัน: ✅ มีอยู่แล้ว
แก้ไข: ไม่ต้องแก้ไข
```

**Spec:**
- Height: `12-14px`
- BorderRadius: `pill (999)`
- Background: สีอ่อนของ fill color (`fillColor.withValues(alpha: 0.12)`)
- Fill: `LinearGradient` ของ fill color
- Animation: `Tween<double>` smooth 600ms

---

### 9.5 AppCard (`lib/widgets/app_card.dart`)

การ์ดทึบ (ไม่ glass) — ใช้สำหรับ item ย่อยภายในการ์ดใหญ่

```
สถานะปัจจุบัน: ✅ มีอยู่แล้ว
แก้ไข: ไม่ต้องแก้ไข
```

**Spec:**
- Background: `white`
- Border: `1px solid #E5F0DE`
- BorderRadius: `24`
- Shadow: `softShadow(primaryColor)`
- Padding: `20px`

---

### 9.6 AppSectionHeader (`lib/widgets/app_section_header.dart`)

Section header ที่มี chip title + subtitle

```
สถานะปัจจุบัน: ✅ มีอยู่แล้ว
แก้ไข: ไม่ต้องแก้ไข
```

**Spec:**
- Title: ใน `AppChip` (pill badge) 
- Subtitle: `bodySmall`, color `mutedText`
- Spacing: `4px` ระหว่าง chip กับ subtitle

---

### 9.7 AnimatedPageWrapper (`lib/widgets/animated_page_wrapper.dart`)

Wrapper สำหรับทุกหน้า — จัดการ entrance animation + background gradient

```
สถานะปัจจุบัน: ✅ มีอยู่แล้ว
แก้ไข: ตรวจสอบว่าใช้ pageBackground() gradient อยู่
```

**Spec:**
- Fade in: `300ms`, curve `easeOut`
- Slide up: `offset (0, 0.02)`, `300ms`
- Background: `AppTheme.pageBackground()` gradient

---

### 9.8 EditFoodDialog (`lib/widgets/edit_food_dialog.dart`)

Bottom sheet แก้ไขรายการอาหาร

```
สถานะปัจจุบัน: ✅ มีอยู่แล้ว
แก้ไข: ปรับ border radius, สี background ให้เป็น pageBg
```

**Spec:**
- Background: `pageBg` (ครีม)
- Top border radius: `28`
- Handle bar: `40 × 4px`, color `#E5F0DE`, radius `pill`
- Input fields: ใช้ theme InputDecorationTheme
- Meal chips: เหมือน tracking screen
- Save button: `GradientButton`

---

## 10. หน้า Login — `login_screen.dart`

### Layout (บนลงล่าง)

```
SafeArea > Center > ConstrainedBox(maxWidth) > SingleChildScrollView > Column
├── [GlassCard opacity:0.12] Hero Header
│   ├── Circular Logo Badge (gradient peach→mint, heart icon)
│   ├── 🌿 Decorative leaves around badge
│   ├── Title: "ยินดีต้อนรับกลับมา" (headlineMedium)
│   ├── Subtitle: "สุขภาพดี เริ่มต้นได้ที่นี่" (bodyMedium, mutedText)
│   └── 3× Feature Chips: "ติดตามง่าย", "โทนน่ารัก", "ใช้ทุกวันสบาย"
│
├── [GlassCard opacity:0.18] Login Form
│   ├── Form Title: "ยินดีต้อนรับกลับ" (titleLarge)
│   ├── Subtitle: "เข้าสู่ระบบเพื่อจัดการสุขภาพ..." (bodySmall)
│   ├── ❌ Error Banner (conditional) — red tinted box
│   ├── Email TextField (icon: LucideIcons.mail)
│   ├── Password TextField (icon: LucideIcons.lock)
│   ├── "ลืมรหัสผ่าน?" TextButton (right-aligned)
│   ├── Remember Me Checkbox
│   ├── GradientButton "เข้าสู่ระบบ" (icon: arrowRight)
│   ├── Divider "หรือ"
│   ├── Google Sign-In OutlinedButton (icon: G badge)
│   └── "ยังไม่มีบัญชี? สมัครสมาชิก" TextButton
│
└── 🌿 Bottom leaf decoration (positioned, small)
```

### Hero Section Detail

```dart
// Logo Badge
Container(
  width: 80, height: 80,
  decoration: BoxDecoration(
    gradient: heroGradient,  // peach → mint
    shape: BoxShape.circle,
    boxShadow: [BoxShadow(color: primaryColor.withValues(alpha: 0.2), blurRadius: 20)],
  ),
  child: Icon(LucideIcons.heart, color: accentColor, size: 36),
)
```

### Feature Chips

```dart
// Pill chip สำหรับ feature highlights
Container(
  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
  decoration: BoxDecoration(
    color: Colors.white.withValues(alpha: 0.7),
    borderRadius: pillRadius,
    border: Border.all(color: primaryColor.withValues(alpha: 0.16)),
  ),
  child: Text("ติดตามง่าย", style: bodySmall.copyWith(color: primaryColor)),
)
```

### Input Fields Style

```dart
// ใช้ Theme InputDecorationTheme เป็นหลัก เพิ่มเติม:
// prefix icon ใส่ใน AppIconBubble ขนาด 32px
// hint text สี mutedText opacity 0.7
// fill color: Colors.white
// border: 1px solid #E5F0DE → focus: primaryColor.withValues(alpha: 0.3)
// border radius: 18
```

---

## 11. หน้า Register — `register_screen.dart`

### Layout

เหมือน Login แต่ฟอร์มมีเพิ่ม:
- Confirm Password field
- ไม่มี forgot password link
- ไม่มี remember me
- ไม่มี Google sign-in
- ปุ่ม: "สมัครสมาชิก"
- ลิงก์: "มีบัญชีอยู่แล้ว? เข้าสู่ระบบ"

---

## 12. หน้า Onboarding — `onboarding_screen.dart`

### Layout (บนลงล่าง)

```
SafeArea > Center > ConstrainedBox > Padding > Column
├── Step Indicator (4 pills)
├── Header Text
│   ├── Title: "ยินดีต้อนรับ!" (headlineLarge)
│   └── Subtitle: "เรามาตั้งค่าเป้าหมายสุขภาพ..." (bodyMedium, mutedText)
│
├── [Expanded > ScrollView > GlassCard opacity:0.15]
│   ├── Step 1: Basic Info
│   │   ├── Nickname TextField (icon: LucideIcons.user)
│   │   └── Gender Selector: 2 pills (ชาย/หญิง) side-by-side
│   │
│   ├── Step 2: Body Metrics
│   │   ├── Row: เดือนเกิด + ปีเกิด (icon: calendar)
│   │   ├── Row: ส่วนสูง + น้ำหนัก (icon: ruler, scale)
│   │   └── Full: น้ำหนักเป้าหมาย (icon: target)
│   │
│   ├── Step 3: Activity Level
│   │   └── 4 selectable cards (icon + title + description)
│   │       ├── 🧘 นั่งอยู่กับที่
│   │       ├── 🚶 ออกกำลังกายเบาๆ
│   │       ├── 🏃 ออกกำลังกายปานกลาง
│   │       └── 💪 ออกกำลังกายหนัก
│   │
│   └── Step 4: Health Goal
│       └── 3 selectable cards
│           ├── ⚖️ ลดน้ำหนัก
│           ├── 🎯 รักษาน้ำหนัก
│           └── 💪 เพิ่มกล้ามเนื้อ
│
├── 🌿 Decorative leaves (positioned left + right)
│
└── GradientButton "ถัดไป" / "เริ่มต้นใช้งาน" (step 4)
```

### Step Indicator Spec

```dart
// 4 pills in a Row
AnimatedContainer(
  width: isActive ? 32 : 12,
  height: 6,
  decoration: BoxDecoration(
    color: isActive ? primaryColor : primaryColor.withValues(alpha: 0.2),
    borderRadius: pillRadius,
  ),
)
// gap between pills: 6px
```

### Selectable Option Card

```dart
// สำหรับ Activity Level & Health Goal
AnimatedContainer(
  padding: EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: isSelected
        ? primaryColor.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.5),
    borderRadius: cardRadius,
    border: Border.all(
      color: isSelected ? primaryColor : cardBorder,
      width: isSelected ? 2 : 1,
    ),
    boxShadow: isSelected ? softShadow(primaryColor) : [],
  ),
  child: Row(children: [
    AppIconBubble(icon, color: isSelected ? primaryColor : mutedText),
    SizedBox(width: 12),
    Column(children: [
      Text(title, style: titleMedium),
      Text(description, style: bodySmall),
    ]),
  ]),
)
```

---

## 13. หน้า Home Dashboard — `home_screen.dart`

### Layout (บนลงล่าง — scroll)

```
Container(gradient: pageBackground) > ConstrainedBox > SingleChildScrollView > Column
│
├── DailyReminderColumn (ถ้ามี reminder ค้าง)
│
├── [GlassCard] Hero Calorie Card ★
│   ├── Header: "แดชบอร์ดวันนี้" (headlineMedium)
│   ├── Status text: "สมดุลดี!" / "เกินเป้า" (bodyMedium, primary/error)
│   ├── 🌿 Decorative illustration (มุมขวาบน — ผู้หญิงกับอาหาร หรือ leaf abstract)
│   │
│   ├── Circular Calorie Gauge ★★★
│   │   ├── Outer ring: CircularProgressIndicator
│   │   │   ├── Background track: primaryColor.withValues(alpha: 0.12), stroke 12
│   │   │   └── Progress ring: gradient เขียว→ส้ม, stroke 12, strokeCap: round
│   │   ├── Center: LucideIcons.zap (สีเขียว ถ้าปกติ / สีแดง ถ้าเกิน)
│   │   ├── Center text: "1,250" (fontSize: 42, w800)
│   │   └── Center sub: "/ 1,800 kcal" (fontSize: 14, mutedText)
│   │
│   └── Row: 2× StatChip
│       ├── "เหลืออีก 550 kcal" (icon: LucideIcons.target, color: primary)
│       └── "น้ำดื่ม 5/8 แก้ว" (icon: LucideIcons.droplet, color: waterColor)
│
├── AppSectionHeader "ภาพรวมสารอาหาร"
│
├── Horizontal ScrollView: 3× MacroCard
│   ├── โปรตีน (proteinColor, icon: LucideIcons.beef)
│   │   ├── AppIconBubble
│   │   ├── Label "โปรตีน" + "45 / 90 g"
│   │   ├── TubeProgressBar
│   │   └── Remaining: "เหลือ 45g"
│   ├── คาร์บ (carbsColor, icon: LucideIcons.wheat)
│   └── ไขมัน (fatColor, icon: LucideIcons.droplets)
│
├── AppSectionHeader "ทางลัดประจำวัน"
│
├── Row/Wrap: 3× ActionCard
│   ├── "เพิ่มอาหาร" (primaryColor, icon: LucideIcons.plus) → tab 1
│   ├── "ออกกำลังกาย" (warmOrange, icon: LucideIcons.play) → tab 2
│   └── "AI Coach" (aiColor, icon: LucideIcons.messageSquare) → AICoachScreen
│
├── [AppCard] 7-Day Chart ★
│   ├── Header: "แนวโน้ม 7 วัน"
│   ├── Badge: "เป้าหมายรายวัน"
│   └── BarChart (fl_chart)
│       ├── 7 bars with gradient fill
│       ├── Thai weekday labels (จ, อ, พ, พฤ, ศ, ส, อา / "วันนี้")
│       ├── Target line: dashed horizontal
│       └── Over-budget bars: error color
│
├── Row: 2× split cards
│   ├── [AppCard] Water Card
│   │   ├── AppIconBubble(droplet, waterColor)
│   │   ├── "น้ำดื่มวันนี้"
│   │   ├── "5 / 8 แก้ว"
│   │   ├── TubeProgressBar (waterColor)
│   │   └── Status text
│   │
│   └── [AppCard] Tip Card
│       ├── AppIconBubble(lightbulb, warning)
│       ├── "Tip วันนี้"
│       └── Rotating tip text
│
└── SizedBox(height: 100) // space for bottom nav
```

### Calorie Ring Implementation Notes

```dart
// วงแหวนแคลอรี่ ใช้ Stack + CircularProgressIndicator แบบ 2 ชั้น
Stack(
  alignment: Alignment.center,
  children: [
    // Background ring
    SizedBox(
      width: 200, height: 200,
      child: CircularProgressIndicator(
        value: 1.0,
        strokeWidth: 14,
        color: primaryColor.withValues(alpha: 0.12),
        strokeCap: StrokeCap.round,
      ),
    ),
    // Progress ring
    SizedBox(
      width: 200, height: 200,
      child: CircularProgressIndicator(
        value: progress.clamp(0.0, 1.0),
        strokeWidth: 14,
        color: progress > 1.0 ? error : primaryColor,
        strokeCap: StrokeCap.round,
      ),
    ),
    // Center content
    Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(LucideIcons.zap, size: 24, color: primaryColor),
      Text("1,250", style: TextStyle(fontSize: 42, fontWeight: FontWeight.w800)),
      Text("/ 1,800 kcal", style: TextStyle(fontSize: 14, color: mutedText)),
    ]),
  ],
)
```

### Bar Chart Style

```dart
// fl_chart BarChart styling
BarChartGroupData(
  x: index,
  barRods: [
    BarChartRodData(
      toY: value,
      width: 24,
      borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      gradient: isOverBudget
          ? LinearGradient(colors: [error, error.withValues(alpha: 0.7)])
          : primaryGradient,
      backDrawRodData: BackgroundBarChartRodData(
        show: true,
        toY: targetCalories,
        color: primaryColor.withValues(alpha: 0.06),
      ),
    ),
  ],
)
// Target line
HorizontalLine(
  y: targetCalories,
  color: primaryColor.withValues(alpha: 0.3),
  strokeWidth: 1.5,
  dashArray: [6, 4],
)
```

---

## 14. หน้า Tracking — `tracking_screen.dart`

### Layout (บนลงล่าง — scroll)

```
Container(gradient: pageBackground) > ConstrainedBox > SingleChildScrollView > Column
│
├── [GlassCard opacity:0.20] Header Banner
│   ├── "บันทึกประจำวัน" (headlineMedium)
│   ├── Subtitle description
│   └── 🌿 Decorative food illustration (มุมขวาบน)
│
├── [GlassCard opacity:0.15] Food Logging Card ★★★
│   ├── Header Row
│   │   ├── AppIconBubble(utensils, primaryColor)
│   │   ├── "บันทึกอาหาร" (titleMedium)
│   │   └── TextButton.icon "สแกน" (icon: camera, accentColor)
│   │
│   ├── NutritionSourceBadge (conditional)
│   │
│   ├── Search TextField
│   │   ├── prefix: LucideIcons.search
│   │   └── suffix: sparkles button (AI estimate)
│   │
│   ├── Horizontal ScrollView: Food Chips
│   │   ├── Custom foods (icon: star, color: warning)
│   │   └── Recent foods (icon: clock, color: mutedText)
│   │
│   ├── Calorie TextField (icon: LucideIcons.zap)
│   │
│   ├── Row: 3× Macro Fields
│   │   ├── โปรตีน (กรัม) — proteinColor
│   │   ├── คาร์บ (กรัม) — carbsColor
│   │   └── ไขมัน (กรัม) — fatColor
│   │
│   ├── Meal Type Selector (horizontal scroll)
│   │   ├── เช้า (icon: sunrise, color: warmOrange)      ← selected: filled
│   │   ├── กลางวัน (icon: sun, color: warning)
│   │   ├── เย็น (icon: sunset, color: accentColor)
│   │   └── ว่าง (icon: coffee, color: mutedText)
│   │
│   ├── GradientButton "เพิ่มรายการอาหาร" (icon: plus)
│   │
│   └── Today's Food List (conditional)
│       ├── Header: "มื้อวันนี้" + count badge
│       └── List: up to 5× FoodItemTile
│           ├── Food emoji/icon + name + calories
│           ├── Swipe left: delete (trash icon, red bg)
│           └── Tap: open EditFoodDialog
│
├── [GlassCard opacity:0.12] Water Intake Card
│   ├── Header Row
│   │   ├── AppIconBubble(droplet, waterColor)
│   │   ├── "ดื่มน้ำ (เป้าหมาย X แก้ว)" (titleMedium)
│   │   └── Large counter: "5" (fontSize: 36, w800)
│   │
│   ├── TubeProgressBar (waterColor)
│   │
│   └── Wrap: 4× Quick Buttons
│       ├── "−" OutlinedButton (subtract 1)
│       ├── "+ 1 แก้ว" (filled, waterColor)
│       ├── "+ 500 มล" (filled, waterColor lighter)
│       └── "+ 1.5 ลิตร" (filled, waterColor lightest)
│
└── SizedBox(height: 100)
```

### Meal Chip Spec

```dart
// Meal type selector chip
AnimatedContainer(
  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
  decoration: BoxDecoration(
    color: isSelected ? mealColor : mealColor.withValues(alpha: 0.08),
    borderRadius: innerRadius,
    border: Border.all(
      color: isSelected ? mealColor : mealColor.withValues(alpha: 0.2),
    ),
    boxShadow: isSelected ? softShadow(mealColor) : [],
  ),
  child: Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(mealIcon, size: 16,
         color: isSelected ? Colors.white : mealColor),
    SizedBox(width: 6),
    Text(mealLabel, style: TextStyle(
      fontSize: 13, fontWeight: FontWeight.w600,
      color: isSelected ? Colors.white : mealColor,
    )),
  ]),
)
```

### Water Quick Button Spec

```dart
// Quick action button
Container(
  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
  decoration: BoxDecoration(
    color: isFilled ? waterColor : Colors.transparent,
    borderRadius: innerRadius,
    border: Border.all(
      color: waterColor.withValues(alpha: isFilled ? 1.0 : 0.3),
    ),
  ),
  child: Text(label, style: TextStyle(
    fontSize: 13, fontWeight: FontWeight.w700,
    color: isFilled ? Colors.white : waterColor,
  )),
)
```

---

## 15. หน้า Content — `content_screen.dart`

### Layout

```
AnimatedPageWrapper > ConstrainedBox > CustomScrollView
│
├── [GlassCard] Hero Card "เรียนรู้และขยับ"
│   ├── Sparkles icon
│   ├── "X คลิปพร้อมดู" + "วันนี้ทำไป X ครั้ง"
│   └── 🌿 Decorative elements
│
├── AppSectionHeader "บทความน่าอ่าน"
│
├── Horizontal ScrollView: Article Cards
│   └── [GlassCard] per article
│       ├── Thumbnail Image (borderRadius: 16 top)
│       ├── Category AppChip
│       ├── Title (titleMedium)
│       └── Tap → ArticleDetailScreen
│
├── AppSectionHeader "คลังวิดีโอ"
│   └── Difficulty Filter Dropdown
│
└── Vertical List: Workout Cards
    └── [AppCard] per workout
        ├── YouTube Thumbnail (play overlay icon)
        ├── Difficulty Badge (color-coded)
        ├── Duration + Type Tags
        └── Action Button ("เริ่มเลย" / "จบ workout")
```

---

## 16. หน้า Profile — `profile_screen.dart`

### Layout

```
Container(gradient: pageBackground) > ConstrainedBox > SingleChildScrollView > Column
│
├── [GlassCard opacity:0.15] Hero Profile Card ★
│   ├── Edit Toggle Button (มุมขวาบน)
│   ├── Avatar (100×100 circle)
│   │   ├── Profile image / fallback initial letter
│   │   ├── Camera badge overlay (มุมขวาล่าง)
│   │   └── 🌿 Circular gradient background (peach → mint)
│   ├── Display Name (titleLarge)
│   ├── Health Goal label (bodySmall)
│   ├── "ประมาณ X วันถึงเป้าหมาย" (bodySmall)
│   └── Glass badge: sparkles icon + goal summary text
│
├── AppSectionHeader "ภาพรวมของคุณ"
│
├── GridView.count(2): 4× Metric Cards
│   ├── เป้าแคลอรี่ (icon: target, primaryColor)    — "X kcal"
│   ├── TDEE (icon: flame, warmOrange)               — "X kcal"
│   ├── น้ำดื่ม (icon: droplets, waterColor)         — "X แก้ว/วัน"
│   └── Streak (icon: badgeCheck, warning)            — "X วัน"
│
├── [GlassCard] Body Data Panel
│   ├── Header: "ข้อมูลร่างกาย" + Save button (edit mode)
│   └── GridView/Column:
│       ├── View Mode: Info cards (น้ำหนัก, ส่วนสูง, น้ำหนักเป้า, อายุ, เป้าหมาย)
│       └── Edit Mode: Input fields with formatters
│
├── [GlassCard] Reminder Settings
│   ├── Toggle: เตือนดื่มน้ำ
│   ├── Toggle: เตือนบันทึกอาหาร
│   └── Toggle: เตือนชั่งน้ำหนัก
│
├── [GlassCard] Feedback Card → FeedbackScreen
│
├── [GlassCard] Admin Card (conditional, role == admin)
│
└── [GlassCard] Logout Card (red-tinted border)
```

### Avatar Spec

```dart
// Profile avatar with camera overlay
Stack(children: [
  Container(
    width: 100, height: 100,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: heroGradient,  // peach → mint
      border: Border.all(color: Colors.white, width: 3),
      boxShadow: softShadow(primaryColor),
    ),
    child: ClipOval(child: profileImage ?? _initialLetter()),
  ),
  Positioned(
    right: 0, bottom: 0,
    child: Container(
      width: 32, height: 32,
      decoration: BoxDecoration(
        color: primaryColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Icon(LucideIcons.camera, size: 14, color: Colors.white),
    ),
  ),
])
```

---

## 17. หน้า AI Coach — `ai_coach_screen.dart`

### Layout

```
AnimatedPageWrapper > Column
│
├── AppBar
│   ├── Title: "AI Coach" (titleLarge)
│   └── Action: Star icon → FeedbackScreen
│
├── [Expanded] CustomScrollView (maxWidth constrained)
│   │
│   ├── [GlassCard] Hero Intro Card ★
│   │   ├── Sparkles AppIconBubble (aiColor)
│   │   ├── Title: "AI Coach ของคุณ" (titleLarge)
│   │   ├── Description text
│   │   └── Row: 3× Topic Pills
│   │       ├── ⚖️ "น้ำหนักคงที่" (icon: scale)
│   │       ├── 🥩 "โปรตีนไม่ถึง" (icon: beef)
│   │       └── 💧 "ดื่มน้ำน้อย" (icon: droplets)
│   │
│   ├── [if no messages] Quick Prompts Card
│   │   └── 4× Prompt Cards (icon: messageCircle + arrowRight)
│   │       ├── "วันนี้กินอะไรดี?"
│   │       ├── "ออกกำลังกายแบบไหนเหมาะ?"
│   │       ├── "แคลอรี่วันนี้เป็นอย่างไร?"
│   │       └── "อยากลดน้ำหนักต้องทำยังไง?"
│   │
│   └── [if has messages] Chat Message Feed
│       ├── User Bubble (right-aligned)
│       │   ├── gradient: primaryGradient
│       │   ├── text: white
│       │   ├── borderRadius: 18,18,4,18 (sharp bottom-right)
│       │   └── max-width: 80%
│       │
│       ├── AI Bubble (left-aligned)
│       │   ├── background: white
│       │   ├── border: 1px cardBorder
│       │   ├── text: ink
│       │   ├── borderRadius: 18,18,18,4 (sharp bottom-left)
│       │   └── max-width: 85%
│       │
│       └── Loading Indicator (left-aligned, CircularProgressIndicator)
│
└── Bottom Input Bar (pinned)
    ├── Container (white bg, top borderRadius: 20, border top: cardBorder)
    ├── Row
    │   ├── [Expanded] TextField (1-4 lines, pill border radius: 24)
    │   └── Animated Send Button
    │       ├── CircleAvatar(radius: 22)
    │       ├── gradient: primaryGradient
    │       └── icon: LucideIcons.send / loader2 (loading)
    └── SafeArea bottom padding
```

### Chat Bubble Spec

```dart
// User bubble
Container(
  constraints: BoxConstraints(maxWidth: screenWidth * 0.8),
  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  decoration: BoxDecoration(
    gradient: primaryGradient,
    borderRadius: BorderRadius.only(
      topLeft: Radius.circular(18),
      topRight: Radius.circular(18),
      bottomLeft: Radius.circular(18),
      bottomRight: Radius.circular(4),  // sharp corner
    ),
    boxShadow: softShadow(primaryColor),
  ),
  child: Text(message, style: TextStyle(color: Colors.white, fontSize: 14)),
)

// AI bubble
Container(
  constraints: BoxConstraints(maxWidth: screenWidth * 0.85),
  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.only(
      topLeft: Radius.circular(18),
      topRight: Radius.circular(18),
      bottomLeft: Radius.circular(4),  // sharp corner
      bottomRight: Radius.circular(18),
    ),
    border: Border.all(color: cardBorder),
    boxShadow: softShadow(aiColor),
  ),
  child: Text(message, style: TextStyle(color: ink, fontSize: 14)),
)
```

### Topic Pill Spec

```dart
Container(
  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  decoration: BoxDecoration(
    color: aiColor.withValues(alpha: 0.08),
    borderRadius: pillRadius,
    border: Border.all(color: aiColor.withValues(alpha: 0.2)),
  ),
  child: Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 14, color: aiColor),
    SizedBox(width: 4),
    Text(label, style: TextStyle(fontSize: 12, color: aiColor, fontWeight: FontWeight.w600)),
  ]),
)
```

---

## 18. Bottom Navigation Bar — `main_screen.dart`

### Spec

```
ตำแหน่งปัจจุบัน: ใช้ GlassCard เป็น floating nav bar
```

### Layout

```
Positioned(bottom: 0, left/right: pagePadding)
└── GlassCard (opacity: 0.25, blur: 16)
    └── SafeArea > Row(mainAxisAlignment: spaceAround)
        ├── NavItem: หน้าแรก (icon: LucideIcons.home, index: 0)
        ├── NavItem: บันทึก (icon: LucideIcons.bookOpen, index: 1)
        ├── Scan Button (center, elevated) ★
        │   ├── Container(width: 56, height: 56)
        │   ├── gradient: primaryGradient
        │   ├── shape: circle
        │   ├── shadow: softShadow(primaryColor)
        │   ├── icon: LucideIcons.scan (white)
        │   └── action: trigger camera scan in tab 1
        ├── NavItem: เนื้อหา (icon: LucideIcons.bookHeart, index: 2)
        └── NavItem: โปรไฟล์ (icon: LucideIcons.user, index: 3)
```

### NavItem Spec

```dart
// Active state
Column(mainAxisSize: MainAxisSize.min, children: [
  AnimatedContainer(
    width: isActive ? 28 : 0,
    height: 3,
    decoration: BoxDecoration(
      color: primaryColor,
      borderRadius: pillRadius,
    ),
  ),
  SizedBox(height: 4),
  Icon(icon, size: 22, color: isActive ? primaryColor : mutedText),
  SizedBox(height: 2),
  Text(label, style: TextStyle(
    fontSize: 10,
    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
    color: isActive ? primaryColor : mutedText,
  )),
])
```

---

## 19. Animation & Micro-interactions

### ทุกหน้า

| Animation | Duration | Curve | ที่ใช้ |
|-----------|----------|-------|--------|
| Page entrance fade | 300ms | easeOut | AnimatedPageWrapper |
| Page entrance slide up | 300ms | easeOut | AnimatedPageWrapper |
| Button press scale | 150ms | easeInOut | GradientButton (0.97) |
| Card selection glow | 200ms | easeOut | Onboarding options, meal chips |
| Step indicator width | 300ms | easeInOut | Onboarding step pills |
| Progress bar fill | 600ms | easeOut | TubeProgressBar |
| Counter number change | 300ms | - | Water glasses, calorie count |

### Transition ระหว่างหน้า

```dart
// ใช้ MaterialPageRoute ปกติ (default slide transition)
// หรือถ้าต้องการ custom:
PageRouteBuilder(
  pageBuilder: (_, __, ___) => TargetScreen(),
  transitionsBuilder: (_, animation, __, child) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween(begin: Offset(0, 0.03), end: Offset.zero)
            .animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
        child: child,
      ),
    );
  },
  transitionDuration: Duration(milliseconds: 300),
)
```

---

## 20. ไฟล์ที่ต้องแก้ไข (สรุป)

### Priority 1: Theme & Components (แก้ก่อน)

| ไฟล์ | สิ่งที่ต้องทำ |
|------|--------------|
| `lib/app_theme.dart` | เพิ่มสี decorative (warmPeach, warmMint, leafGreen ฯลฯ), เพิ่ม heroGradient, ปรับ pageBackground gradient ให้อบอุ่นขึ้น |
| `lib/widgets/glass_card.dart` | ตรวจสอบว่า default values ตรงตาม spec |
| `lib/widgets/animated_page_wrapper.dart` | ตรวจสอบว่าใช้ pageBackground() |

### Priority 2: Auth & Onboarding Screens

| ไฟล์ | สิ่งที่ต้องทำ |
|------|--------------|
| `lib/screens/login_screen.dart` | เพิ่ม hero section decoration, ปรับ glassmorphism, เพิ่มใบไม้ตกแต่ง |
| `lib/screens/register_screen.dart` | เพิ่ม decoration เหมือน login |
| `lib/screens/onboarding_screen.dart` | เพิ่มใบไม้ตกแต่ง, ปรับ selection card style |

### Priority 3: Main Screens

| ไฟล์ | สิ่งที่ต้องทำ |
|------|--------------|
| `lib/screens/home_screen.dart` | ปรับ hero card ให้มี illustration/decoration, ปรับ calorie ring gradient, ปรับ bar chart สี |
| `lib/screens/tracking_screen.dart` | เพิ่ม header illustration, ปรับ meal chips สี, เพิ่มใบไม้ตกแต่ง |
| `lib/screens/content_screen.dart` | เพิ่ม decoration ตามสไตล์ |
| `lib/screens/profile_screen.dart` | ปรับ avatar gradient background, เพิ่ม hero section decoration |
| `lib/screens/ai_coach_screen.dart` | ปรับ chat bubble style, เพิ่ม sparkle decoration |

### Priority 4: Navigation & Supporting

| ไฟล์ | สิ่งที่ต้องทำ |
|------|--------------|
| `lib/main_screen.dart` | ปรับ bottom nav ให้ตรง spec (scan button center) |
| `lib/screens/history_screen.dart` | ใช้ style เดียวกัน (glass card + decoration) |
| `lib/screens/weight_screen.dart` | ใช้ style เดียวกัน |
| `lib/screens/feedback_screen.dart` | ใช้ style เดียวกัน |
| `lib/screens/custom_food_screen.dart` | ใช้ style เดียวกัน |
| `lib/widgets/edit_food_dialog.dart` | ปรับ background เป็น pageBg |

### ไม่ต้องแก้ไข

| ไฟล์/โฟลเดอร์ | เหตุผล |
|---------------|--------|
| `lib/services/*` | Business logic ไม่เกี่ยวกับ UI |
| `lib/models/*` | Data models ไม่เกี่ยวกับ UI |
| `lib/utils/*` | Helpers ไม่เกี่ยวกับ UI |
| `lib/constants/*` | Config values ไม่ต้องเปลี่ยน |
| `lib/firebase_options.dart` | Firebase config |

---

## ⚠️ ข้อควรระวังสำหรับ AI ที่แก้ไข

1. **อย่าลบ logic เดิม** — แก้เฉพาะส่วน UI/visual ห้ามแก้ business logic, service calls, state management
2. **อย่าเพิ่ม package ใหม่** — ใช้เฉพาะ package ที่มีใน pubspec.yaml เท่านั้น
3. **อย่าอ้างอิง asset ที่ไม่มี** — assets มีแค่ `.env` กับ 1 PNG ใช้ CustomPaint / Container decoration แทนรูปภาพ
4. **ทดสอบ responsive** — ตรวจว่า compact (< 380px) และ normal ทำงานได้
5. **ภาษาไทย** — ทุก UI text เป็นภาษาไทย ห้ามเปลี่ยนเป็นภาษาอังกฤษ
6. **ใช้ AppTheme constants** — ห้าม hardcode สีหรือขนาด ใช้ค่าจาก AppTheme เสมอ
7. **รักษา GlassCard** — ทุกการ์ดหลักต้องเป็น GlassCard ไม่ใช่ Container ธรรมดา
8. **รักษา GradientButton** — ปุ่ม primary ต้องเป็น GradientButton ไม่ใช่ ElevatedButton
9. **Null safety** — Dart null safety เปิดอยู่ ระวังการใช้ `!` และ `?`
10. **Comments เดิม** — อย่าลบ comments ที่มีอยู่แล้ว เพิ่มได้แต่ห้ามลบ
