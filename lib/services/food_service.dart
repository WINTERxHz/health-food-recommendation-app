import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/food_model.dart';

class FoodService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 🔹 GET
  Stream<List<Food>> getFoods({String category = ""}) {
    Query query = _db.collection('foods');

    if (category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }

    return query.snapshots().map(
          (snapshot) =>
              snapshot.docs.map((doc) => Food.fromFirestore(doc)).toList(),
        );
  }

  // 🔹 ADD
  Future<void> addFood({
    required String name,
    required int calories,
    required int protein,
    required int fat,
    required int carbs,
    required String category,
    required bool isHealthy,
  }) async {
    await _db.collection('foods').add({
      'name': name,
      'calories': calories,
      'protein': protein,
      'fat': fat,
      'carbs': carbs,
      'category': category,
      'isHealthy': isHealthy,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // 🔹 UPDATE
  Future<void> updateFood(String id, Map<String, dynamic> data) async {
    await _db.collection('foods').doc(id).update(data);
  }

  // 🔹 DELETE
  Future<void> deleteFood(String id) async {
    await _db.collection('foods').doc(id).delete();
  }
}
