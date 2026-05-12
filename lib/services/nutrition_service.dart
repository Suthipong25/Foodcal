import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/nutrition_result.dart';
import '../utils/app_logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'food_database_service.dart';

/// Facade หลักสำหรับค้นหาข้อมูลโภชนาการ
///
/// Flow:
///   1. Firestore Cache (ผ่าน FoodDatabaseService)
///   2. Open Food Facts (+ AI แปลชื่อไทย + ประมาณ serving)
///   3. Gemini AI estimate (fallback)
class NutritionService {
  static String get _apiKey =>
      dotenv.env['GEMINI_API_KEY'] ?? const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  static bool get isConfigured => _apiKey.isNotEmpty;

  static final FoodDatabaseService _foodDb = FoodDatabaseService();

  // ─── Public API ────────────────────────────────────────────────────────

  /// ค้นหาโภชนาการจากชื่ออาหาร (text)
  static Future<NutritionResult?> lookupFood(String foodName) async {
    final name = foodName.trim();
    if (name.isEmpty) return null;

    // 1. ลองหาจากฐานข้อมูลจริงก่อน
    final dbResult = await _foodDb.searchFood(name);
    if (dbResult != null) {
      // ถ้าชื่อจากฐานข้อมูลเป็นภาษาอังกฤษ ให้ AI แปลเป็นไทยและประมาณ serving
      final enriched = await _enrichWithAI(dbResult, originalQuery: name);
      return enriched ?? dbResult;
    }

    // 2. Fallback: ใช้ Gemini AI ประมาณการ
    if (!isConfigured) return null;
    return _estimateWithAI(name);
  }

  /// วิเคราะห์อาหารจากรูปภาพ (ยังคงใช้ Gemini AI อย่างเดียว)
  static Future<NutritionResult?> analyzeImage(Uint8List imageBytes) async {
    if (imageBytes.isEmpty || !isConfigured) return null;

    const prompt = '''
คุณเป็นนักโภชนาการผู้เชี่ยวชาญ วิเคราะห์อาหารในรูปภาพนี้
ประมาณปริมาณที่เหมาะสมสำหรับ 1 มื้อ/1 จาน/1 ชิ้นตามที่เห็นในรูป

ตอบเป็น JSON object เท่านั้น (ไม่มี markdown):
{
  "name": "ชื่ออาหารภาษาไทย",
  "calories": <int kcal>,
  "protein": <int กรัม>,
  "carbs": <int กรัม>,
  "fat": <int กรัม>,
  "serving_label": "คำอธิบาย serving เช่น 1 จาน (~300g)"
}''';

    try {
      final text = await _callGeminiImage(prompt, imageBytes);
      if (text == null) return null;
      return _parseAIResult(text, NutritionSource.aiEstimate);
    } catch (e) {
      AppLogger.error('[Nutrition] analyzeImage failed', e);
      rethrow;
    }
  }

  // ─── Private: AI enrichment ────────────────────────────────────────────

  /// เพิ่มข้อมูลจาก AI: แปลชื่อไทย + ปรับ serving จาก 100g → 1 มื้อจริง
  static Future<NutritionResult?> _enrichWithAI(
    NutritionResult dbResult, {
    required String originalQuery,
  }) async {
    if (!isConfigured) return dbResult;

    final prompt = '''
คุณเป็นนักโภชนาการ ข้อมูลต่อไปนี้มาจากฐานข้อมูลโภชนาการต่อ serving ดังนี้:
ชื่อ (EN): ${dbResult.name}
Serving: ${dbResult.servingLabel}
แคลอรี่: ${dbResult.calories} kcal
โปรตีน: ${dbResult.protein}g  คาร์บ: ${dbResult.carbs}g  ไขมัน: ${dbResult.fat}g

งาน:
1. แปลหรือตั้งชื่อภาษาไทยที่เหมาะสมสำหรับ "$originalQuery"
2. ประมาณ serving ที่คนไทยทานจริง 1 มื้อ (เช่น 1 จาน, 1 ชิ้น) แล้วคำนวณโภชนาการใหม่

ตอบเป็น JSON object เท่านั้น (ไม่มี markdown):
{
  "name": "ชื่อภาษาไทย",
  "calories": <int kcal>,
  "protein": <int กรัม>,
  "carbs": <int กรัม>,
  "fat": <int กรัม>,
  "serving_label": "เช่น 1 จาน (~300g)"
}''';

    try {
      final text = await _callGeminiText(prompt);
      if (text == null) return dbResult;
      final enriched = _parseAIResult(text, NutritionSource.database);
      return enriched ?? dbResult;
    } catch (e) {
      AppLogger.error('[Nutrition] _enrichWithAI failed', e);
      return dbResult; // คืนค่าเดิมถ้า AI ล้มเหลว
    }
  }

