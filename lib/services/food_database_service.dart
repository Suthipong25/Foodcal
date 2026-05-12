import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import '../models/nutrition_result.dart';
import '../utils/app_logger.dart';

/// Service สำหรับดึงข้อมูลโภชนาการจาก Open Food Facts
/// พร้อม Firestore Cache (TTL 30 วัน)
class FoodDatabaseService {
  static const String _baseUrl = 'https://world.openfoodfacts.org/cgi/search.pl';
  static const Duration _cacheTtl = Duration(days: 30);
  static const String _cacheCollection = 'food_cache';

  final FirebaseFirestore _db;

  FoodDatabaseService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  /// ค้นหาโภชนาการจากชื่ออาหาร
  /// คืนค่า null ถ้าไม่พบในฐานข้อมูล
  Future<NutritionResult?> searchFood(String foodName) async {
    final key = _normalizeKey(foodName);

    // 1. ตรวจ Firestore Cache ก่อน
    final cached = await _getFromCache(key);
    if (cached != null) {
      AppLogger.info('[FoodDB] Cache hit: $key');
      return cached;
    }

    // 2. ค้นหาจาก Open Food Facts API
    final result = await _fetchFromOpenFoodFacts(foodName);
    if (result != null) {
      // บันทึก cache
      await _saveToCache(key, result);
      AppLogger.info('[FoodDB] Found in Open Food Facts: ${result.name}');
    }

    return result;
  }

  // ─── Cache ──────────────────────────────────────────────────────────────

  String _normalizeKey(String name) {
    return name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
  }

  Future<NutritionResult?> _getFromCache(String key) async {
    try {
      final doc = await _db.collection(_cacheCollection).doc(key).get();
      if (!doc.exists) return null;

      final data = doc.data()!;
      final cachedAt = (data['cachedAt'] as Timestamp?)?.toDate();
      if (cachedAt == null) return null;

      // ตรวจ TTL
      if (DateTime.now().difference(cachedAt) > _cacheTtl) {
        AppLogger.info('[FoodDB] Cache expired for: $key');
        return null;
      }

      return NutritionResult.fromMap(Map<String, dynamic>.from(data));
    } catch (e) {
      AppLogger.error('[FoodDB] Cache read error', e);
      return null;
    }
  }

  Future<void> _saveToCache(String key, NutritionResult result) async {
    try {
      final map = result.toMap()..['cachedAt'] = FieldValue.serverTimestamp();
      await _db.collection(_cacheCollection).doc(key).set(map);
    } catch (e) {
      AppLogger.error('[FoodDB] Cache write error', e);
      // ไม่ throw เพราะ cache failure ไม่ควรทำให้ flow หลักล้มเหลว
    }
  }

  // ─── Open Food Facts API ────────────────────────────────────────────────

  Future<NutritionResult?> _fetchFromOpenFoodFacts(String foodName) async {
    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'search_terms': foodName,
        'search_simple': '1',
        'action': 'process',
        'json': '1',
        'page_size': '5',
        'fields':
            'product_name,product_name_th,nutriments,serving_size,quantity',
      });

      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final products = data['products'] as List<dynamic>?;
      if (products == null || products.isEmpty) return null;

      // หาผลิตภัณฑ์ที่มีข้อมูลโภชนาการครบที่สุด
      for (final raw in products) {
        final product = raw as Map<String, dynamic>;
        final nutriments = product['nutriments'] as Map<String, dynamic>?;
        if (nutriments == null) continue;

        // ค่าต่อ 100g จาก Open Food Facts
        final cal100g = _extractNum(nutriments['energy-kcal_100g'] ??
            nutriments['energy-kcal'] ??
            nutriments['energy_100g']);
        if (cal100g == null || cal100g <= 0) continue;

        final protein100g =
            _extractNum(nutriments['proteins_100g'] ?? nutriments['proteins']);
        final carbs100g = _extractNum(
            nutriments['carbohydrates_100g'] ?? nutriments['carbohydrates']);
        final fat100g =
            _extractNum(nutriments['fat_100g'] ?? nutriments['fat']);

        // ชื่อสินค้า (อาจเป็น EN)
        final rawName = (product['product_name_th'] as String?)?.trim() ??
            (product['product_name'] as String?)?.trim() ??
            foodName;

        // serving size จาก label (เช่น "240 ml", "100 g") — ใช้ 100g เป็น default
        final servingRaw =
            (product['serving_size'] as String?)?.trim() ?? '100g';
        final servingGrams = _parseServingGrams(servingRaw) ?? 100.0;

        return NutritionResult(
          name: rawName,
          calories: ((cal100g * servingGrams) / 100).round(),
          protein: ((protein100g ?? 0) * servingGrams / 100).round(),
          carbs: ((carbs100g ?? 0) * servingGrams / 100).round(),
          fat: ((fat100g ?? 0) * servingGrams / 100).round(),
          servingLabel: servingRaw,
          source: NutritionSource.database,
        );
      }

      return null;
    } catch (e) {
      AppLogger.error('[FoodDB] Open Food Facts fetch error', e);
      return null;
    }
  }

  /// แปลง "240 ml" หรือ "100 g" เป็นตัวเลข gram/ml
  double? _parseServingGrams(String serving) {
    final match = RegExp(r'([\d.]+)').firstMatch(serving);
    return match != null ? double.tryParse(match.group(1)!) : null;
  }

  double? _extractNum(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
