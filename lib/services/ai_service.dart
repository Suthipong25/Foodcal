import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AIService {
  static String get _backendUrl => dotenv.env['AI_BACKEND_URL']?.trim() ?? '';
  static const Duration _timeout = Duration(seconds: 30);

  static bool get isConfigured => _backendUrl.isNotEmpty;
  static bool get requiresBackend => true;

  static String get configErrorMessage =>
      'ฟีเจอร์ AI ยังไม่พร้อมใช้งาน กรุณาตั้งค่า AI_BACKEND_URL ก่อน';

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

    return _postNutritionRequest(
      _buildBackendUri('/analyzeFoodImage'),
      {'imageBase64': base64Encode(imageBytes)},
    );
  }

  static Future<Map<String, dynamic>?> estimateCalories(String foodName) async {
    final normalizedFoodName = foodName.trim();
    if (normalizedFoodName.isEmpty || !isConfigured) return null;

    return _postNutritionRequest(
      _buildBackendUri('/estimateFood'),
      {'foodName': normalizedFoodName},
    );
  }

  static Future<String?> askCoach(
    String message, {
    List<Map<String, String>> history = const [],
  }) async {
    final normalizedMessage = message.trim();
    if (normalizedMessage.isEmpty || !isConfigured) return null;

    final response = await _postJsonRequest(
      _buildBackendUri('/askCoach'),
      {
        'message': normalizedMessage,
        'history': history,
      },
    );

    final reply = response?['reply']?.toString().trim();
    if (reply == null || reply.isEmpty) return null;
    return reply;
  }

  static Future<Map<String, dynamic>?> _postNutritionRequest(
    Uri uri,
    Map<String, dynamic> body,
  ) async {
    final response = await _postJsonRequest(uri, body);
    if (response == null) return null;
    return _normalizeNutritionResult(response);
  }

  static Future<Map<String, dynamic>?> _postJsonRequest(
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
        debugPrint(
          'AI backend error ${response.statusCode}: ${response.body}',
        );
        return null;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
    } catch (error) {
      debugPrint('AI backend request failed: $error');
    }

    return null;
  }

  static Map<String, dynamic>? _normalizeNutritionResult(
    Map<String, dynamic> result,
  ) {
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
