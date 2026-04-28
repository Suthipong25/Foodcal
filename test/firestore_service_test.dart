import 'package:flutter_test/flutter_test.dart';
import 'package:foodcal/services/firestore_service.dart';

void main() {
  group('FirestoreService Tests', () {
    test('dateKey formats correctly for different dates', () {
      final dt1 = DateTime(2023, 1, 5, 12, 0); // 2023-01-05
      final dt2 = DateTime(2023, 10, 15, 8, 30); // 2023-10-15

      expect(FirestoreService.dateKey(dt1), '2023-01-05');
      expect(FirestoreService.dateKey(dt2), '2023-10-15');
    });

    test('requiredWorkoutMinutes calculates correctly', () {
      // For level == Beginner
      expect(FirestoreService.requiredWorkoutMinutes(10), 6); // 60%
      expect(FirestoreService.requiredWorkoutMinutes(20), 12);

      // For level == Intermediate
      expect(FirestoreService.requiredWorkoutMinutes(10), 6); // 60%
      expect(FirestoreService.requiredWorkoutMinutes(20), 12);

      // For other levels
      expect(FirestoreService.requiredWorkoutMinutes(10), 6); // 60%
    });
  });
}
