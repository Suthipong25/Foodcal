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

const List<WorkoutVideo> workoutVideos = [
  WorkoutVideo(
    id: 1,
    title: 'คาร์ดิโอ 15 นาที สำหรับมือใหม่',
    level: 'Beginner',
    duration: '15 min',
    type: 'Cardio',
    youtubeUrl: 'https://www.youtube.com/watch?v=IT94xC35u6k',
  ),
  WorkoutVideo(
    id: 2,
    title: 'HIIT เผาผลาญไขมันแบบเข้มข้น',
    level: 'Expert',
    duration: '20 min',
    type: 'HIIT',
    youtubeUrl: 'https://www.youtube.com/watch?v=ml6cT4AZdqI',
  ),
  WorkoutVideo(
    id: 3,
    title: 'โยคะยามเช้า 10 นาที',
    level: 'Beginner',
    duration: '10 min',
    type: 'Yoga',
    youtubeUrl: 'https://www.youtube.com/watch?v=UEEsdXn8oG8',
  ),
  WorkoutVideo(
    id: 4,
    title: 'หน้าท้องกระชับใน 10 นาที',
    level: 'Intermediate',
    duration: '10 min',
    type: 'Strength',
    youtubeUrl: 'https://www.youtube.com/watch?v=1919eTCoESo',
  ),
  WorkoutVideo(
    id: 5,
    title: 'บอดี้เวตสร้างกล้ามเนื้อที่บ้าน',
    level: 'Expert',
    duration: '20 min',
    type: 'Strength',
    youtubeUrl: 'https://www.youtube.com/watch?v=vc1E5CfRfos',
  ),
  WorkoutVideo(
    id: 6,
    title: 'พิลาทิสเพิ่มแกนกลางลำตัว',
    level: 'Intermediate',
    duration: '20 min',
    type: 'Pilates',
    youtubeUrl: 'https://www.youtube.com/watch?v=2eA2Koq6pTI',
  ),
  WorkoutVideo(
    id: 7,
    title: 'เบิร์นไขมัน 30 นาที แบบไม่กระโดด',
    level: 'Beginner',
    duration: '30 min',
    type: 'Cardio',
    youtubeUrl: 'https://www.youtube.com/watch?v=v7AYKMP6rOE',
  ),
  WorkoutVideo(
    id: 8,
    title: 'ยืดเหยียดร่างกาย 15 นาที ทุกวัน',
    level: 'Beginner',
    duration: '15 min',
    type: 'Stretch',
    youtubeUrl: 'https://www.youtube.com/watch?v=L_xrDAtykMI',
  ),
  WorkoutVideo(
    id: 9,
    title: 'HIIT สายโหด 15 นาที',
    level: 'Expert',
    duration: '15 min',
    type: 'HIIT',
    youtubeUrl: 'https://www.youtube.com/watch?v=2MoGxae-zyo',
  ),
  WorkoutVideo(
    id: 10,
    title: 'กระชับต้นขาและสะโพก',
    level: 'Intermediate',
    duration: '15 min',
    type: 'Strength',
    youtubeUrl: 'https://www.youtube.com/watch?v=AQ-zcv_viAo',
  ),
];