  /// ประมาณการโภชนาการทั้งหมดจาก AI (fallback)
  static Future<NutritionResult?> _estimateWithAI(String foodName) async {
    final prompt = '''
คุณเป็นนักโภชนาการผู้เชี่ยวชาญอาหารไทยและสากล
ประมาณค่าโภชนาการของ "$foodName" สำหรับ 1 มื้อ/1 จาน/1 ชิ้นที่คนไทยทานจริง

ตอบเป็น JSON object เท่านั้น (ไม่มี markdown):
{
  "name": "ชื่อภาษาไทย",
  "calories": <int kcal>,
  "protein": <int กรัม>,
  "carbs": <int กรัม>,
  "fat": <int กรัม>,
  "serving_label": "เช่น 1 จาน (~350g)"
}''';

    try {
      final text = await _callGeminiText(prompt);
      if (text == null) return null;
      return _parseAIResult(text, NutritionSource.aiEstimate);
    } catch (e) {
      AppLogger.error('[Nutrition] _estimateWithAI failed', e);
      rethrow;
    }
  }

  // ─── Gemini HTTP Helpers ──────────────────────────────────────────────

  static const List<String> _models = [
    'gemini-2.5-flash',
    'gemini-2.5-pro',
    'gemini-2.0-flash',
    'gemini-2.0-pro',
  ];

  static Future<http.Response> _postWithFallback(String body) async {
    const maxRetries = 2;
    const baseDelay = Duration(seconds: 2);

    for (final model in _models) {
      final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$_apiKey');

      for (int i = 0; i < maxRetries; i++) {
        try {
          final res = await http.post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: body,
          );
          if (res.statusCode == 200) return res;
          
          AppLogger.error('[Nutrition] Gemini API ($model) failed with ${res.statusCode}: ${res.body}');
          
          if (res.statusCode == 503 || res.statusCode == 429) {
            AppLogger.info('[Nutrition] Retrying in ${baseDelay.inSeconds * (i + 1)}s...');
            await Future.delayed(baseDelay * (i + 1));
            continue;
          }
          if (res.statusCode == 404) {
            break;
          }
          if (i == maxRetries - 1) return res;
        } catch (e) {
          if (i == maxRetries - 1) rethrow;
          await Future.delayed(baseDelay * (i + 1));
        }
      }
    }
    throw Exception('All Gemini models failed or were unavailable.');
  }

  static Future<String?> _callGeminiText(String prompt) async {
    final res = await _postWithFallback(jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {'temperature': 0.1},
    }));
    return _extractText(res);
  }

  static Future<String?> _callGeminiImage(
      String prompt, Uint8List bytes) async {
    final base64Image = base64Encode(bytes);
    final res = await _postWithFallback(jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt},
            {
              'inlineData': {'mimeType': 'image/jpeg', 'data': base64Image}
            }
          ]
        }
      ],
      'generationConfig': {'temperature': 0.1},
    }));
    return _extractText(res);
  }

  static String? _extractText(http.Response response) {
    if (response.statusCode != 200) {
      throw Exception(
          'Gemini API Error: ${response.statusCode} ${response.body}');
    }
    final data = jsonDecode(response.body);
    final candidates = data['candidates'] as List?;
    if (candidates != null && candidates.isNotEmpty) {
      final parts = candidates[0]['content']['parts'] as List?;
      if (parts != null && parts.isNotEmpty) {
        return parts[0]['text']?.toString();
      }
    }
    return null;
  }

  // ─── JSON Parsing ─────────────────────────────────────────────────────

  static NutritionResult? _parseAIResult(String text, NutritionSource source) {
    final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
    if (jsonMatch == null) return null;

    try {
      final raw = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
      final calories = _toInt(raw['calories']);
      if (calories == null) return null;

      return NutritionResult(
        name: raw['name']?.toString().trim() ?? '',
        calories: calories,
        protein: _toInt(raw['protein']) ?? 0,
        carbs: _toInt(raw['carbs']) ?? 0,
        fat: _toInt(raw['fat']) ?? 0,
        servingLabel: raw['serving_label']?.toString().trim() ?? '1 serving',
        source: source,
      );
    } catch (_) {
      return null;
    }
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    if (value == null) return null;
    final match = RegExp(r'-?\d+').firstMatch(value.toString());
    return match != null ? int.tryParse(match.group(0)!) : null;
  }
}
