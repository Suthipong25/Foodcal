# FoodCal redesign options

## แบบที่ 1: Fresh Coach

คอนเซปต์: แอพสุขภาพที่เป็นมิตร สดใส และช่วยให้ผู้ใช้รู้สึกว่าการดูแลตัวเองทำได้ทุกวัน

- โทนสีหลัก: deep green `#163C2C`, fresh green `#23A36E`, coral `#FF7E67`, soft cream-green `#F5FAEF`
- บุคลิก: อบอุ่น สนับสนุน เหมาะกับผู้ใช้ทั่วไปหรือมือใหม่
- หน้าแรก: hero card ใหญ่ บอกแคลอรี่ที่เหลือพร้อม progress ring
- ปุ่มหลัก: สแกนอาหาร, เพิ่มอาหาร, AI Coach เป็น action ใหญ่ แตะง่าย
- สารอาหาร: แสดงเป็นกล่องสีแยก macro อ่านเร็ว ไม่กดดัน
- เหมาะกับ: onboarding, home, tracking, content, AI coach

## แบบที่ 2: Pro Tracker

คอนเซปต์: dashboard สำหรับคนจริงจังกับตัวเลข macro และพฤติกรรมรายวัน

- โทนสีหลัก: near-black `#111713`, dark surface `#1C241F`, lime `#C9F24D`, cyan `#67E8F9`, amber `#FFB86B`
- บุคลิก: แม่นยำ กระชับ มืออาชีพ เหมาะกับคน track ทุกวัน
- หน้าแรก: metric cards สองใบใน viewport แรก เช่น consumed และ remaining
- กราฟ: แนวโน้ม 7 วันอยู่ใกล้ macro split เพื่อดู performance เร็ว
- ปุ่มหลัก: action row แบบ compact สำหรับ scan, workout, AI Coach
- เหมาะกับ: home, history, weight, progress reports

## คำแนะนำ

ทิศทางที่เลือกใช้ตอนนี้คือ Fresh Coach เพราะเข้ากับ FoodCal ในฐานะแอพสุขภาพสำหรับผู้ใช้วงกว้างมากกว่า และให้ความรู้สึกเป็นมิตรตอนบันทึกอาหารทุกวัน

Pro Tracker ยังเก็บไว้เป็นทางเลือกถ้าต้องการ reposition แอพให้จริงจังขึ้นสำหรับกลุ่ม fitness/macro tracking ในอนาคต

## Preview

เพิ่ม route สำหรับดู mockup แล้ว:

```text
/design-options
```

ไฟล์ preview อยู่ที่:

```text
lib/screens/design_options_screen.dart
```
