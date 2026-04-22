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
      expect(FirestoreService.requiredWorkoutMinutes(10, 'Beginner'), 7); // 70%
      expect(FirestoreService.requiredWorkoutMinutes(20, 'Beginner'), 14);

      // For level == Intermediate
      expect(FirestoreService.requiredWorkoutMinutes(10, 'Intermediate'), 8); // 80%
      expect(FirestoreService.requiredWorkoutMinutes(20, 'Intermediate'), 16);

      // For other levels
      expect(FirestoreService.requiredWorkoutMinutes(10, 'Expert'), 9); // 90%
    });
  });
}
