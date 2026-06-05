import 'package:cloud_firestore/cloud_firestore.dart';

class Food {
  final String id;
  final String name;
  final int calories;
  final int protein;
  final int fat;
  final int carbs;
  final String category;
  final bool isHealthy;
  final String? emoji;

  Food({
    required this.id,
    required this.name,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.category,
    required this.isHealthy,
    this.emoji,
  });

  factory Food.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Food(
      id: doc.id,
      name: data['name'] ?? '',
      calories: data['calories'] ?? 0,
      protein: data['protein'] ?? 0,
      fat: data['fat'] ?? 0,
      carbs: data['carbs'] ?? 0,
      category: data['category'] ?? '',
      isHealthy: data['isHealthy'] ?? false,
      emoji: data['emoji'],
    );
  }
}
