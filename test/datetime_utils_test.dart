import 'package:flutter_test/flutter_test.dart';
import 'package:foodcal/utils/datetime_utils.dart';

void main() {
  group('DateTimeUtils', () {
    test('dateKey formats as YYYY-MM-DD', () {
      final key = DateTimeUtils.dateKey(DateTime(2026, 4, 28, 22, 10));
      expect(key, '2026-04-28');
    });

    test('parseDateKey handles invalid input safely', () {
      expect(DateTimeUtils.parseDateKey('bad-key'), isNull);
      expect(DateTimeUtils.parseDateKey(null), isNull);
    });

    test('isSameDay compares by calendar day', () {
      final a = DateTime(2026, 4, 28, 7, 0);
      final b = DateTime(2026, 4, 28, 23, 59);
      expect(DateTimeUtils.isSameDay(a, b), isTrue);
    });
  });
}
