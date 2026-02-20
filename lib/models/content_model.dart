
class WorkoutVideo {
  final int id;
  final String title;
  final String level;
  final String duration;
  final String type;
  final String youtubeUrl;

  const WorkoutVideo({
    required this.id,
    required this.title,
    required this.level,
    required this.duration,
    required this.type,
    required this.youtubeUrl,
  });
}

class Article {
  final int id;
  final String title;
  final String category;
  final String body;
  final String imageUrl;

  const Article({
    required this.id,
    required this.title,
    required this.category,
    required this.body,
    required this.imageUrl,
  });
}

// Mock Data
const List<WorkoutVideo> WORKOUT_VIDEOS = [
  WorkoutVideo(
    id: 1, 
    title: 'คาร์ดิโอ 15 นาที (มือใหม่)', 
    level: 'Beginner', 
    duration: '15 min', 
    type: 'Cardio', 
    youtubeUrl: 'https://www.youtube.com/watch?v=IT94xC35u6k'
  ),
  WorkoutVideo(
    id: 2, 
    title: 'HIIT เผาผลาญไขมันขั้นสุด', 
    level: 'Expert', 
    duration: '20 min', 
    type: 'HIIT', 
    youtubeUrl: 'https://www.youtube.com/watch?v=ml6cT4AZdqI'
  ),
  WorkoutVideo(
    id: 3, 
    title: 'โยคะยามเช้า 10 นาที', 
    level: 'Beginner', 
    duration: '10 min', 
    type: 'Yoga', 
    youtubeUrl: 'https://www.youtube.com/watch?v=UEEsdXn8oG8'
  ),
  WorkoutVideo(
    id: 4, 
    title: 'ปั้นซิกแพคใน 10 นาที', 
    level: 'Intermediate', 
    duration: '10 min', 
    type: 'Strength', 
    youtubeUrl: 'https://www.youtube.com/watch?v=1919eTCoESo'
  ),
  WorkoutVideo(
    id: 5, 
    title: 'บอดี้เวทสร้างกล้ามเนื้อที่บ้าน', 
    level: 'Expert', 
    duration: '20 min', 
    type: 'Strength', 
    youtubeUrl: 'https://www.youtube.com/watch?v=vc1E5CfRfos'
  ),
  WorkoutVideo(
    id: 6, 
    title: 'พิลาทิสเพิ่มหน้าท้องแบนราบ', 
    level: 'Intermediate', 
    duration: '20 min', 
    type: 'Pilates', 
    youtubeUrl: 'https://www.youtube.com/watch?v=2eA2Koq6pTI'
  ),
  WorkoutVideo(
    id: 7, 
    title: 'เบิร์นไขมัน 30 นาที (ไม่ใช้กระโดด)', 
    level: 'Beginner', 
    duration: '30 min', 
    type: 'Cardio', 
    youtubeUrl: 'https://www.youtube.com/watch?v=v7AYKMP6rOE'
  ),
  WorkoutVideo(
    id: 8, 
    title: 'ยืดเหยียดร่างกาย 15 นาที (ทุกวัน)', 
    level: 'Beginner', 
    duration: '15 min', 
    type: 'Stretch', 
    youtubeUrl: 'https://www.youtube.com/watch?v=L_xrDAtykMI'
  ),
  WorkoutVideo(
    id: 9, 
    title: 'HIIT สุดเดือด 15 นาที', 
    level: 'Expert', 
    duration: '15 min', 
    type: 'HIIT', 
    youtubeUrl: 'https://www.youtube.com/watch?v=2MoGxae-zyo'
  ),
  WorkoutVideo(
    id: 10, 
    title: 'กระชับต้นขาและก้น', 
    level: 'Intermediate', 
    duration: '15 min', 
    type: 'Strength', 
    youtubeUrl: 'https://www.youtube.com/watch?v=AQ-zcv_viAo'
  ),
];

