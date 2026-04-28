import 'package:flutter_test/flutter_test.dart';
import 'package:foodcal/services/ai_service.dart';

void main() {
  group('AIService parser', () {
    test('parses key-value nutrition response', () {
      const text = '''
name: ข้าวมันไก่
calories: 560
protein: 24
carbs: 72
fat: 18
''';

      final result = AIService.parseNutritionForTest(text);

      expect(result, isNotNull);
      expect(result!['name'], 'ข้าวมันไก่');
      expect(result['calories'], 560);
      expect(result['protein'], 24);
      expect(result['carbs'], 72);
      expect(result['fat'], 18);
    });

    test('returns null when required fields are missing', () {
      const text = 'name: ข้าวผัด\ncalories: 500';
      final result = AIService.parseNutritionForTest(text);
      expect(result, isNull);
    });
  });
}
