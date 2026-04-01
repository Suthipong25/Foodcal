# AI Backend Setup

ตอนนี้ฝั่งแอปถูกปรับให้ **ไม่เรียก Gemini จาก client ตรงแล้ว**

แอปจะเรียก backend ที่เรากำหนดผ่าน `--dart-define=AI_BACKEND_URL=...` แทน เช่น

```bash
flutter run --dart-define=AI_BACKEND_URL=https://YOUR_DOMAIN/api/ai
```

โดย backend ควรมี 2 endpoint:

## 1. `POST /analyze-food-image`

Request

```json
{
  "imageBase64": "..."
}
```

Response

```json
{
  "name": "ข้าวมันไก่",
  "calories": 585,
  "protein": 27,
  "carbs": 63,
  "fat": 18
}
```

## 2. `POST /estimate-food`

Request

```json
{
  "foodName": "ข้าวไข่เจียว"
}
```

Response

```json
{
  "name": "ข้าวไข่เจียว",
  "calories": 420,
  "protein": 14,
  "carbs": 39,
  "fat": 22
}
```

## ข้อแนะนำด้านความปลอดภัย

- เก็บ Gemini API key ไว้ใน backend environment เท่านั้น
- ตรวจสอบ input size ของรูปก่อนส่งเข้า model
- ใส่ rate limit ตาม user หรือ IP
- log เฉพาะ metadata ที่จำเป็น หลีกเลี่ยงการเก็บรูปเต็มถ้าไม่จำเป็น
- validate response schema ก่อนส่งกลับแอป
