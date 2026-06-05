import 'package:flutter_test/flutter_test.dart';
import 'package:appfoodh/services/profile_service.dart';
import 'package:appfoodh/models/food_log_model.dart';
import 'package:appfoodh/models/user_model.dart';

void main() {
  // ──────────────────────────────────────────────────
  // 1. ProfileService.calculateBMI
  // ──────────────────────────────────────────────────
  group('ProfileService.calculateBMI', () {
    final service = ProfileService();

    test('Normal BMI — 70kg, 175cm → ~22.9', () {
      final bmi = service.calculateBMI(70, 175);
      expect(bmi, closeTo(22.86, 0.1));
    });

    test('Underweight — 45kg, 170cm → ~15.6', () {
      final bmi = service.calculateBMI(45, 170);
      expect(bmi, closeTo(15.57, 0.1));
    });

    test('Overweight — 90kg, 170cm → ~31.1', () {
      final bmi = service.calculateBMI(90, 170);
      expect(bmi, closeTo(31.14, 0.1));
    });

    test('height = 0 should return 0 (no division by zero)', () {
      final bmi = service.calculateBMI(70, 0);
      expect(bmi, equals(0));
    });
  });

  // ──────────────────────────────────────────────────
  // 2. FoodLogEntry.dateKey
  // ──────────────────────────────────────────────────
  group('FoodLogEntry.dateKey', () {
    test('formats date correctly with zero-padding', () {
      final entry = FoodLogEntry(
        id: '1',
        foodId: 'f1',
        foodName: 'Apple',
        calories: 95,
        protein: 0,
        fat: 0,
        carbs: 25,
        mealType: 'Snack',
        loggedAt: DateTime(2025, 3, 9),
      );
      expect(entry.dateKey, equals('2025-03-09'));
    });

    test('formats double-digit month and day correctly', () {
      final entry = FoodLogEntry(
        id: '2',
        foodId: 'f2',
        foodName: 'Rice',
        calories: 200,
        protein: 4,
        fat: 0,
        carbs: 45,
        mealType: 'Lunch',
        loggedAt: DateTime(2025, 12, 25),
      );
      expect(entry.dateKey, equals('2025-12-25'));
    });
  });

  // ──────────────────────────────────────────────────
  // 3. UserModel
  // ──────────────────────────────────────────────────
  group('UserModel', () {
    test('fullName returns firstName + lastName', () {
      final user = UserModel(
        firstName: 'John',
        lastName: 'Doe',
        dietType: 'Balanced',
        goal: 'Maintain',
        weight: 70,
        height: 175,
        bmi: 22.9,
        gender: 'Male', // เพิ่ม gender
      );
      expect(user.fullName, equals('John Doe'));
    });

    test('copyWith updates only specified fields', () {
      final user = UserModel(
        firstName: 'John',
        lastName: 'Doe',
        dietType: 'Balanced',
        goal: 'Maintain',
        weight: 70,
        height: 175,
        bmi: 22.9,
        gender: 'Male', // เพิ่ม gender
      );
      final updated = user.copyWith(weight: 75, bmi: 24.5, gender: 'Female');
      expect(updated.weight, equals(75));
      expect(updated.bmi, equals(24.5));
      expect(updated.gender, equals('Female')); // ทดสอบค่าที่เพิ่มใหม่
      expect(updated.firstName, equals('John')); // ไม่เปลี่ยน
    });
    test('fromMap handles missing fields with defaults', () {
      final user = UserModel.fromMap({});
      expect(user.firstName, equals(''));
      expect(user.dietType, equals('Balanced'));
      expect(user.bmi, equals(0.0));
      expect(user.gender, equals('Male')); // ทดสอบ Default value ของเพศ
    });
  });

  // ──────────────────────────────────────────────────
  // 4. BMI Label logic
  // ──────────────────────────────────────────────────
  group('BMI classification', () {
    String bmiLabel(double bmi) {
      if (bmi < 18.5) return 'Underweight';
      if (bmi < 25) return 'Normal';
      if (bmi < 30) return 'Overweight';
      return 'Obese';
    }

    test('BMI 17 → Underweight', () => expect(bmiLabel(17), 'Underweight'));
    test('BMI 22 → Normal', () => expect(bmiLabel(22), 'Normal'));
    test('BMI 27 → Overweight', () => expect(bmiLabel(27), 'Overweight'));
    test('BMI 35 → Obese', () => expect(bmiLabel(35), 'Obese'));
    test(
        'BMI 18.5 → Normal (boundary)', () => expect(bmiLabel(18.5), 'Normal'));
    test('BMI 25 → Overweight (boundary)',
        () => expect(bmiLabel(25), 'Overweight'));
  });
}
