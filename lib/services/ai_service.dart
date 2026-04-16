import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AIService {
  static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  static String get _backendUrl => dotenv.env['AI_BACKEND_URL']?.trim() ?? '';
  static const Duration _timeout = Duration(seconds: 30);
  static const List<String> _apiVersions = ['v1', 'v1beta'];
  static const List<String> _defaultModels = [
    'gemini-2.0-flash',
    'gemini-1.5-flash-latest',
    'gemini-1.5-pro-latest',
    'gemini-pro',
    'gemini-1.5-pro',
    'gemini-2.5-flash',
    'gemini-1.5-flash',
  ];

  static List<String> get _models {
    final envModel = dotenv.env['GEMINI_MODEL']?.trim();
    final models = <String>[
      if (envModel != null && envModel.isNotEmpty) envModel,
      ..._defaultModels,
    ];
    return models.toSet().toList();
  }

  static bool get isConfigured =>
      _backendUrl.isNotEmpty || _apiKey.isNotEmpty;

  static bool get requiresBackend => kIsWeb;
  static String get configErrorMessage {
    if (kIsWeb && _backendUrl.isEmpty) {
      return 'เวอร์ชันเว็บต้องตั้งค่า AI_BACKEND_URL ก่อน จึงจะใช้ AI ได้';
    }
    if (!kIsWeb && _backendUrl.isEmpty && _apiKey.isEmpty) {
      return 'กรุณาตั้งค่า GEMINI_API_KEY หรือ AI_BACKEND_URL ก่อนใช้งาน AI';
    }
    return 'ฟีเจอร์ AI ยังไม่พร้อมใช้งาน';
  }

  static String _buildUrl(String version, String model) =>
      'https://generativelanguage.googleapis.com/$version/models/$model:generateContent?key=$_apiKey';

  static Uri _buildBackendUri(String path) {
    final base = _backendUrl.endsWith('/')
        ? _backendUrl.substring(0, _backendUrl.length - 1)
        : _backendUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$base$normalizedPath');
  }

  static Future<Map<String, dynamic>?> analyzeFoodImage(
    Uint8List imageBytes,
  ) async {
    if (imageBytes.isEmpty || !isConfigured) return null;

    if (_backendUrl.isNotEmpty) {
      return _postToBackend(
        _buildBackendUri('/analyzeFoodImage'),
        {'imageBase64': base64Encode(imageBytes)},
      );
    }

    const prompt = '''
You are a highly accurate nutrition expert.
Analyze this food image and respond with valid JSON using exactly this structure:
{
  "name": "food name in Thai",
  "calories": 0,
  "protein": 0,
  "carbs": 0,
  "fat": 0
}

Rules for accuracy:
1. All values must be integers (except name).
2. Estimate for 1 standard Thai serving size. 
3. Be realistic about Thai street food (it often contains hidden cooking oils or sugar).
4. CRITICAL: Your total calories MUST be mathematically correct. It must roughly equal: (protein * 4) + (carbs * 4) + (fat * 9).
5. If uncertain about the exact image, estimate the closest common Thai dish.
6. Output ONLY valid JSON, no markdown formatting.
''';

    final body = {
      'contents': [
        {
          'parts': [
            {'text': prompt},
            {
              'inline_data': {
                'mime_type': 'image/jpeg',
                'data': base64Encode(imageBytes),
              },
            },
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.1,
      },
    };

    return _postToGemini(body);
  }

  static Future<Map<String, dynamic>?> estimateCalories(String foodName) async {
    if (foodName.trim().isEmpty || !isConfigured) return null;

    if (_backendUrl.isNotEmpty) {
      return _postToBackend(
        _buildBackendUri('/estimateFood'),
        {'foodName': foodName.trim()},
      );
    }

    final prompt = '''
You are a nutrition expert.
Estimate the nutrition for "$foodName" (1 serving) and respond with valid JSON using exactly this structure:
{
  "calories": 0,
  "protein": 0,
  "carbs": 0,
  "fat": 0
}

Rules for accuracy:
1. All values must be integers.
2. Use a standard Thai serving size (e.g., 1 full plate or 1 bowl).
3. Be realistic about Thai preparation methods, which often include extra fats.
4. CRITICAL: Your total calories MUST be mathematically correct. It must roughly equal: (protein * 4) + (carbs * 4) + (fat * 9).
5. Output ONLY valid JSON, no markdown formatting.
''';

    final body = {
      'contents': [
        {
          'parts': [
            {'text': prompt},
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.1,
      },
    };

    return _postToGemini(body);
  }

  static Future<String?> askCoach(String message, {List<Map<String, String>> history = const []}) async {
    if (message.trim().isEmpty || !isConfigured) return null;

    if (_backendUrl.isNotEmpty) {
      final response = await _postToBackend(
        _buildBackendUri('/askCoach'),
        {'message': message.trim(), 'history': history},
      );
      if (response != null && response.containsKey('reply')) {
        return response['reply'] as String;
      }
    }

    String historyContext = '';
    if (history.isNotEmpty) {
      historyContext =
          'Previous conversation:\n${history.map((e) => "${e['role'] == 'user' ? 'User' : 'Coach'}: ${e['content']}").join('\n')}\n\n';
    }

    final prompt = '''
You are a friendly, encouraging, and knowledgeable health and nutrition coach for an app called "Foodcal".
Respond to the user naturally and directly in Thai. Keep your answers concise, practical, and highly relevant to diet, fitness, and standard Thai food. Avoid markdown structure if possible.
$historyContext
User message: "$message"
''';

    final body = {
      'contents': [
        {
          'parts': [
            {'text': prompt},
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.7,
      },
    };

    try {
      for (final version in _apiVersions) {
        for (final model in _models) {
          final uri = Uri.parse(_buildUrl(version, model));
          final response = await http
              .post(
                uri,
                headers: const {'Content-Type': 'application/json'},
                body: jsonEncode(body),
              )
              .timeout(_timeout);

          if (response.statusCode == 404 || response.statusCode == 503 || response.statusCode == 429) {
            continue;
          }

          if (response.statusCode >= 200 && response.statusCode < 300) {
             final decoded = jsonDecode(response.body);
             final text = _extractCandidateText(decoded);
             if (text != null && text.isNotEmpty) return text;
          }
        }
      }
    } catch (e) {
      debugPrint('Gemini askCoach failed: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> _postToGemini(
    Map<String, dynamic> body,
  ) async {
    try {
      for (final version in _apiVersions) {
        for (final model in _models) {
          final uri = Uri.parse(_buildUrl(version, model));
          final response = await http
              .post(
                uri,
                headers: const {'Content-Type': 'application/json'},
                body: jsonEncode(body),
              )
              .timeout(_timeout);

          if (response.statusCode == 404 || response.statusCode == 503 || response.statusCode == 429) {
            debugPrint('Gemini model unavailable or overloaded for $version/$model (Code: ${response.statusCode})');
            continue;
          }

          if (response.statusCode < 200 || response.statusCode >= 300) {
            debugPrint(
              'Gemini error ${response.statusCode} on $version/$model: ${response.body}',
            );
            return null;
          }

          final decoded = jsonDecode(response.body);
          if (decoded is! Map<String, dynamic>) {
            debugPrint('Gemini returned invalid payload on $version/$model');
            return null;
          }

          final text = _extractCandidateText(decoded);
          if (text == null || text.isEmpty) {
            debugPrint('Gemini returned empty content on $version/$model');
            return null;
          }

          final parsed = _parseNutritionResponse(text);
          if (parsed != null) return parsed;

          debugPrint('Gemini returned unparsable text on $version/$model: $text');
          return null;
        }
      }
    } catch (e) {
      debugPrint('Gemini request failed: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> _postToBackend(
    Uri uri,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await http
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint('AI backend error ${response.statusCode}: ${response.body}');
        return null;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return _normalizeResult(decoded);
      if (decoded is Map) {
        return _normalizeResult(decoded.map((k, v) => MapEntry(k.toString(), v)));
      }
    } catch (e) {
      debugPrint('AI backend request failed: $e');
    }
    return null;
  }

  static String? _extractCandidateText(Map<String, dynamic> decoded) {
    final candidates = decoded['candidates'];
    if (candidates is! List || candidates.isEmpty) return null;

    final first = candidates.first;
    if (first is! Map) return null;

    final content = first['content'];
    if (content is! Map) return null;

    final parts = content['parts'];
    if (parts is! List || parts.isEmpty) return null;

    for (final part in parts) {
      if (part is Map && part['text'] is String) {
        return part['text'] as String;
      }
    }

    return null;
  }

  static String? _extractJson(String text) {
    final trimmed = text.trim();
    if (trimmed.startsWith('{')) return trimmed;

    final codeBlock = RegExp(r'```(?:json)?\s*(\{[\s\S]*?\})\s*```');
    final match = codeBlock.firstMatch(trimmed);
    if (match != null) return match.group(1);

    final jsonOnly = RegExp(r'\{[\s\S]*\}');
    final jsonMatch = jsonOnly.firstMatch(trimmed);
    return jsonMatch?.group(0);
  }

  static Map<String, dynamic>? _parseNutritionResponse(String text) {
    final jsonStr = _extractJson(text);
    if (jsonStr != null) {
      final result = jsonDecode(jsonStr);
      if (result is Map<String, dynamic>) return _normalizeResult(result);
      if (result is Map) {
        return _normalizeResult(result.map((k, v) => MapEntry(k.toString(), v)));
      }
    }

    final normalized = text.replaceAll('\r', '');
    final lines = normalized
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    final result = <String, dynamic>{};
    for (final line in lines) {
      final match = RegExp(r'^([A-Za-z_ ]+)\s*:\s*(.+)$').firstMatch(line);
      if (match == null) continue;

      final key = match.group(1)!.trim().toLowerCase().replaceAll(' ', '');
      final value = match.group(2)!.trim();

      if (key == 'name') {
        result['name'] = value;
        continue;
      }

      final number = RegExp(r'-?\d+').firstMatch(value);
      if (number == null) continue;
      final parsed = int.tryParse(number.group(0)!);
      if (parsed == null) continue;

      if (key.contains('calorie')) result['calories'] = parsed;
      if (key == 'protein') result['protein'] = parsed;
      if (key == 'carbs' || key == 'carb') result['carbs'] = parsed;
      if (key == 'fat') result['fat'] = parsed;
    }

    return _normalizeResult(result);
  }

  static Map<String, dynamic>? _normalizeResult(Map<String, dynamic> result) {
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
    if (name != null && name.isNotEmpty) {
      normalized['name'] = name;
    }

    return normalized;
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    if (value == null) return null;

    final match = RegExp(r'-?\d+').firstMatch(value.toString());
    if (match == null) return null;
    return int.tryParse(match.group(0)!);
  }
}
