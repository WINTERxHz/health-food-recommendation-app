import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/tdee_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/food_log_model.dart';
import '../models/food_model.dart';
import '../services/food_log_service.dart';
import '../services/food_service.dart';
import '../services/exercise_service.dart';

class FoodLogScreen extends StatefulWidget {
  const FoodLogScreen({super.key});

  @override
  State<FoodLogScreen> createState() => _FoodLogScreenState();
}

class _FoodLogScreenState extends State<FoodLogScreen> {
  static const _primaryGreen = Color(0xFF2E7D32);
  static const _lightGreen = Color(0xFFE8F5E9);

  final _logService = FoodLogService();
  final _foodService = FoodService();
  final _exerciseService = ExerciseService();

  DateTime _selectedDate = DateTime.now();
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // Stream user profile → real-time เมื่อ goal/diet เปลี่ยน
  Stream<UserModel?> get _userStream {
    if (_uid == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromMap(doc.data()!) : null);
  }

  static const _meals = ['Breakfast', 'Lunch', 'Dinner'];

  static const _mealIcons = {
    'Breakfast': Icons.wb_sunny_outlined,
    'Lunch': Icons.lunch_dining,
    'Dinner': Icons.nights_stay_outlined,
  };

  static const _mealColors = {
    'Breakfast': Color(0xFFFF8F00),
    'Lunch': Color(0xFF2E7D32),
    'Dinner': Color(0xFF1565C0),
  };

  @override
  void initState() {
    super.initState();
  }

