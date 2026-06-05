import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/water_log_model.dart';

class WaterService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference _ref(String uid) =>
      _db.collection('users').doc(uid).collection('waterLog');

  // FIX: helper สร้าง dateKey แบบเดียวกันทุกที่
  static String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  /// Stream รายการ water log ของวันที่กำหนด
  Stream<List<WaterLogEntry>> getLogsForDate(String uid, DateTime date) {
    final key = _dateKey(date);
    return _ref(uid)
        .where('dateKey', isEqualTo: key)
        .orderBy('loggedAt')
        .snapshots()
        .map((s) => s.docs.map((d) => WaterLogEntry.fromFirestore(d)).toList());
  }

  /// รวม ml ของวันนี้
  Stream<int> getTotalForDate(String uid, DateTime date) {
    return getLogsForDate(uid, date)
        .map((logs) => logs.fold(0, (sum, e) => sum + e.amount));
  }

  /// เพิ่ม water log — FIX: ใส่ dateKey ให้ถูกต้องทุกครั้ง
  Future<void> addWater(String uid, int amount) async {
    final now = DateTime.now();
    await _ref(uid).add({
      'amount': amount,
      'loggedAt': Timestamp.fromDate(now),
      'dateKey': _dateKey(now), // FIX: ต้องมี field นี้ถึง query ได้
    });
  }

  /// ลบ water log
  Future<void> deleteWater(String uid, String id) async {
    await _ref(uid).doc(id).delete();
  }

  /// รวม ml ย้อนหลัง 7 วัน → Map<dateKey, totalMl>
  Future<Map<String, int>> getDailyWaterLast7Days(String uid) async {
    final from = DateTime.now().subtract(const Duration(days: 6));
    final fromTs =
        Timestamp.fromDate(DateTime(from.year, from.month, from.day));
    final snap =
        await _ref(uid).where('loggedAt', isGreaterThanOrEqualTo: fromTs).get();
    final Map<String, int> result = {};
    for (final doc in snap.docs) {
      final entry = WaterLogEntry.fromFirestore(doc);
      result[entry.dateKey] = (result[entry.dateKey] ?? 0) + entry.amount;
    }
    return result;
  }
}
