import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../constants/app_config.dart';
import '../utils/app_logger.dart';

class AIService {
  static String get _apiKey {
    final key = dotenv.env['GEMINI_API_KEY']?.trim() ?? '';
    return key;
  }

  static const String _model = 'gemini-2.0-flash';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  static bool get isConfigured => _apiKey.isNotEmpty;

  static String get configErrorMessage =>
      'ฟีเจอร์ AI ยังไม่พร้อมใช้งาน กรุณาตั้งค่า GEMINI_API_KEY ก่อน';

  static Uri get _generateContentUri =>
      Uri.parse('$_baseUrl/$_model:generateContent?key=$_apiKey');

  // ── Estimate food nutrition from name ──────────────────────────────────────

  static Future<Map<String, dynamic>?> estimateCalories(String foodName) async {
    final normalized = foodName.trim();
    if (normalized.isEmpty || !isConfigured) return null;

    const prompt = '''You are a nutrition expert.
Estimate the nutrition for "{food}" (1 serving, typical Thai serving size) and respond in exactly 4 lines:
calories: <integer>
protein: <integer>
carbs: <integer>
fat: <integer>

Rules:
- use only integers
- no markdown
- no explanation''';

    final text = await _generateText(
      prompt.replaceAll('{food}', normalized),
    );
    if (text == null) return null;
    return _parseNutrition(text);
  }

