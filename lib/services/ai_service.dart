import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AIService {
  static const String _backendUrl = String.fromEnvironment('AI_BACKEND_URL');
  static const Duration _timeout = Duration(seconds: 20);

  static bool get isConfigured => _backendUrl.isNotEmpty;

  static Future<Map<String, dynamic>?> analyzeFoodImage(Uint8List imageBytes) async {
    if (imageBytes.isEmpty || !isConfigured) return null;

    return _postJson(
      endpoint: 'analyze-food-image',
      payload: {
        'imageBase64': base64Encode(imageBytes),
      },
    );
  }

  static Future<Map<String, dynamic>?> estimateCalories(String foodName) async {
    if (foodName.trim().isEmpty || !isConfigured) return null;

    return _postJson(
      endpoint: 'estimate-food',
      payload: {
        'foodName': foodName.trim(),
      },
    );
  }

  static Future<Map<String, dynamic>?> _postJson({
    required String endpoint,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final uri = _resolveEndpoint(endpoint);
      final response = await http
          .post(
            uri,
            headers: const {
              'Content-Type': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(_timeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint('AI backend error ${response.statusCode}: ${response.body}');
        return null;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      if (decoded is Map) {
        return decoded.map(
          (key, value) => MapEntry(key.toString(), value),
        );
      }
    } catch (e) {
      debugPrint('AI backend request failed: $e');
    }
    return null;
  }

  static Uri _resolveEndpoint(String endpoint) {
    final baseUri = Uri.parse(_backendUrl);
    final normalizedBasePath = baseUri.path.endsWith('/')
        ? baseUri.path
        : '${baseUri.path}/';
    return baseUri.replace(path: '$normalizedBasePath$endpoint');
  }
}
