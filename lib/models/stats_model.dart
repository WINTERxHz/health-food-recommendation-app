// lib/models/stats_model.dart
// ─────────────────────────────────────────────────────────
// Models สำหรับ Stats screen — แยก data structure ออกจาก UI
// ─────────────────────────────────────────────────────────

// ── Summary ของวันนี้ ─────────────────────────────────────
class DailySummary {
  final int calories;
  final int protein;
  final int fat;
  final int carbs;
  final int goal;

  const DailySummary({
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.goal,
  });

  double get progress => goal > 0 ? (calories / goal).clamp(0.0, 1.0) : 0.0;
  int get remaining => (goal - calories).clamp(0, goal);
  bool get isOver => calories > goal;

  static const empty = DailySummary(
    calories: 0,
    protein: 0,
    fat: 0,
    carbs: 0,
    goal: 0,
  );
}

// ── Macro ของวันใดวันหนึ่ง ─────────────────────────────────
class DayMacro {
  final String dateKey; // "2025-03-20"
  final String dayLabel; // "จ" "อ" "พ" …
  final int protein;
  final int fat;
  final int carbs;

  const DayMacro({
    required this.dateKey,
    required this.dayLabel,
    required this.protein,
    required this.fat,
    required this.carbs,
  });

  int get total => protein + fat + carbs;
}

// ── เมนูที่กินบ่อย ────────────────────────────────────────
class FrequentFood {
  final String name;
  final int count;
  final double ratio; // 0.0–1.0 เทียบกับ max

  const FrequentFood({
    required this.name,
    required this.count,
    required this.ratio,
  });
}

// ── ผลลัพธ์รวมทั้งหมดที่ StatsService คำนวณ ──────────────
class StatsResult {
  final DailySummary today;
  final List<DayMacro> macroTrend; // 7 วัน
  final List<FrequentFood> topFoods; // top 5

  const StatsResult({
    required this.today,
    required this.macroTrend,
    required this.topFoods,
  });
}
