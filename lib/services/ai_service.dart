import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../utils/app_logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIService {
  // ใช้ API Key จาก Environment variables (เช่น --dart-define=GEMINI_API_KEY=xxx)
  static String get _apiKey =>
      dotenv.env['GEMINI_API_KEY'] ?? const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  static bool get isConfigured => _apiKey.isNotEmpty;

  static String get configErrorMessage =>
      'ฟีเจอร์ AI ยังไม่พร้อมใช้งานในขณะนี้ โปรดตั้งค่า API Key ในโค้ด';

  static Future<Map<String, dynamic>?> estimateCalories(String foodName) async {
    final normalized = foodName.trim();
    if (normalized.isEmpty || !isConfigured) return null;

    final prompt =
        'You are an expert nutritionist. Estimate the calories and macronutrients for: $normalized. Return ONLY a valid JSON object with the following keys: "calories" (int), "protein" (int, grams), "carbs" (int, grams), "fat" (int, grams). Do not include any markdown formatting like ```json.';

    try {
      final responseText = await _generateText(prompt);
      if (responseText == null) return null;
      return _parseNutrition(responseText);
    } catch (error) {
      AppLogger.error('[AI] estimateCalories failed', error);
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> analyzeFoodImage(
    Uint8List imageBytes,
  ) async {
    if (imageBytes.isEmpty || !isConfigured) return null;

    const prompt =
        'You are an expert nutritionist. Analyze the food in the image and estimate its calories and macronutrients. Return ONLY a valid JSON object with the following keys: "name" (string, concise name of the food in Thai), "calories" (int), "protein" (int, grams), "carbs" (int, grams), "fat" (int, grams). Do not include any markdown formatting like ```json.';

    try {
      final responseText = await _generateImage(prompt, imageBytes);
      if (responseText == null) return null;
      return _parseNutrition(responseText);
    } catch (error) {
      AppLogger.error('[AI] analyzeFoodImage failed', error);
      rethrow;
    }
  }

  static Future<String?> askCoach(
    String message, {
    List<Map<String, String>> history = const [],
  }) async {
    final normalized = message.trim();
    if (normalized.isEmpty || !isConfigured) return null;

    final prompt =
        'You are an expert health and fitness coach. The user says: $normalized. Please provide a concise, helpful, and motivating response in Thai. Keep it short and easy to read.';

    try {
      final contents = [];
      for (final h in history) {
        if (h['role'] != 'error') {
          contents.add({
            'role': h['role'] == 'user' ? 'user' : 'model',
            'parts': [
              {'text': h['content']}
            ]
          });
        }
      }
      contents.add({
        'role': 'user',
        'parts': [
          {'text': prompt}
        ]
      });

      final responseText = await _generateChat(contents);
      return responseText;
    } catch (error) {
      AppLogger.error('[AI] askCoach failed', error);
      rethrow;
    }
  }

  // ─── Gemini HTTP Helpers ──────────────────────────────────────────────────

  static const List<String> _models = [
    'gemini-2.5-flash',
    'gemini-2.0-flash',
    'gemini-1.5-pro',
    'gemini-pro'
  ];

  static Future<http.Response> _postWithModelFallback(String body) async {
    const maxRetriesPerModel = 2;
    const baseDelay = Duration(seconds: 2);

    for (final model in _models) {
      final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$_apiKey');

      for (int i = 0; i < maxRetriesPerModel; i++) {
        try {
          final response = await http.post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: body,
          );

          if (response.statusCode == 200) {
            return response;
          }

          if (response.statusCode == 503 || response.statusCode == 429) {
            AppLogger.info(
                'Gemini API ($model) ${response.statusCode}: Retrying in ${baseDelay.inSeconds * (i + 1)}s...');
            await Future.delayed(baseDelay * (i + 1));
            continue; // retry same model
          }

          if (response.statusCode == 404) {
            AppLogger.info(
                'Gemini API ($model) 404: Model not found. Falling back to next model...');
            break; // Break inner loop to try next model
          }

          if (i == maxRetriesPerModel - 1) {
            return response; // Let caller handle other errors
          }
        } catch (e) {
          if (i == maxRetriesPerModel - 1) rethrow;
          await Future.delayed(baseDelay * (i + 1));
        }
      }
    }
    throw Exception('All Gemini models failed or were unavailable.');
  }

  static Future<String?> _generateText(String prompt) async {
    final response = await _postWithModelFallback(
      jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.1,
        }
      }),
    );
    return _extractText(response);
  }

  static Future<String?> _generateImage(
      String prompt, Uint8List imageBytes) async {
    final base64Image = base64Encode(imageBytes);
    final response = await _postWithModelFallback(
      jsonEncode({
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
        'generationConfig': {
          'temperature': 0.1,
        }
      }),
    );
    return _extractText(response);
  }

  static Future<String?> _generateChat(List<dynamic> contents) async {
    final response = await _postWithModelFallback(
      jsonEncode({
        'contents': contents,
        'generationConfig': {
          'temperature': 0.7,
        }
      }),
    );
    return _extractText(response);
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

  // ─── JSON Parsing Logic ───────────────────────────────────────────────────

  @visibleForTesting
  static Map<String, dynamic>? parseNutritionForTest(String text) {
    return _parseNutrition(text);
  }

  static Map<String, dynamic>? _normalizeNutrition(dynamic raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);

    final calories = _toInt(map['calories']);
    final protein = _toInt(map['protein']);
    final carbs = _toInt(map['carbs']);
    final fat = _toInt(map['fat']);

    if (calories == null) return null;

    final normalized = <String, dynamic>{
      'calories': calories,
      'protein': protein ?? 0,
      'carbs': carbs ?? 0,
      'fat': fat ?? 0,
    };

    final name = map['name']?.toString().trim();
    if (name != null && name.isNotEmpty) {
      normalized['name'] = name;
    }

    return normalized;
  }

  static Map<String, dynamic>? _parseNutrition(String text) {
    final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
    if (jsonMatch == null) return null;

    try {
      return _normalizeNutrition(jsonDecode(jsonMatch.group(0)!));
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