const List<Article> educationArticles = [
  Article(
    id: 1,
    title: 'Protein 101 กินยังไงให้พอ',
    category: 'Nutrition',
    imageUrl:
        'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500&q=80',
    body: '''
โปรตีนเป็นสารอาหารสำคัญสำหรับการซ่อมแซมร่างกายและสร้างกล้ามเนื้อ โดยเฉพาะคนที่ออกกำลังกายสม่ำเสมอควรให้ความสำคัญกับเรื่องนี้มากขึ้น

ปริมาณที่มักแนะนำ
- คนทั่วไป 0.8 ถึง 1 กรัม ต่อน้ำหนักตัว 1 กิโลกรัม
- คนออกกำลังกาย 1.4 ถึง 2 กรัม ต่อน้ำหนักตัว 1 กิโลกรัม

แหล่งโปรตีนที่เลือกได้ง่าย
1. อกไก่
2. ไข่
3. ปลา
4. เต้าหู้และถั่ว
5. กรีกโยเกิร์ต

เคล็ดลับคือกระจายโปรตีนให้ครบหลายมื้อในวันเดียว แทนที่จะเน้นกินหนักแค่มื้อเดียว
''',
  ),
  Article(
    id: 2,
    title: 'การนอนสำคัญกว่าที่คิด',
    category: 'Health',
    imageUrl:
        'https://images.unsplash.com/photo-1541781774459-bb2af2f05b55?w=500&q=80',
    body: '''
การนอนคือช่วงเวลาที่ร่างกายฟื้นฟูตัวเอง หากพักผ่อนไม่พอ ฮอร์โมนความหิวอาจเสียสมดุลและทำให้คุมอาหารยากขึ้น

ผลที่พบบ่อยเมื่อพักผ่อนน้อย
- หิวบ่อยขึ้น
- ฟื้นตัวจากการออกกำลังกายช้าลง
- สมาธิลดลง
- มีโอกาสกินเกินเป้าหมายได้ง่าย

แนวทางง่าย ๆ ที่ช่วยได้
1. นอนให้ได้ประมาณ 7 ถึง 8 ชั่วโมง
2. เข้านอนและตื่นเวลาเดิมให้สม่ำเสมอ
3. ลดการเล่นมือถือก่อนนอนอย่างน้อย 30 นาที
''',
  ),
  Article(
    id: 3,
    title: 'ดื่มน้ำให้พอ ช่วยเรื่องการคุมหุ่น',
    category: 'Habit',
    imageUrl:
        'https://images.unsplash.com/photo-1548839140-29a749e1cf4d?w=500&q=80',
    body: '''
น้ำช่วยให้ระบบต่าง ๆ ทำงานดีขึ้น ทั้งการย่อย การลำเลียงสารอาหาร และการควบคุมความอยากอาหาร

ประโยชน์ของการดื่มน้ำสม่ำเสมอ
1. ลดอาการหิวหลอก
2. ช่วยให้สดชื่นและโฟกัสดีขึ้น
3. สนับสนุนการออกกำลังกายและการฟื้นตัว

สูตรจำง่ายคือ น้ำหนักตัวคูณ 30 ถึง 35 มิลลิลิตรต่อวัน แล้วค่อยปรับตามกิจกรรมที่ทำ
''',
  ),
  Article(
    id: 4,
    title: 'คาร์บไม่ใช่ศัตรู',
    category: 'Nutrition',
    imageUrl:
        'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=500&q=80',
    body: '''
คาร์โบไฮเดรตคือแหล่งพลังงานหลักของร่างกาย โดยเฉพาะถ้าคุณออกกำลังกายหรือใช้สมองเยอะ การตัดแป้งทิ้งทั้งหมดมักไม่ใช่คำตอบ

สิ่งสำคัญคือเลือกแหล่งคาร์บที่ดี เช่น
- ข้าวไม่ขัดสี
- ขนมปังโฮลวีต
- มันหวาน
- ผลไม้

ถ้าต้องการคุมหุ่น ให้เริ่มจากจัดปริมาณและเวลาให้เหมาะสม มากกว่าตัดออกทั้งหมด
''',
  ),
  Article(
    id: 5,
    title: 'ไขมันดีและไขมันที่ควรลด',
    category: 'Nutrition',
    imageUrl:
        'https://images.unsplash.com/photo-1523049673857-eb18f1d7b578?w=500&q=80',
    body: '''
ไขมันไม่ได้แปลว่าไม่ดีเสมอไป ร่างกายยังต้องใช้ไขมันสำหรับฮอร์โมน สมอง และการดูดซึมวิตามินบางชนิด

ไขมันดีที่พบได้บ่อย
- อะโวคาโด
- ถั่วและเมล็ดพืช
- น้ำมันมะกอก
- ปลาที่มีไขมันดี

สิ่งที่ควรลดคือของทอดจัด อาหารแปรรูป และไขมันทรานส์
''',
  ),
  Article(
    id: 6,
    title: 'Cheat Meal ควรมีไหม',
    category: 'Habit',
    imageUrl:
        'https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=500&q=80',
    body: '''
Cheat Meal คือมื้อที่ยืดหยุ่นขึ้นเพื่อช่วยให้การคุมอาหารทำได้ยาวขึ้น แต่ต้องวางขอบเขตให้ดี

หลักที่ควรจำ
1. จำกัดเป็นบางมื้อ ไม่ใช่ทั้งวัน
2. กินแบบรู้ตัว ไม่ไหลไปเรื่อย
3. กลับเข้าสู่แผนเดิมในมื้อถัดไป

ถ้าใช้ให้ถูก มันช่วยเรื่องวินัยระยะยาวได้มากกว่าทำให้แผนพัง
''',
  ),
  Article(
    id: 7,
    title: 'เวทเทรนนิ่งกับคาร์ดิโอ เลือกอะไรดี',
    category: 'Fitness',
    imageUrl:
        'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=500&q=80',
    body: '''
ทั้งสองแบบมีข้อดีต่างกัน คาร์ดิโอช่วยใช้พลังงานขณะทำ ส่วนเวทช่วยรักษาและสร้างมวลกล้ามเนื้อ

ถ้าอยากเห็นผลดีในระยะยาว มักแนะนำให้ผสมกัน เช่น
- เวท 3 วันต่อสัปดาห์
- คาร์ดิโอ 2 ถึง 3 วัน

จุดสำคัญคือทำอย่างสม่ำเสมอและเลือกแผนที่เข้ากับชีวิตจริง
''',
  ),
  Article(
    id: 8,
    title: 'เริ่มต้น Intermittent Fasting อย่างเข้าใจ',
    category: 'Nutrition',
    imageUrl:
        'https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=500&q=80',
    body: '''
IF คือการกำหนดช่วงเวลากิน ไม่ใช่การอดแบบหักโหม รูปแบบยอดนิยมคือ 16 ต่อ 8

ข้อดีที่หลายคนชอบ
- วางแผนมื้อง่ายขึ้น
- ลดการกินจุกจิก
- เหมาะกับคนที่ไม่ชอบกินเช้า

แต่สิ่งที่สำคัญที่สุดยังคงเป็นปริมาณอาหารรวมและคุณภาพอาหารในแต่ละวัน
''',
  ),
];
