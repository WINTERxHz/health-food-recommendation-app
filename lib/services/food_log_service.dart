import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/food_log_model.dart';
import '../models/food_model.dart';

class FoodLogService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // path: users/{uid}/foodLog/{docId}
  CollectionReference _ref(String uid) =>
      _db.collection('users').doc(uid).collection('foodLog');

  /// Stream รายการ log ของวันที่กำหนด
  Stream<List<FoodLogEntry>> getLogsForDate(String uid, DateTime date) {
    final key =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    return _ref(uid)
        .where('dateKey', isEqualTo: key)
        .snapshots()
        .map((s) => s.docs.map((d) => FoodLogEntry.fromFirestore(d)).toList());
  }

  /// Stream log ย้อนหลัง 7 วัน สำหรับกราฟ
  Stream<List<FoodLogEntry>> getLogsLast7Days(String uid) {
    final from = DateTime.now().subtract(const Duration(days: 6));
    final fromTs =
        Timestamp.fromDate(DateTime(from.year, from.month, from.day));
    return _ref(uid)
        .where('loggedAt', isGreaterThanOrEqualTo: fromTs)
        .orderBy('loggedAt')
        .snapshots()
        .map((s) => s.docs.map((d) => FoodLogEntry.fromFirestore(d)).toList());
  }

  /// เพิ่ม log
  Future<void> addLog({
    required String uid,
    required Food food,
    required String mealType,
    DateTime? loggedAt,
  }) async {
    final entry = FoodLogEntry(
      id: '',
      foodId: food.id,
      foodName: food.name,
      calories: food.calories,
      protein: food.protein,
      fat: food.fat,
      carbs: food.carbs,
      mealType: mealType,
      loggedAt: loggedAt ?? DateTime.now(),
    );
    await _ref(uid).add(entry.toMap());
  }

  /// ลบ log
  Future<void> deleteLog(String uid, String logId) async {
    await _ref(uid).doc(logId).delete();
  }

  /// สรุป calories รายวันย้อนหลัง 7 วัน → Map<dateKey, totalCalories>
  Future<Map<String, int>> getDailyCaloriesLast7Days(String uid) async {
    final logs = await getLogsLast7Days(uid).first;
    final Map<String, int> result = {};
    for (final log in logs) {
      result[log.dateKey] = (result[log.dateKey] ?? 0) + log.calories;
    }
    return result;
  }
}
