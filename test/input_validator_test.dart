import 'package:flutter_test/flutter_test.dart';
import 'package:foodcal/utils/input_validator.dart';

void main() {
  group('InputValidator', () {
    test('rejects empty food name', () {
      expect(InputValidator.validateFoodName('   '), isNotNull);
    });

    test('sanitizes repeated spaces and control chars', () {
      final value = InputValidator.sanitizeForStorage('  ข้าว\u0000  มัน   ไก่  ');
      expect(value, 'ข้าว มัน ไก่');
    });

    test('rejects too high calories', () {
      expect(InputValidator.validateCalories('99999'), isNotNull);
    });
  });
}
