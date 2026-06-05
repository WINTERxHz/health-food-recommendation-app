import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/food_model.dart';
import '../models/user_model.dart';
import '../models/stats_model.dart';
import '../services/food_service.dart';
import '../services/food_log_service.dart';
import '../services/stats_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  static const _primaryGreen = Color(0xFF2E7D32);
  static const _lightGreen = Color(0xFFE8F5E9);

  static const _categoryColors = [
    Color(0xFF2E7D32),
    Color(0xFF1565C0),
    Color(0xFFE65100),
    Color(0xFF6A1B9A),
    Color(0xFF00838F),
  ];

  final _foodService = FoodService();
  final _logService = FoodLogService();
  final _statsService = StatsService();

  Map<String, int> _weeklyCalories = {};

  @override
  void initState() {
    super.initState();
    _loadWeeklyCalories();
  }

  Future<void> _loadWeeklyCalories() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final weekly = await _logService.getDailyCaloriesLast7Days(uid);
    if (!mounted) return;
    setState(() => _weeklyCalories = weekly);
  }

  Stream<UserModel?> get _userStream {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromMap(doc.data()!) : null);
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: _lightGreen,
      appBar: AppBar(
        backgroundColor: _primaryGreen,
        title: const Text("Stats"),
        centerTitle: false,
      ),
      body: StreamBuilder<UserModel?>(
        stream: _userStream,
        builder: (context, userSnap) {
          final userModel = userSnap.data;

          return StreamBuilder<List<Food>>(
            stream: _foodService.getFoods(),
            builder: (context, foodSnap) {
              if (!foodSnap.hasData) {
                return const Center(
                    child: CircularProgressIndicator(color: _primaryGreen));
              }
              final foods = foodSnap.data!;

              // StatsService รวม stream เดียว — widget รับ StatsResult ไปแสดงผล
              return StreamBuilder<StatsResult>(
                stream: (uid != null && userModel != null)
                    ? _statsService.watchStats(uid, userModel)
                    : null,
                builder: (context, statsSnap) {
                  final stats = statsSnap.data;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── 1. Weekly Calorie Chart ───────────
                        _sectionTitle("📅 แคลอรี่รายสัปดาห์"),
                        const SizedBox(height: 10),
                        _WeeklyCalorieChart(weeklyCalories: _weeklyCalories),
                        const SizedBox(height: 24),

                        // ── 2. Macro Trend 7 วัน ──────────────
                        if (stats != null) ...[
                          _sectionTitle("📈 Macro 7 วัน"),
                          const SizedBox(height: 10),
                          _MacroTrendCard(trend: stats.macroTrend),
                          const SizedBox(height: 24),

                          // ── 3. Most Eaten Foods ───────────────
                          _sectionTitle("🍽️ กินบ่อยที่สุด"),
                          const SizedBox(height: 10),
                          _MostEatenCard(foods: stats.topFoods),
                          const SizedBox(height: 24),
                        ],

                        // ── 4. BMI ────────────────────────────
                        if (userModel != null) ...[
                          _sectionTitle("🩺 สุขภาพของคุณ"),
                          const SizedBox(height: 10),
                          _BMICard(user: userModel),
                          const SizedBox(height: 24),
                        ],

                        // ── 5. Food Database ──────────────────
                        _sectionTitle("🗄️ ฐานข้อมูลอาหาร"),
                        const SizedBox(height: 10),
                        _OverviewRow(foods: foods),
                        const SizedBox(height: 16),
                        _ChartCard(
                          title: "Healthy vs Unhealthy",
                          child: _HealthyPieChart(foods: foods),
                        ),
                        const SizedBox(height: 16),
                        _ChartCard(
                          title: "Foods by Category",
                          child: _CategoryBarChart(
                              foods: foods, colors: _categoryColors),
                        ),
                        const SizedBox(height: 24),

                        // ── 6. Top Foods ──────────────────────
                        _sectionTitle("🏆 Top Foods"),
                        const SizedBox(height: 10),
                        _TopFoodList(
                          title: "🔥 Lowest Calories",
                          foods: [...foods]
                            ..sort((a, b) => a.calories.compareTo(b.calories)),
                          subtitle: (f) => "${f.calories} kcal",
                          color: Colors.deepOrange,
                        ),
                        const SizedBox(height: 12),
                        _TopFoodList(
                          title: "💪 Highest Protein",
                          foods: [...foods]
                            ..sort((a, b) => b.protein.compareTo(a.protein)),
                          subtitle: (f) => "${f.protein}g",
                          color: Colors.blue,
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(
        title,
        style: const TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold, color: _primaryGreen),
      );
}

// ─────────────────────────────────────────────────────────
// 🎯 Daily Goal Progress Ring
// ─────────────────────────────────────────────────────────
class _DailyGoalRing extends StatelessWidget {
  final DailySummary summary;
  const _DailyGoalRing({required this.summary});

  static const _green = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            SizedBox(
              width: 110,
              height: 110,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 110,
                    height: 110,
                    child: CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: 10,
                      color: Colors.grey.shade200,
                    ),
                  ),
                  SizedBox(
                    width: 110,
                    height: 110,
                    child: CircularProgressIndicator(
                      value: summary.progress,
                      strokeWidth: 10,
                      strokeCap: StrokeCap.round,
                      color: summary.isOver ? Colors.deepOrange : _green,
                    ),
                  ),
                  Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(
                      '${summary.calories}',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: summary.isOver ? Colors.deepOrange : _green,
                      ),
                    ),
                    Text('kcal',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500)),
                  ]),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RingInfoRow(
                      label: 'เป้าหมาย',
                      value: '${summary.goal} kcal',
                      color: Colors.grey.shade700),
                  const SizedBox(height: 4),
                  _RingInfoRow(
                      label: summary.isOver ? 'เกินมา' : 'เหลืออีก',
                      value: '${summary.remaining} kcal',
                      color: summary.isOver ? Colors.deepOrange : _green,
                      bold: true),
                  const Divider(height: 16),
                  _RingInfoRow(
                      label: 'Protein',
                      value: '${summary.protein}g',
                      color: Colors.blue),
                  const SizedBox(height: 2),
                  _RingInfoRow(
                      label: 'Carbs',
                      value: '${summary.carbs}g',
                      color: Colors.purple),
                  const SizedBox(height: 2),
                  _RingInfoRow(
                      label: 'Fat',
                      value: '${summary.fat}g',
                      color: Colors.amber.shade700),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool bold;

  const _RingInfoRow({
    required this.label,
    required this.value,
    required this.color,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: bold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// 📈 Macro Trend 7 วัน
// ─────────────────────────────────────────────────────────
class _MacroTrendCard extends StatelessWidget {
  final List<DayMacro> trend;
  const _MacroTrendCard({required this.trend});

  @override
  Widget build(BuildContext context) {
    final maxVal = trend.fold(0, (m, d) {
      final v = [d.protein, d.fat, d.carbs].reduce((a, b) => a > b ? a : b);
      return v > m ? v : m;
    });

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              _MacroLegend('P', Colors.blue),
              const SizedBox(width: 12),
              _MacroLegend('C', Colors.purple),
              const SizedBox(width: 12),
              _MacroLegend('F', Colors.amber.shade700),
            ]),
            const SizedBox(height: 16),
            if (maxVal == 0)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text('ยังไม่มีข้อมูลสัปดาห์นี้',
                      style: TextStyle(color: Colors.grey.shade400)),
                ),
              )
            else
              SizedBox(
                height: 120,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: trend
                      .map((day) => Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _MacroBar(
                                        value: day.protein,
                                        max: maxVal,
                                        color: Colors.blue,
                                        maxHeight: 80),
                                    const SizedBox(width: 2),
                                    _MacroBar(
                                        value: day.carbs,
                                        max: maxVal,
                                        color: Colors.purple,
                                        maxHeight: 80),
                                    const SizedBox(width: 2),
                                    _MacroBar(
                                        value: day.fat,
                                        max: maxVal,
                                        color: Colors.amber.shade700,
                                        maxHeight: 80),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(day.dayLabel,
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade500)),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MacroLegend extends StatelessWidget {
  final String label;
  final Color color;
  const _MacroLegend(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }
}

class _MacroBar extends StatelessWidget {
  final int value;
  final int max;
  final Color color;
  final double maxHeight;
  const _MacroBar(
      {required this.value,
      required this.max,
      required this.color,
      required this.maxHeight});

  @override
  Widget build(BuildContext context) {
    final h = max == 0 ? 2.0 : (value / max * maxHeight).clamp(2.0, maxHeight);
    return Container(
      width: 7,
      height: h,
      decoration: BoxDecoration(
        color: value == 0 ? Colors.grey.shade200 : color,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// 🍽️ Most Eaten Foods (7 วัน)
// ─────────────────────────────────────────────────────────
class _MostEatenCard extends StatelessWidget {
  final List<FrequentFood> foods;
  const _MostEatenCard({required this.foods});

  static const _green = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: foods.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text('ยังไม่มีข้อมูลสัปดาห์นี้',
                      style: TextStyle(color: Colors.grey.shade400)),
                ),
              )
            : Column(
                children: foods.asMap().entries.map((entry) {
                  final rank = entry.key + 1;
                  final food = entry.value;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(children: [
                      SizedBox(
                        width: 22,
                        child: Text('$rank',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: rank == 1
                                  ? Colors.amber.shade700
                                  : Colors.grey.shade400,
                            )),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(food.name,
                                style: const TextStyle(fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 3),
                            FractionallySizedBox(
                              widthFactor: food.ratio,
                              child: Container(
                                height: 4,
                                decoration: BoxDecoration(
                                  color: _green.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _green.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('${food.count} ครั้ง',
                            style: TextStyle(
                                fontSize: 11,
                                color: _green,
                                fontWeight: FontWeight.w600)),
                      ),
                    ]),
                  );
                }).toList(),
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Weekly Calorie Bar Chart (from Food Log)
// ─────────────────────────────────────────────────────────
class _WeeklyCalorieChart extends StatelessWidget {
  final Map<String, int> weeklyCalories;
  const _WeeklyCalorieChart({required this.weeklyCalories});

  static const _primaryGreen = Color(0xFF2E7D32);

  List<String> get _last7Days {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
    });
  }

  String _shortLabel(String dateKey) {
    final parts = dateKey.split('-');
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final d =
        DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    return days[d.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final days = _last7Days;
    final maxVal = days
        .map((k) => weeklyCalories[k] ?? 0)
        .fold(0, (a, b) => a > b ? a : b);
    final maxY =
        ((maxVal + 200).toDouble()).clamp(500.0, double.infinity).toDouble();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (weeklyCalories.isEmpty)
              const SizedBox(
                height: 120,
                child: Center(
                  child: Text("No food logged this week",
                      style: TextStyle(color: Colors.black38)),
                ),
              )
            else
              SizedBox(
                height: 180,
                child: BarChart(
                  BarChartData(
                    maxY: maxY,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (_) =>
                          FlLine(color: Colors.black12, strokeWidth: 1),
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 36,
                          getTitlesWidget: (v, _) => Text(
                            v.toInt().toString(),
                            style: const TextStyle(
                                fontSize: 9, color: Colors.black45),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (v, _) {
                            final i = v.toInt();
                            if (i < 0 || i >= days.length) {
                              return const SizedBox();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                _shortLabel(days[i]),
                                style: const TextStyle(
                                    fontSize: 10, color: Colors.black54),
                              ),
                            );
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                    ),
                    barGroups: List.generate(days.length, (i) {
                      final cal = (weeklyCalories[days[i]] ?? 0).toDouble();
                      return BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: cal,
                            color:
                                cal > 0 ? _primaryGreen : Colors.grey.shade200,
                            width: 28,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6)),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// (ส่วนที่เหลือเหมือนเดิม — copy มาจาก stats_screen เดิม)
// ─────────────────────────────────────────────────────────
class _BMICard extends StatelessWidget {
  final UserModel user;
  const _BMICard({required this.user});

  Color get _color {
    if (user.bmi < 18.5) return Colors.blue;
    if (user.bmi < 25) return const Color(0xFF2E7D32);
    if (user.bmi < 30) return Colors.orange;
    return Colors.red;
  }

  String get _label {
    if (user.bmi < 18.5) return "Underweight";
    if (user.bmi < 25) return "Normal";
    if (user.bmi < 30) return "Overweight";
    return "Obese";
  }

  double get _progress => ((user.bmi - 15) / 20).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final barWidth = MediaQuery.of(context).size.width - 80;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(user.bmi.toStringAsFixed(1),
                      style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: _color)),
                  Text("BMI  •  $_label",
                      style: TextStyle(color: _color, fontSize: 14)),
                ]),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text("${user.weight.toStringAsFixed(1)} kg",
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text("${user.height.toStringAsFixed(0)} cm",
                      style: const TextStyle(color: Colors.black45)),
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(user.goal,
                        style: const TextStyle(
                            color: Color(0xFF2E7D32),
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                ]),
              ],
            ),
            const SizedBox(height: 16),
            Stack(children: [
              Container(
                height: 10,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: const LinearGradient(colors: [
                    Colors.blue,
                    Color(0xFF2E7D32),
                    Colors.orange,
                    Colors.red,
                  ]),
                ),
              ),
              Positioned(
                left: (_progress * barWidth).clamp(0.0, barWidth),
                child: Container(
                  width: 14,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: _color, width: 2.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text("15",
                    style: TextStyle(fontSize: 10, color: Colors.black38)),
                Text("18.5",
                    style: TextStyle(fontSize: 10, color: Colors.black38)),
                Text("25",
                    style: TextStyle(fontSize: 10, color: Colors.black38)),
                Text("30",
                    style: TextStyle(fontSize: 10, color: Colors.black38)),
                Text("35",
                    style: TextStyle(fontSize: 10, color: Colors.black38)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewRow extends StatelessWidget {
  final List<Food> foods;
  const _OverviewRow({required this.foods});

  @override
  Widget build(BuildContext context) {
    final healthy = foods.where((f) => f.isHealthy).length;
    return Row(children: [
      _StatTile(
          label: "Total",
          value: "${foods.length}",
          icon: Icons.restaurant_menu,
          color: const Color(0xFF2E7D32)),
      const SizedBox(width: 10),
      _StatTile(
          label: "Healthy",
          value: "$healthy",
          icon: Icons.eco,
          color: Colors.green),
      const SizedBox(width: 10),
      _StatTile(
          label: "Unhealthy",
          value: "${foods.length - healthy}",
          icon: Icons.warning_amber,
          color: Colors.orange),
    ]);
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatTile(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(fontSize: 11, color: Colors.black45)),
          ]),
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _ChartCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          child,
        ]),
      ),
    );
  }
}

class _HealthyPieChart extends StatefulWidget {
  final List<Food> foods;
  const _HealthyPieChart({required this.foods});

  @override
  State<_HealthyPieChart> createState() => _HealthyPieChartState();
}

class _HealthyPieChartState extends State<_HealthyPieChart> {
  int _touched = -1;

  @override
  Widget build(BuildContext context) {
    final healthy = widget.foods.where((f) => f.isHealthy).length;
    final unhealthy = widget.foods.length - healthy;
    final total = widget.foods.length;
    if (total == 0) return const SizedBox(height: 160);

    return SizedBox(
      height: 180,
      child: Row(children: [
        Expanded(
          child: PieChart(PieChartData(
            sectionsSpace: 3,
            centerSpaceRadius: 38,
            pieTouchData: PieTouchData(
              touchCallback: (evt, res) {
                setState(() {
                  _touched = (evt.isInterestedForInteractions &&
                          res?.touchedSection != null)
                      ? res!.touchedSection!.touchedSectionIndex
                      : -1;
                });
              },
            ),
            sections: [
              PieChartSectionData(
                value: healthy.toDouble(),
                color: const Color(0xFF2E7D32),
                title: _touched == 0
                    ? "$healthy\nHealthy"
                    : "${(healthy / total * 100).toStringAsFixed(0)}%",
                radius: _touched == 0 ? 66 : 56,
                titleStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
              PieChartSectionData(
                value: unhealthy.toDouble(),
                color: Colors.orange,
                title: _touched == 1
                    ? "$unhealthy\nUnhealthy"
                    : "${(unhealthy / total * 100).toStringAsFixed(0)}%",
                radius: _touched == 1 ? 66 : 56,
                titleStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
            ],
          )),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Dot(color: const Color(0xFF2E7D32), label: "Healthy ($healthy)"),
            const SizedBox(height: 10),
            _Dot(color: Colors.orange, label: "Unhealthy ($unhealthy)"),
          ],
        ),
      ]),
    );
  }
}

class _CategoryBarChart extends StatelessWidget {
  final List<Food> foods;
  final List<Color> colors;
  const _CategoryBarChart({required this.foods, required this.colors});

  @override
  Widget build(BuildContext context) {
    final Map<String, int> counts = {};
    for (final f in foods) {
      counts[f.category] = (counts[f.category] ?? 0) + 1;
    }
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (entries.isEmpty) return const SizedBox(height: 160);
    final maxY = (entries.first.value + 2).toDouble();

    return Column(children: [
      SizedBox(
        height: 180,
        child: BarChart(BarChartData(
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: Colors.black12, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (v, _) => Text(v.toInt().toString(),
                    style:
                        const TextStyle(fontSize: 10, color: Colors.black45)),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= entries.length) return const SizedBox();
                  final name = entries[i].key;
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(name.length > 7 ? name.substring(0, 7) : name,
                        style: const TextStyle(
                            fontSize: 9, color: Colors.black54)),
                  );
                },
              ),
            ),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          barGroups: List.generate(entries.length, (i) {
            final color = colors[i % colors.length];
            return BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: entries[i].value.toDouble(),
                color: color,
                width: 22,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(6)),
              ),
            ]);
          }),
        )),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 12,
        runSpacing: 6,
        children: List.generate(
          entries.length,
          (i) => _Dot(
              color: colors[i % colors.length],
              label: "${entries[i].key} (${entries[i].value})"),
        ),
      ),
    ]);
  }
}

class _TopFoodList extends StatelessWidget {
  final String title;
  final List<Food> foods;
  final String Function(Food) subtitle;
  final Color color;
  const _TopFoodList(
      {required this.title,
      required this.foods,
      required this.subtitle,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final top = foods.take(5).toList();
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...top.asMap().entries.map((e) {
            final rank = e.key + 1;
            final food = e.value;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.12), shape: BoxShape.circle),
                  child: Text("$rank",
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ),
                const SizedBox(width: 12),
                Expanded(
                    child:
                        Text(food.name, style: const TextStyle(fontSize: 14))),
                Text(subtitle(food),
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ]),
            );
          }),
        ]),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  final String label;
  const _Dot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(fontSize: 13)),
    ]);
  }
}
