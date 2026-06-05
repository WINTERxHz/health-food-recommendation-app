import 'package:cloud_firestore/cloud_firestore.dart';

class FoodLogEntry {
  final String id;
  final String foodId;
  final String foodName;
  final int calories;
  final int protein;
  final int fat;
  final int carbs;
  final String mealType; // "Breakfast" | "Lunch" | "Dinner"
  final DateTime loggedAt;

  FoodLogEntry({
    required this.id,
    required this.foodId,
    required this.foodName,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.mealType,
    required this.loggedAt,
  });

  factory FoodLogEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FoodLogEntry(
      id: doc.id,
      foodId: data['foodId'] ?? '',
      foodName: data['foodName'] ?? '',
      calories: (data['calories'] ?? 0) as int,
      protein: data['protein'] ?? 0,
      fat: data['fat'] ?? 0,
      carbs: data['carbs'] ?? 0,
      mealType: data['mealType'] ?? 'Lunch',
      loggedAt: (data['loggedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'foodId': foodId,
        'foodName': foodName,
        'calories': calories,
        'protein': protein,
        'fat': fat,
        'carbs': carbs,
        'mealType': mealType,
        'loggedAt': Timestamp.fromDate(loggedAt),
        'dateKey': _dateKey(loggedAt), // "2025-03-09" สำหรับ query ง่าย
      };

  static String _dateKey(DateTime dt) =>
      "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";

  String get dateKey => _dateKey(loggedAt);
}
