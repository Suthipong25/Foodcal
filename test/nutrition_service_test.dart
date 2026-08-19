import 'package:flutter_test/flutter_test.dart';
import 'package:foodcal/models/nutrition_result.dart';
import 'package:foodcal/services/food_database_service.dart';
import 'package:foodcal/services/nutrition_service.dart';

void main() {
  late _FakeFoodDatabaseService fakeFoodDb;

  setUp(() {
    fakeFoodDb = _FakeFoodDatabaseService();
    NutritionService.setFoodDatabaseServiceForTest(fakeFoodDb);
    NutritionService.setApiKeyForTest('');
  });

  tearDown(() {
    NutritionService.resetTestingOverrides();
  });

  group('NutritionService.lookupFood', () {
    test('checks database/cache before AI for Thai food names', () async {
      const dbResult = NutritionResult(
        name: 'ข้าวผัดหมูจาก cache',
        calories: 540,
        protein: 22,
        carbs: 70,
        fat: 18,
        servingLabel: '1 จาน',
        source: NutritionSource.database,
      );
      fakeFoodDb.result = dbResult;

      final result = await NutritionService.lookupFood('ข้าวผัดหมู');

      expect(fakeFoodDb.queries, ['ข้าวผัดหมู']);
      expect(result, same(dbResult));
      expect(result!.source, NutritionSource.database);
    });

    test('returns null after database miss when AI is not configured', () async {
      final result = await NutritionService.lookupFood('เมนูที่ไม่มีในฐานข้อมูล');

      expect(fakeFoodDb.queries, ['เมนูที่ไม่มีในฐานข้อมูล']);
      expect(result, isNull);
    });

    test('does not query database for empty input', () async {
      final result = await NutritionService.lookupFood('   ');

      expect(fakeFoodDb.queries, isEmpty);
      expect(result, isNull);
    });
  });
}

class _FakeFoodDatabaseService implements FoodDatabaseService {
  NutritionResult? result;
  final List<String> queries = [];

  @override
  Future<NutritionResult?> searchFood(String foodName) async {
    queries.add(foodName);
    return result;
  }
}
