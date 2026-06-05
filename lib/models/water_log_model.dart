import 'package:cloud_firestore/cloud_firestore.dart';

class WaterLogEntry {
  final String id;
  final int amount; // ml
  final DateTime loggedAt;

  WaterLogEntry({
    required this.id,
    required this.amount,
    required this.loggedAt,
  });

  factory WaterLogEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WaterLogEntry(
      id: doc.id,
      amount: data['amount'] ?? 0,
      loggedAt: (data['loggedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'amount': amount,
        'loggedAt': Timestamp.fromDate(loggedAt),
        'dateKey': _dateKey(loggedAt),
      };

  static String _dateKey(DateTime dt) =>
      "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";

  String get dateKey => _dateKey(loggedAt);
}
