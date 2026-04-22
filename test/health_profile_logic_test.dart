import 'package:flutter_test/flutter_test.dart';
import 'package:foodcal/models/daily_log.dart';
import 'package:foodcal/services/firestore_service.dart';
import 'package:foodcal/utils/health_profile_stats.dart';

void main() {
  group('HealthProfileValidator', () {
    test('rejects impossible lose goal target', () {
      final error = HealthProfileValidator.validate(
        name: 'Pat',
        birthMonth: 5,
        birthYear: 1995,
        height: 170,
        weight: 65,
        targetWeight: 70,
        goal: 'lose',
      );

      expect(error, isNotNull);
    });

    test('accepts valid profile values', () {
      final error = HealthProfileValidator.validate(
        name: 'Pat',
        birthMonth: 5,
        birthYear: 1995,
        height: 170,
        weight: 65,
        targetWeight: 60,
        goal: 'lose',
      );

      expect(error, isNull);
    });
  });

  group('FirestoreService login streak', () {
    test('returns null when already synced today in Bangkok', () {
      final nextStreak = FirestoreService.calculateNextLoginStreak(
        currentStreak: 5,
        rawLastLogin: '2026-04-22T00:30:00Z',
        now: DateTime.utc(2026, 4, 22, 8, 0),
      );

      expect(nextStreak, isNull);
    });

    test('increments streak for consecutive Bangkok day', () {
      final nextStreak = FirestoreService.calculateNextLoginStreak(
        currentStreak: 5,
        rawLastLogin: '2026-04-21T01:00:00Z',
        now: DateTime.utc(2026, 4, 22, 2, 0),
      );

      expect(nextStreak, 6);
    });

    test('resets streak after a gap', () {
      final nextStreak = FirestoreService.calculateNextLoginStreak(
        currentStreak: 5,
        rawLastLogin: '2026-04-18T01:00:00Z',
        now: DateTime.utc(2026, 4, 22, 2, 0),
      );

      expect(nextStreak, 1);
    });
  });

  group('FirestoreService workout helpers', () {
    test('required workout minutes uses 60 percent rule', () {
      expect(FirestoreService.requiredWorkoutMinutes(20), 12);
      expect(FirestoreService.requiredWorkoutMinutes(1), 1);
    });

    test('workout calories depend on level', () {
      expect(
        FirestoreService.calculateWorkoutCalories(
          WorkoutItem(
            id: 1,
            title: 'A',
            level: 'Beginner',
            duration: '10 min',
            minutes: 10,
            type: 'Cardio',
            completedAt: DateTime(2026, 4, 22),
          ),
        ),
        50,
      );

      expect(
        FirestoreService.calculateWorkoutCalories(
          WorkoutItem(
            id: 2,
            title: 'B',
            level: 'Intermediate',
            duration: '10 min',
            minutes: 10,
            type: 'Cardio',
            completedAt: DateTime(2026, 4, 22),
          ),
        ),
        70,
      );
    });
  });
}
