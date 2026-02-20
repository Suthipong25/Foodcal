import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIService {
  
  static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? ''; 

  static GenerativeModel? _getModel(String schemaInstruction) {
    if (_apiKey.isEmpty || _apiKey == 'YOUR_GEMINI_API_KEY_HERE') {
      debugPrint('Error: Gemini API Key is missing. Please set it in assets/.env file.');
      return null;
    }
    
    final fullSystemInstruction = """
คุณเป็นผู้เชี่ยวชาญด้านโภชนาการอาหารไทย (Thai Nutrition Expert)
หน้าที่ของคุณคือวิเคราะห์และประมาณค่าพลังงาน (แคลอรี่) และสารอาหารหลัก (โปรตีน, คาร์บ, ไขมัน) ต่อ 1 หน่วยบริโภคมาตรฐาน
ตอบกลับเป็นข้อมูล JSON ตามโครงสร้างที่กำหนดเท่านั้น ห้ามเกริ่นนำ ห้ามพูดนอกเรื่อง ห้ามอธิบาย
ถ้าไม่แน่ใจ ให้ใช้ค่าเฉลี่ยของอาหารชนิดนั้นๆ

โครงสร้างที่คุณต้องตอบ:
$schemaInstruction
""";

    return GenerativeModel(
      model: 'gemini-3-flash-preview',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        temperature: 0.1,
        maxOutputTokens: 1024, // Increased to prevent truncation in vision tasks
      ),
      systemInstruction: Content.system(fullSystemInstruction),
    );
  }

  static Future<Map<String, dynamic>?> analyzeFoodImage(Uint8List imageBytes) async {
    if (imageBytes.isEmpty) return null;

    final model = _getModel("""
{
  "name": "ชื่ออาหารภาษาไทย",
  "calories": 500,
  "protein": 20,
  "carbs": 60,
  "fat": 15
}
""");

    if (model == null) return null;

    try {
      // Added explicit JSON format reminder in the prompt for Gemini 3
      final content = [Content.multi([
        DataPart('image/jpeg', imageBytes), 
        TextPart("Analyze the food in this image and output the nutritional data strictly in the requested JSON format. Provide the best estimation possible.")
      ])];
      final response = await model.generateContent(content);
      return _parseResponse(response.text);
    } catch (e) {
      debugPrint('AI Image Analysis Error: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> estimateCalories(String foodName) async {
    final model = _getModel("""
{
  "name": "ชื่ออาหารภาษาไทย",
  "calories": 450,
  "protein": 15,
  "carbs": 55,
  "fat": 12
}
""");

    if (model == null) return null;

    try {
      final response = await model.generateContent([Content.text("ประมาณค่าโภชนาการสำหรับ: $foodName")]);
      return _parseResponse(response.text);
    } catch (e) {
      debugPrint('AI Text Estimation Error: $e');
      return null;
    }
  }

  static Map<String, dynamic>? _parseResponse(String? text) {
    if (text == null || text.isEmpty) return null;
    debugPrint('AI Raw Response: $text');
    try {
      final jsonString = _extractJson(text);
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('JSON Parsing Error: $e \nOriginal Text: $text');
      // Final fallback: if it's still breaking, try to close the JSON manually for a partial result
      if (text.contains('"name":')) {
         try {
           final partialFix = text.endsWith('}') ? text : '$text"}'; 
           final secondTry = _extractJson(partialFix);
           return jsonDecode(secondTry) as Map<String, dynamic>;
         } catch (_) {}
      }
      return null;
    }
  }

  static String _extractJson(String text) {
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start != -1 && end != -1 && end > start) {
      return text.substring(start, end + 1);
    }
    // Handle cases where the model might only output the JSON content without braces in JSON mode
    final cleaned = text.replaceAll('```json', '').replaceAll('```', '').trim();
    if (cleaned.startsWith('{') && (cleaned.endsWith('}') || cleaned.contains('}'))) {
      final lastBrace = cleaned.lastIndexOf('}');
      return cleaned.substring(0, lastBrace + 1);
    }
    return cleaned.startsWith('{') ? cleaned : '{}';
  }
}