const List<Article> EDUCATION_ARTICLES = [
  Article(
    id: 1, 
    title: 'Protein 101: กินยังไงให้พอ?', 
    category: 'Nutrition',
    imageUrl: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500&q=80',
    body: '''
โปรตีนคือสารอาหารที่สำคัญที่สุดสำหรับการสร้างกล้ามเนื้อและซ่อมแซมส่วนที่สึกหรอ

ปริมาณที่แนะนำ:
- บุคคลทั่วไป: 0.8 - 1 กรัม ต่อน้ำหนักตัว 1 กิโลกรัม
- คนออกกำลังกาย: 1.5 - 2 กรัม ต่อน้ำหนักตัว 1 กิโลกรัม

แหล่งโปรตีนที่ดี:
1. อกไก่ (23g โปรตีน/100g)
2. ไข่ต้ม (6g โปรตีน/ฟอง)
3. ปลาแซลมอน
4. ถั่วเหลืองและเต้าหู้
5. เวย์โปรตีน

เคล็ดลับ: ควรแบ่งทานโปรตีนให้กระจายในทุกมื้อ เพื่อการดูดซึมที่ดีที่สุด
'''
  ),
  Article(
    id: 2, 
    title: 'ความสำคัญของการนอนหลับ', 
    category: 'Health',
    imageUrl: 'https://images.unsplash.com/photo-1541781774459-bb2af2f05b55?w=500&q=80',
    body: '''
การนอนหลับไม่ได้เป็นเพียงการพักผ่อน แต่เป็นช่วงเลาที่ร่างกายซ่อมแซมตัวเองและปรับสมดุลฮอร์โมน

ผลเสียของการนอนน้อย:
- ฮอร์โมนหิว (Ghrelin) เพิ่มขึ้น ทำให้หิวบ่อย
- การเผาผลาญลดลง
- ร่างกายสะสมไขมันง่ายขึ้น
- ฟื้นตัวจากการออกกำลังกายได้ช้า

คำแนะนำ:
- นอนให้ได้ 7-8 ชั่วโมงต่อคืน
- เข้านอนและตื่นเวลาเดิม
- งดเล่นมือถือก่อนนอน 30 นาที
'''
  ),
  Article(
    id: 3, 
    title: 'Water Intake: ดื่มน้ำลดอ้วน', 
    category: 'Habit',
    imageUrl: 'https://images.unsplash.com/photo-1548839140-29a749e1cf4d?w=500&q=80',
    body: '''
น้ำเป็นตัวช่วยสำคัญในการเผาผลาญไขมัน การดื่มน้ำให้เพียงพอช่วยเพิ่มอัตราการเผาผลาญได้

ประโยชน์ของการดื่มน้ำ:
1. ลดความอยากอาหาร
2. ช่วยระบบขับถ่าย
3. เพิ่มประสิทธิภาพการออกกำลังกาย

สูตรคำนวณ: น้ำหนักตัว (kg) x 33 = ปริมาณน้ำที่ควรดื่ม (ml)
เช่น หนัก 60kg x 33 = 1,980 ml (ประมาณ 2 ลิตร)

Tips: ดื่มน้ำ 1 แก้วทันทีหลังตื่นนอน เพื่อกระตุ้นระบบเผาผลาญ
'''
  ),
  Article(
    id: 4,
    title: 'คาร์โบไฮเดรต: มิตรหรือศัตรู?',
    category: 'Nutrition',
    imageUrl: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=500&q=80',
    body: '''
หลายคนกลัวแป้งเวลาลดน้ำหนัก แต่จริงๆ แล้วคาร์โบไฮเดรตคือแหล่งพลังงานหลักของร่างกาย

ชนิดของคาร์บ:
1. Simple Carbs (แป้งขัดขาว, น้ำตาล): ดูดซึมเร็ว หิวเร็ว ควรเลี่ยง
2. Complex Carbs (ข้าวกล้อง, โฮลวีต, ธัญพืช): มีใยอาหาร อิ่มนาน ให้พลังงานต่อเนื่อง

ควรกินตอนไหน?
- มื้อเช้าและก่อนออกกำลังกาย: เพื่อสะสมพลังงาน
- หลังออกกำลังกาย: เพื่อเติม Glycogen
- มื้อเย็น: ลดปริมาณลงได้หากไม่ได้ใช้พลังงานต่อ
'''
  ),
  Article(
    id: 5,
    title: 'ไขมันดี vs ไขมันเลว',
    category: 'Nutrition',
    imageUrl: 'https://images.unsplash.com/photo-1523049673857-eb18f1d7b578?w=500&q=80',
    body: '''
ไขมันไม่ได้ทำให้อ้วนเสมอไป ร่างกายต้องการไขมันเพื่อดูดซึมวิตามินและสร้างฮอร์โมน

ไขมันดี (Good Fat):
- อะโวคาโด
- น้ำมันมะกอก
- ถั่วอัลมอนด์
- ปลาทะเล

ไขมันเลว (Bad Fat):
- ไขมันทรานส์ (เนยเทียม, ครีมเทียม)
- ของทอดน้ำมันลอย
- เบเกอรี่แปรรูป

เลือกทานไขมันดีในปริมาณพอเหมาะ จะช่วยลดการอักเสบและบำรุงหัวใจ
'''
  ),
  Article(
    id: 6,
    title: 'Cheat Meal คืออะไร?',
    category: 'Habit',
    imageUrl: 'https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=500&q=80',
    body: '''
Cheat Meal คือมื้อตามใจปาก 1 มื้อในสัปดาห์ เพื่อคลายเครียดและกระตุ้นการเผาผลาญ

กฎเหล็กของ Cheat Meal:
1. กินแค่ 1 มื้อ ไม่ใช่ทั้งวัน (Cheat Day)
2. อย่ากินจนจุกเกินไป
3. กลับมาคุมอาหารทันทีในมื้อถัดไป

ประโยชน์: ช่วยลดความเครียดจากการคุมอาหาร (Cortisol) ซึ่งเป็นสาเหตุของการเก็บไขมันที่พุง
'''
  ),
  Article(
    id: 7,
    title: 'เวทเทรนนิ่ง vs คาร์ดิโอ',
    category: 'Fitness',
    imageUrl: 'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=500&q=80',
    body: '''
คำถามโลกแตก: อยากผอมต้องเล่นอะไร?

Cardio (วิ่ง, ปั่นจักรยาน):
- เผาผลาญแคลอรี่ขณะเล่นสูง
- ดีต่อหัวใจและปอด

Weight Training (ยกเวท):
- สร้างกล้ามเนื้อ = เตาเผาพลังงานระยะยาว
- รูปร่างกระชับ ไม่ย้วย
- เผาผลาญต่อเนื่อง (Afterburn Effect)

สรุป: ทำควบคู่กันดีที่สุด! เวท 3 วัน + คาร์ดิโอ 2-3 วัน
'''
  ),
  Article(
    id: 8,
    title: 'Intermittent Fasting (IF) มือใหม่',
    category: 'Nutrition',
    imageUrl: 'https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=500&q=80',
    body: '''
IF ไม่ใช่การอดอาหาร แต่คือการกำหนด "เวลา" กิน

สูตรยอดนิยม 16/8:
- กินได้ 8 ชั่วโมง (เช่น 12.00 - 20.00)
- อด 16 ชั่วโมง (ดื่มน้ำเปล่า, กาแฟดำได้)

ข้อดี:
- ร่างกายดึงไขมันมาใช้ในช่วงที่อด
- ลดระดับอินซูลิน
- ทำง่าย ไม่ต้องนับแคลอรี่ละเอียดมาก

ข้อควรระวัง: อย่ากินแหลกในช่วง 8 ชั่วโมง ต้องคุมสารอาหารด้วย
'''
  ),
  Article(
    id: 9,
    title: 'วิตามินที่คนลดน้ำหนักควรเสริม',
    category: 'Health',
    imageUrl: 'https://images.unsplash.com/photo-1584017911766-d451b3d0e843?w=500&q=80',
    body: '''
เมื่อทานน้อยลง อาจขาดสารอาหารบางอย่าง

1. วิตามิน B รวม: ช่วยเผาผลาญแป้งและน้ำตาล
2. วิตามิน D: เกี่ยวข้องกับการควบคุมน้ำหนักและความแข็งแรงกระดูก
3. แมกนีเซียม: ช่วยเรื่องการนอนหลับและกล้ามเนื้อ
4. Fish Oil: ลดการอักเสบ

*ควรเน้นทานจากอาหารหลักก่อน อาหารเสริมเป็นเพียงตัวช่วย
'''
  ),
  Article(
    id: 10,
    title: 'Mindset: ชนะใจตัวเอง',
    category: 'Habit',
    imageUrl: 'https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=500&q=80',
    body: '''
การลดน้ำหนักคือการวิ่งมาราธอน ไม่ใช่สปรินท์

3 วิธีคิดสู่ความสำเร็จ:
1. Consistency > Intensity: ความสม่ำเสมอสำคัญกว่าความหนัก ทำเบาๆ แต่ทำทุกวันดีกว่า
2. Forgive Yourself: หลุดกินไปมื้อนึง ไม่ได้แปลว่าล้มเหลว เริ่มใหม่ทันที
3. Focus on Health: โฟกัสสุขภาพที่ดีขึ้น มากกว่าตัวเลขบนตาชั่ง

สู้ๆ คุณทำได้!
'''
  ),
];
