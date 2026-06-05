import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/food_model.dart';

class FavoriteService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Stream รายการ food id ที่ user กด favorite ไว้
  Stream<List<String>> getFavoriteIds(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return [];
      final data = doc.data()!;
      final favs = data['favorites'];
      if (favs == null) return <String>[];
      return List<String>.from(favs);
    });
  }

  /// Stream รายการ Food object ที่ user favorite ไว้
  Stream<List<Food>> getFavoriteFoods(String uid) {
    return getFavoriteIds(uid).asyncMap((ids) async {
      if (ids.isEmpty) return [];

      // Firestore whereIn limit = 30 per query
      final chunks = <List<String>>[];
      for (var i = 0; i < ids.length; i += 30) {
        chunks.add(ids.sublist(i, i + 30 > ids.length ? ids.length : i + 30));
      }

      final results = <Food>[];
      for (final chunk in chunks) {
        final snapshot = await _db
            .collection('foods')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        results.addAll(snapshot.docs.map((d) => Food.fromFirestore(d)));
      }

      // เรียงตาม order ที่ user กด favorite
      results.sort((a, b) => ids.indexOf(a.id).compareTo(ids.indexOf(b.id)));
      return results;
    });
  }

  /// toggle — ถ้ามีอยู่แล้วให้ลบ, ถ้าไม่มีให้เพิ่ม
  Future<void> toggleFavorite(String uid, String foodId) async {
    final ref = _db.collection('users').doc(uid);
    final doc = await ref.get();

    List<String> current = [];
    if (doc.exists) {
      final data = doc.data()!;
      current = List<String>.from(data['favorites'] ?? []);
    }

    if (current.contains(foodId)) {
      current.remove(foodId);
    } else {
      current.add(foodId);
    }

    await ref.set({'favorites': current}, SetOptions(merge: true));
  }

  Future<bool> isFavorite(String uid, String foodId) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return false;
    final favs = List<String>.from(doc.data()?['favorites'] ?? []);
    return favs.contains(foodId);
  }
}
