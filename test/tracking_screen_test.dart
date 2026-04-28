import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodcal/models/daily_log.dart';
import 'package:foodcal/models/user_profile.dart';
import 'package:foodcal/screens/tracking_screen.dart';

void main() {
  testWidgets('TrackingScreen displays target water and current water correctly',
      (WidgetTester tester) async {
    // Create mock data
    final profile = UserProfile(
      uid: 'test_uid',
      name: 'Test User',
      gender: 'male',
      birthMonth: 1,
      birthYear: 1990,
      height: 175,
      weight: 70,
      targetWeight: 65,
      activityLevel: 'moderate',
      goal: 'lose',
      tdee: 2500,
      targetCalories: 2000,
      targetProtein: 150,
      targetCarbs: 200,
      targetFat: 60,
      targetWaterGlasses: 8,
      joinedDate: DateTime.now(),
    );

    final log = DailyLog(
      date: '2023-01-01',
      caloriesIn: 500,
      caloriesOut: 200,
      protein: 30,
      carbs: 50,
      fat: 10,
      waterGlasses: 3,
      foods: [],
      workouts: [],
      lastUpdated: DateTime.now(),
    );

    // Build our app and trigger a frame.
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TrackingScreen(
          log: log,
          profile: profile,
          scanRequestVersion: 0,
        ),
      ),
    ));

    // Verify that water texts are displayed.
    expect(find.textContaining('เป้าหมาย 8 แก้ว'), findsOneWidget);
    expect(find.text('3'), findsOneWidget); // Current water glasses
    expect(find.text('1 แก้ว'), findsOneWidget); // Add 1 glass button
  });
}