  // ── Analyze food image ─────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> analyzeFoodImage(
      Uint8List imageBytes) async {
    if (imageBytes.isEmpty || !isConfigured) return null;

    const prompt = '''You are a nutrition expert.
Analyze this food image and respond in exactly 5 lines:
name: <food name in Thai>
calories: <integer>
protein: <integer>
carbs: <integer>
fat: <integer>

Rules:
- use only integers
- per 1 serving
- no markdown
- no explanation
- if uncertain, still estimate the closest common Thai dish''';

    final body = {
      'contents': [
        {
          'parts': [
            {'text': prompt},
            {
              'inline_data': {
                'mime_type': 'image/jpeg',
                'data': base64Encode(imageBytes),
              }
            },
          ],
        }
      ],
      'generationConfig': {
        'temperature': 0.1,
        'maxOutputTokens': 256,
      },
    };

    final text = await _callGemini(body);
    if (text == null) return null;
    return _parseNutrition(text);
  }

  // ── Ask AI Coach ───────────────────────────────────────────────────────────

  static Future<String?> askCoach(
    String message, {
    List<Map<String, String>> history = const [],
  }) async {
    final normalized = message.trim();
    if (normalized.isEmpty || !isConfigured) return null;

    final historyContext = history
        .where((e) =>
            e['role'] != null && e['content'] != null && e['role'] != 'error')
        .toList()
        .reversed
        .take(10)
        .toList()
        .reversed
        .map(
            (e) => '${e['role'] == 'user' ? 'User' : 'Coach'}: ${e['content']}')
        .join('\n');

    final prompt =
        '''You are a friendly Thai health coach for an app called Foodcal.
Reply only in Thai. Keep the advice practical, concise, and safe.
If the user asks about a plateau, overeating, low protein, low water intake, or consistency, give 3-5 actionable suggestions.
Avoid medical diagnosis and tell the user to seek a professional if symptoms sound dangerous.

${historyContext.isNotEmpty ? 'Previous conversation:\n$historyContext\n\n' : ''}User: $normalized''';

    return _generateText(
      prompt,
      temperature: 0.7,
      maxOutputTokens: 512,
    );
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  static Future<String?> _generateText(
    String prompt, {
    double temperature = 0.1,
    int maxOutputTokens = 128,
  }) async {
    final body = {
      'contents': [
        {
          'parts': [
            {'text': prompt},
          ],
        }
      ],
      'generationConfig': {
        'temperature': temperature,
        'maxOutputTokens': maxOutputTokens,
      },
    };
    return _callGemini(body);
  }

  static Future<String?> _callGemini(Map<String, dynamic> body) async {
    try {
      final response = await http
          .post(
            _generateContentUri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(AppConfig.geminiRequestTimeout);

      // Handle non-2xx status codes
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final errorMessage =
            _categorizeGeminiError(response.statusCode, response.body);
        AppLogger.warn('[Gemini API] Error $errorMessage');
        return null;
      }

      // Parse response
      final decoded = jsonDecode(response.body) as Map<String, dynamic>?;
      final text = decoded?['candidates']?[0]?['content']?['parts']
          ?.firstWhere(
            (p) => p['text'] != null,
            orElse: () => null,
          )?['text']
          ?.toString()
          .trim();

      return (text == null || text.isEmpty) ? null : text;
    } on TimeoutException catch (e) {
      AppLogger.warn('[Gemini API] Request timeout: $e');
      return null;
    } on SocketException catch (e) {
      AppLogger.warn('[Gemini API] Network error: $e');
      return null;
    } on FormatException catch (e) {
      AppLogger.warn('[Gemini API] Response parse error: $e');
      return null;
    } catch (e) {
      final errorType = _categorizeException(e);
      AppLogger.error('[Gemini API] Request failed ($errorType)', e);
      return null;
    }
  }

  /// Categorize HTTP error status codes
  static String _categorizeGeminiError(int statusCode, String body) {
    final hasQuotaError = body.toLowerCase().contains('quota');
    if (hasQuotaError) return 'Quota exceeded';
    switch (statusCode) {
      case 400:
        return 'Bad request - invalid input';
      case 401:
      case 403:
        return 'Authentication failed - check API key';
      case 429:
        return 'Rate limited - too many requests';
      case 500:
      case 502:
      case 503:
        return 'Service temporarily unavailable';
      default:
        return 'HTTP $statusCode';
    }
  }

  /// Categorize exception types for better error handling
  static String _categorizeException(Object error) {
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('socket') || errorStr.contains('connection')) {
      return 'NetworkError';
    }
    if (errorStr.contains('timeout')) {
      return 'TimeoutError';
    }
    if (errorStr.contains('format')) {
      return 'FormatError';
    }

    return 'UnknownError';
  }

  static Map<String, dynamic>? _parseNutrition(String text) {
    // Try JSON first
    final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
    if (jsonMatch != null) {
      try {
        final parsed = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>?;
        if (parsed != null) return _normalizeNutrition(parsed);
      } catch (_) {}
    }

    // Parse key: value lines
    final result = <String, dynamic>{};
    for (final rawLine in text.replaceAll('\r', '').split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;
      final match = RegExp(r'^([A-Za-z_ ]+)\s*:\s*(.+)$').firstMatch(line);
      if (match == null) continue;

      final key = match.group(1)!.trim().toLowerCase().replaceAll(' ', '');
      final value = match.group(2)!.trim();

      if (key == 'name') {
        result['name'] = value;
        continue;
      }

      final numMatch = RegExp(r'-?\d+').firstMatch(value);
      if (numMatch == null) continue;
      final number = int.tryParse(numMatch.group(0)!);
      if (number == null) continue;

      if (key.contains('calorie')) result['calories'] = number;
      if (key == 'protein') result['protein'] = number;
      if (key == 'carbs' || key == 'carb') result['carbs'] = number;
      if (key == 'fat') result['fat'] = number;
    }

    return _normalizeNutrition(result);
  }

  @visibleForTesting
  static Map<String, dynamic>? parseNutritionForTest(String text) {
    return _parseNutrition(text);
  }

  static Map<String, dynamic>? _normalizeNutrition(
      Map<String, dynamic> result) {
    final calories = _toInt(result['calories']);
    final protein = _toInt(result['protein']);
    final carbs = _toInt(result['carbs']);
    final fat = _toInt(result['fat']);

    if (calories == null || protein == null || carbs == null || fat == null) {
      return null;
    }

    final normalized = <String, dynamic>{
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };

    final name = result['name']?.toString().trim();
    if (name != null && name.isNotEmpty) normalized['name'] = name;

    return normalized;
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    if (value == null) return null;
    final match = RegExp(r'-?\d+').firstMatch(value.toString());
    return match != null ? int.tryParse(match.group(0)!) : null;
  }
}
