import 'package:cloud_firestore/cloud_firestore.dart';

class ExerciseLogEntry {
  final String id;
  final String name; // เช่น "Running", "Cycling"
  final int durationMinutes;
  final int caloriesBurned;
  final DateTime loggedAt;

  ExerciseLogEntry({
    required this.id,
    required this.name,
    required this.durationMinutes,
    required this.caloriesBurned,
    required this.loggedAt,
  });

  factory ExerciseLogEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ExerciseLogEntry(
      id: doc.id,
      name: data['name'] ?? '',
      durationMinutes: data['durationMinutes'] ?? 0,
      caloriesBurned: data['caloriesBurned'] ?? 0,
      loggedAt: (data['loggedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'durationMinutes': durationMinutes,
        'caloriesBurned': caloriesBurned,
        'loggedAt': Timestamp.fromDate(loggedAt),
        'dateKey': _dateKey(loggedAt),
      };

  static String _dateKey(DateTime dt) =>
      "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";

  String get dateKey => _dateKey(loggedAt);
}
