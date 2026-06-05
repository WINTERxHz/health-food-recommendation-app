import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/exercise_log_model.dart';

class ExerciseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference _ref(String uid) =>
      _db.collection('users').doc(uid).collection('exerciseLog');

  /// Stream รายการ exercise ของวันที่กำหนด
  Stream<List<ExerciseLogEntry>> getLogsForDate(String uid, DateTime date) {
    final key =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    return _ref(uid)
        .where('dateKey', isEqualTo: key)
        .orderBy('loggedAt')
        .snapshots()
        .map((s) =>
            s.docs.map((d) => ExerciseLogEntry.fromFirestore(d)).toList());
  }

  /// เพิ่ม exercise log
  Future<void> addExercise({
    required String uid,
    required String name,
    required int durationMinutes,
    required int caloriesBurned,
    DateTime? loggedAt,
  }) async {
    final entry = ExerciseLogEntry(
      id: '',
      name: name,
      durationMinutes: durationMinutes,
      caloriesBurned: caloriesBurned,
      loggedAt: loggedAt ?? DateTime.now(),
    );
    await _ref(uid).add(entry.toMap());
  }

  /// ลบ exercise log
  Future<void> deleteExercise(String uid, String id) async {
    await _ref(uid).doc(id).delete();
  }

  /// รวม calories burned ย้อนหลัง 7 วัน → Map<dateKey, totalBurned>
  Future<Map<String, int>> getDailyBurnedLast7Days(String uid) async {
    final from = DateTime.now().subtract(const Duration(days: 6));
    final fromTs =
        Timestamp.fromDate(DateTime(from.year, from.month, from.day));
    final snap =
        await _ref(uid).where('loggedAt', isGreaterThanOrEqualTo: fromTs).get();
    final Map<String, int> result = {};
    for (final doc in snap.docs) {
      final entry = ExerciseLogEntry.fromFirestore(doc);
      result[entry.dateKey] =
          (result[entry.dateKey] ?? 0) + entry.caloriesBurned;
    }
    return result;
  }

  // ── Preset exercises พร้อม MET value ──────────────
  // calories = MET × weight(kg) × duration(hr)
  static int estimateCalories({
    required String exerciseName,
    required int durationMinutes,
    double weightKg = 65,
  }) {
    const met = {
      'Running': 9.8,
      'Walking': 3.5,
      'Cycling': 7.5,
      'Swimming': 8.0,
      'Jump Rope': 11.0,
      'Yoga': 2.5,
      'Weight Training': 5.0,
      'HIIT': 10.0,
    };
    final m = met[exerciseName] ?? 5.0;
    return (m * weightKg * (durationMinutes / 60)).round();
  }

  static const List<String> presetExercises = [
    'Running',
    'Walking',
    'Cycling',
    'Swimming',
    'Jump Rope',
    'Yoga',
    'Weight Training',
    'HIIT',
  ];
}
