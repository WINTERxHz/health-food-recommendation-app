// lib/services/stats_service.dart
// ─────────────────────────────────────────────────────────
// Business logic ทั้งหมดของ Stats screen
// Widget ไม่ต้องคำนวณอะไรเอง — รับ StatsResult ไปแสดงผลอย่างเดียว
// ─────────────────────────────────────────────────────────

import '../models/food_log_model.dart';
import '../models/stats_model.dart';
import '../models/user_model.dart';
import 'food_log_service.dart';
import 'tdee_service.dart';

class StatsService {
  final FoodLogService _logService;

  StatsService({FoodLogService? logService})
      : _logService = logService ?? FoodLogService();

  // ── Stream หลัก → emit StatsResult ทุกครั้งที่ log เปลี่ยน ──
  Stream<StatsResult> watchStats(String uid, UserModel user) {
    final age = TdeeService.calculateAge(user.birthDate);
    final goal = TdeeService.calculateDailyGoal(
      user.weight,
      user.height,
      user.goal,
      age,
      user.gender,
    ).round();

    // รวม 2 streams: วันนี้ + 7 วัน
    return _logService.getLogsLast7Days(uid).map((logs7) {
      final today = _buildToday(logs7, goal);
      final trend = _buildMacroTrend(logs7);
      final top = _buildTopFoods(logs7);
      return StatsResult(today: today, macroTrend: trend, topFoods: top);
    });
  }

  // ── คำนวณ summary วันนี้ ──────────────────────────────────
  DailySummary _buildToday(List<FoodLogEntry> logs7, int goal) {
    final todayKey = _dateKey(DateTime.now());
    final todayLogs = logs7.where((l) => l.dateKey == todayKey).toList();

    return DailySummary(
      calories: todayLogs.fold(0, (s, e) => s + e.calories),
      protein: todayLogs.fold(0, (s, e) => s + e.protein),
      fat: todayLogs.fold(0, (s, e) => s + e.fat),
      carbs: todayLogs.fold(0, (s, e) => s + e.carbs),
      goal: goal,
    );
  }

  // ── Macro trend 7 วันย้อนหลัง ────────────────────────────
  List<DayMacro> _buildMacroTrend(List<FoodLogEntry> logs7) {
    // group by dateKey
    final Map<String, List<FoodLogEntry>> byDay = {};
    for (final log in logs7) {
      byDay.putIfAbsent(log.dateKey, () => []).add(log);
    }

    return List.generate(7, (i) {
      final date = DateTime.now().subtract(Duration(days: 6 - i));
      final key = _dateKey(date);
      final dayLogs = byDay[key] ?? [];

      return DayMacro(
        dateKey: key,
        dayLabel: _thaiDayLabel(date.weekday),
        protein: dayLogs.fold(0, (s, e) => s + e.protein),
        fat: dayLogs.fold(0, (s, e) => s + e.fat),
        carbs: dayLogs.fold(0, (s, e) => s + e.carbs),
      );
    });
  }

  // ── Top 5 เมนูที่กินบ่อย ──────────────────────────────────
  List<FrequentFood> _buildTopFoods(List<FoodLogEntry> logs7, {int limit = 5}) {
    final Map<String, int> freq = {};
    for (final log in logs7) {
      freq[log.foodName] = (freq[log.foodName] ?? 0) + 1;
    }

    final sorted = freq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final top = sorted.take(limit).toList();
    final maxCount = top.isEmpty ? 1 : top.first.value;

    return top
        .map((e) => FrequentFood(
              name: e.key,
              count: e.value,
              ratio: e.value / maxCount,
            ))
        .toList();
  }

  // ── Helpers ───────────────────────────────────────────────
  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _thaiDayLabel(int weekday) {
    const labels = {1: 'จ', 2: 'อ', 3: 'พ', 4: 'พฤ', 5: 'ศ', 6: 'ส', 7: 'อา'};
    return labels[weekday] ?? '';
  }
}