  // ── Date helpers ────────────────────────────
  String get _dateLabel {
    final now = DateTime.now();
    final diff =
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day)
            .difference(DateTime(now.year, now.month, now.day))
            .inDays;
    if (diff == 0) return "Today";
    if (diff == -1) return "Yesterday";
    return "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}";
  }

  void _prevDay() => setState(
      () => _selectedDate = _selectedDate.subtract(const Duration(days: 1)));

  void _nextDay() {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    if (_selectedDate
        .isBefore(DateTime(tomorrow.year, tomorrow.month, tomorrow.day))) {
      setState(
          () => _selectedDate = _selectedDate.add(const Duration(days: 1)));
    }
  }

  // ── Add food bottom sheet ───────────────────
  void _showAddFoodSheet(String mealType, UserModel? userModel) {
    final dateForLog = _selectedDate;

    String searchText = '';
    String selectedMeal = mealType;

    // ── Pre-filter ตาม dietType + goal ──────────
    final defaultCategory =
        (userModel?.dietType != null && userModel!.dietType != 'Balanced')
            ? userModel.dietType
            : '';

    final defaultHealthy = userModel?.goal == 'Gain weight' ? false : true;

    String selectedCategory = defaultCategory;
    bool onlyHealthy = defaultHealthy;

    const categories = [
      {'label': 'ทั้งหมด', 'value': ''},
      {'label': 'Low Carb', 'value': 'Low Carb'},
      {'label': 'Balanced', 'value': 'Balanced'},
      {'label': 'High Protein', 'value': 'High Protein'},
      {'label': 'Vegetarian', 'value': 'Vegetarian'},
      {'label': 'Keto', 'value': 'Keto'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) {
        return StatefulBuilder(builder: (ctx, setModal) {
          return DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (_, scrollCtrl) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  children: [
                    // Handle
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2)),
                    ),

                    // ── Goal + Diet badge ────────────────
                    if (userModel != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: _primaryGreen.withOpacity(0.07),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: _primaryGreen.withOpacity(0.2)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.person_outline,
                                        size: 14, color: _primaryGreen),
                                    const SizedBox(width: 6),
                                    Text(
                                      'แสดงตาม: ${userModel!.goal} · ${userModel!.dietType}',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: _primaryGreen,
                                          fontWeight: FontWeight.w600),
                                    ),
                                    const Spacer(),
                                    // ปุ่ม reset กลับไป default
                                    GestureDetector(
                                      onTap: () => setModal(() {
                                        selectedCategory = defaultCategory;
                                        onlyHealthy = defaultHealthy;
                                        searchText = '';
                                      }),
                                      child: const Text(
                                        'Reset',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: _primaryGreen,
                                            decoration:
                                                TextDecoration.underline),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Meal selector
                    Row(
                      children: _meals.map((m) {
                        final selected = m == selectedMeal;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setModal(() => selectedMeal = m),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: selected
                                    ? _mealColors[m]
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    _mealIcons[m],
                                    size: 16,
                                    color: selected
                                        ? Colors.white
                                        : Colors.black45,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    m,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: selected
                                          ? Colors.white
                                          : Colors.black45,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 12),

                    // ── Search ──────────────────────────
                    TextField(
                      decoration: InputDecoration(
                        hintText: "Search food to add...",
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      ),
                      onChanged: (v) => setModal(() => searchText = v),
                    ),

                    const SizedBox(height: 8),

                    // ── Category filter chips ────────────
                    SizedBox(
                      height: 34,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: categories.map((cat) {
                          final selected = selectedCategory == cat['value'];
                          // ★ mark chip ที่ตรงกับ dietType ของ user
                          final isUserDiet = cat['value'] == defaultCategory &&
                              cat['value'] != '';
                          return GestureDetector(
                            onTap: () => setModal(
                                () => selectedCategory = cat['value']!),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: selected
                                    ? _primaryGreen
                                    : isUserDiet
                                        ? _primaryGreen.withOpacity(0.08)
                                        : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: selected
                                      ? _primaryGreen
                                      : isUserDiet
                                          ? _primaryGreen.withOpacity(0.4)
                                          : Colors.grey.shade300,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isUserDiet) ...[
                                    Icon(Icons.star,
                                        size: 10,
                                        color: selected
                                            ? Colors.white
                                            : _primaryGreen),
                                    const SizedBox(width: 3),
                                  ],
                                  Text(
                                    cat['label']!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: selected
                                          ? Colors.white
                                          : isUserDiet
                                              ? _primaryGreen
                                              : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 6),

                    // ── Healthy toggle + goal label ───────
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () =>
                              setModal(() => onlyHealthy = !onlyHealthy),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: onlyHealthy
                                  ? Colors.green.shade50
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: onlyHealthy
                                    ? _primaryGreen
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.eco,
                                    size: 14,
                                    color: onlyHealthy
                                        ? _primaryGreen
                                        : Colors.black38),
                                const SizedBox(width: 4),
                                Text(
                                  'Healthy only',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: onlyHealthy
                                        ? _primaryGreen
                                        : Colors.black54,
                                  ),
                                ),
                                // ★ บอก user ว่า on เพราะ goal
                                if (defaultHealthy && onlyHealthy) ...[
                                  const SizedBox(width: 4),
                                  Icon(Icons.star,
                                      size: 10,
                                      color: onlyHealthy
                                          ? _primaryGreen
                                          : Colors.black26),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // goal badge
                        if (userModel != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.flag_outlined,
                                    size: 13, color: Colors.blue.shade700),
                                const SizedBox(width: 4),
                                Text(
                                  userModel!.goal,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // ── Food list ────────────────────────
                    Expanded(
                      child: StreamBuilder<List<Food>>(
                        stream: _foodService.getFoods(),
                        builder: (_, snap) {
                          if (!snap.hasData) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          // filter เหมือน recommender
                          final foods = snap.data!.where((f) {
                            final matchSearch = f.name
                                .toLowerCase()
                                .contains(searchText.toLowerCase());
                            final matchCat = selectedCategory.isEmpty ||
                                f.category == selectedCategory;
                            final matchHealthy = !onlyHealthy || f.isHealthy;
                            return matchSearch && matchCat && matchHealthy;
                          }).toList();

                          if (foods.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('🌿', style: TextStyle(fontSize: 40)),
                                  const SizedBox(height: 8),
                                  Text(
                                    'ไม่พบเมนูที่ตรงกัน',
                                    style: TextStyle(
                                        color: Colors.black38, fontSize: 14),
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView.builder(
                            controller: scrollCtrl,
                            itemCount: foods.length,
                            itemBuilder: (_, i) {
                              final food = foods[i];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      _primaryGreen.withOpacity(0.1),
                                  child: Icon(
                                    food.isHealthy ? Icons.eco : Icons.fastfood,
                                    color: food.isHealthy
                                        ? _primaryGreen
                                        : Colors.orange,
                                    size: 18,
                                  ),
                                ),
                                title: Text(food.name,
                                    style: const TextStyle(fontSize: 14)),
                                subtitle: Text(
                                    "${food.calories} kcal  •  P:${food.protein}g  F:${food.fat}g  C:${food.carbs}g",
                                    style: const TextStyle(fontSize: 11)),
                                trailing: IconButton(
                                  icon: const Icon(Icons.add_circle,
                                      color: _primaryGreen),
                                  onPressed: () async {
                                    // ✅ FIX: ใช้ dateForLog แทน DateTime.now()
                                    // dateForLog = วันที่ user เลือกไว้ก่อนเปิด sheet
                                    await _logService.addLog(
                                      uid: _uid!,
                                      food: food,
                                      mealType: selectedMeal,
                                      loggedAt: dateForLog,
                                    );
                                    if (ctx.mounted) Navigator.pop(ctx);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                        content: Text(
                                            "${food.name} added to $selectedMeal"),
                                        backgroundColor: _primaryGreen,
                                        duration: const Duration(seconds: 2),
                                      ));
                                    }
                                  },
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // if (_uid == null) {
    //   return const Scaffold(body: Center(child: Text("Please login")));
    // }
    if (_uid == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: _lightGreen,
      appBar: AppBar(
        backgroundColor: _primaryGreen,
        title: const Text("Food Log"),
        centerTitle: false,
      ),
      body: StreamBuilder<UserModel?>(
        stream: _userStream,
        builder: (context, userSnap) {
          final userModel = userSnap.data;

          return StreamBuilder<List<FoodLogEntry>>(
            stream: _logService.getLogsForDate(_uid!, _selectedDate),
            builder: (context, snapshot) {
              final logs = snapshot.data ?? [];

              final totalCal = logs.fold(0, (s, e) => s + e.calories);
              final totalP = logs.fold(0, (s, e) => s + e.protein);
              final totalF = logs.fold(0, (s, e) => s + e.fat);
              final totalC = logs.fold(0, (s, e) => s + e.carbs);

              return Column(
                children: [
                  // ── Date navigator ────────────────
                  Container(
                    color: _primaryGreen,
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left,
                              color: Colors.white),
                          onPressed: _prevDay,
                        ),
                        Text(
                          _dateLabel,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right,
                              color: Colors.white),
                          onPressed: _nextDay,
                        ),
                      ],
                    ),
                  ),

                  // ── Daily Summary ─────────────────
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "$totalCal",
                              style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: _primaryGreen),
                            ),
                            const SizedBox(width: 6),
                            const Text("kcal today",
                                style: TextStyle(
                                    color: Colors.black45, fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _MacroSummary(
                                label: "Protein",
                                value: "${totalP}g",
                                color: Colors.blue),
                            _MacroSummary(
                                label: "Fat",
                                value: "${totalF}g",
                                color: Colors.amber.shade700),
                            _MacroSummary(
                                label: "Carbs",
                                value: "${totalC}g",
                                color: Colors.purple),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ── TDEE Progress Bar ─────────────
                  if (userModel != null) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: StreamBuilder<List>(
                        stream: _exerciseService.getLogsForDate(
                            _uid!, _selectedDate),
                        builder: (context, exSnap) {
                          final burnedCal = (exSnap.data ?? []).fold<int>(
                              0, (s, e) => s + (e.caloriesBurned as int));

                          final age =
                              TdeeService.calculateAge(userModel!.birthDate);
                          final dailyGoal = TdeeService.calculateDailyGoal(
                                userModel!.weight,
                                userModel!.height,
                                userModel!.goal,
                                age,
                                userModel!.gender,
                              ) +
                              burnedCal;
                          final percent = totalCal / dailyGoal;
                          final progressColor =
                              TdeeService.progressColor(percent);

                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2)),
                              ],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(children: [
                                      const Icon(Icons.local_fire_department,
                                          size: 16, color: Color(0xFF2E7D32)),
                                      const SizedBox(width: 4),
                                      Text(
                                        "เป้าหมายวันนี้",
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black54),
                                      ),
                                      // badge แสดง burned ถ้ามี
                                      if (burnedCal > 0) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.shade100,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '+$burnedCal 🏃',
                                            style: TextStyle(
                                                fontSize: 9,
                                                color: Colors.orange.shade800,
                                                fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ],
                                    ]),
                                    Text(
                                      "$totalCal / ${dailyGoal.toStringAsFixed(0)} kcal",
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: progressColor),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: percent.clamp(0.0, 1.0),
                                    backgroundColor: Colors.grey.shade200,
                                    color: progressColor,
                                    minHeight: 10,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      TdeeService.goalLabel(userModel!.goal),
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey.shade500),
                                    ),
                                    Text(
                                      percent > 1.0
                                          ? "เกินเป้า ${((percent - 1) * 100).toStringAsFixed(0)}%"
                                          : "เหลืออีก ${(dailyGoal - totalCal).toStringAsFixed(0)} kcal",
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: progressColor,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  // ── Meal Sections ─────────────────
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      children: _meals.map((meal) {
                        final mealLogs =
                            logs.where((l) => l.mealType == meal).toList();
                        final mealCal =
                            mealLogs.fold(0, (s, e) => s + e.calories);

                        return _MealSection(
                          meal: meal,
                          icon: _mealIcons[meal]!,
                          color: _mealColors[meal]!,
                          logs: mealLogs,
                          totalCalories: mealCal,
                          onAdd: () => _showAddFoodSheet(meal, userModel),
                          onDelete: (logId) =>
                              _logService.deleteLog(_uid!, logId),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Macro Summary Badge
// ─────────────────────────────────────────────────────────
class _MacroSummary extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MacroSummary(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.black45)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// Meal Section Card
// ─────────────────────────────────────────────────────────
class _MealSection extends StatelessWidget {
  final String meal;
  final IconData icon;
  final Color color;
  final List<FoodLogEntry> logs;
  final int totalCalories;
  final VoidCallback onAdd;
  final Function(String) onDelete;

  const _MealSection({
    required this.meal,
    required this.icon,
    required this.color,
    required this.logs,
    required this.totalCalories,
    required this.onAdd,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(meal,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                if (totalCalories > 0)
                  Text("$totalCalories kcal",
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.add_circle_outline, color: color),
                  onPressed: onAdd,
                  tooltip: "Add food",
                ),
              ],
            ),
          ),

          // Food entries
          if (logs.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Text("No food logged yet",
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
            )
          else
            ...logs.map((log) => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 8, 10),
                  child: Row(
                    children: [
                      Expanded(
                          child: Text(log.foodName,
                              style: const TextStyle(fontSize: 14))),
                      Text("${log.calories} kcal",
                          style: const TextStyle(
                              color: Colors.deepOrange,
                              fontSize: 13,
                              fontWeight: FontWeight.w500)),
                      IconButton(
                        icon: const Icon(Icons.close,
                            size: 16, color: Colors.black38),
                        onPressed: () => onDelete(log.id),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }
}
