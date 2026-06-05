import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/food_model.dart';
import '../models/user_model.dart';
import '../models/food_log_model.dart';
import '../services/food_service.dart';
import '../services/food_log_service.dart';
import '../services/exercise_service.dart';
import '../services/tdee_service.dart';
import 'food_detail_screen.dart';

class ForYouScreen extends StatelessWidget {
  const ForYouScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Please login')));
    }

    // Stream user profile — real-time
    final userStream = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromMap(doc.data()!) : null);

    return StreamBuilder<UserModel?>(
      stream: userStream,
      builder: (context, userSnap) {
        final user = userSnap.data;

        return StreamBuilder<List<Food>>(
          stream: FoodService().getFoods(),
          builder: (context, foodSnap) {
            final foods = foodSnap.data ?? [];

            return Scaffold(
              backgroundColor: const Color(0xFFE8F5E9),
              body: CustomScrollView(
                slivers: [
                  // ── AppBar ─────────────────────────
                  SliverAppBar(
                    expandedHeight: 120,
                    pinned: true,
                    backgroundColor: const Color(0xFF2E7D32),
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '🍽️ For You',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user != null
                                      ? 'แนะนำตาม ${user.goal} · ${user.dietType}'
                                      : 'เมนูที่เหมาะกับคุณวันนี้',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── Content ────────────────────────
                  if (user == null || foods.isEmpty)
                    const SliverFillRemaining(
                      child: Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFF2E7D32))),
                    )
                  else
                    SliverToBoxAdapter(
                      child: _ForYouContent(
                        uid: uid,
                        user: user,
                        foods: foods,
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────
// Content — ดึง context วันนี้แล้ว render sections
// ─────────────────────────────────────────────────────────
class _ForYouContent extends StatefulWidget {
  final String uid;
  final UserModel user;
  final List<Food> foods;

  const _ForYouContent({
    required this.uid,
    required this.user,
    required this.foods,
  });

  @override
  State<_ForYouContent> createState() => _ForYouContentState();
}

class _ForYouContentState extends State<_ForYouContent> {
  static const _green = Color(0xFF2E7D32);

  final _logService = FoodLogService();
  final _exerciseService = ExerciseService();

  bool _loading = true;
  int _calToday = 0;
  int _burnedToday = 0;
  List<String> _eatenFoodIds = [];

  late List<Food> _topPicks;
  late List<Food> _lowCalPicks;
  late List<Food> _highProtein;
  late List<Food> _healthyPicks;

  // Stream subscriptions — real-time
  final _today = DateTime.now();
  StreamSubscription? _logSub;
  StreamSubscription? _exSub;

  // เก็บค่าล่าสุดของแต่ละ stream แยกกัน
  int _calFromLog = 0;
  int _calFromEx = 0;
  List<String> _idsFromLog = [];

  @override
  void initState() {
    super.initState();
    _topPicks = _lowCalPicks = _highProtein = _healthyPicks = [];

    // listen food log stream
    _logSub = _logService.getLogsForDate(widget.uid, _today).listen((logs) {
      if (!mounted) return;
      setState(() {
        _calFromLog = logs.fold(0, (s, e) => s + e.calories);
        _idsFromLog = logs.map((l) => l.foodId).toSet().toList();
        _calToday = _calFromLog;
        _eatenFoodIds = _idsFromLog;
        _loading = false;
        _buildSections();
      });
    });

    // listen exercise stream
    _exSub =
        _exerciseService.getLogsForDate(widget.uid, _today).listen((exLogs) {
      if (!mounted) return;
      setState(() {
        _calFromEx = exLogs.fold(0, (s, e) => s + e.caloriesBurned);
        _burnedToday = _calFromEx;
        _buildSections();
      });
    });
  }

  @override
  void dispose() {
    _logSub?.cancel();
    _exSub?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(_ForYouContent old) {
    super.didUpdateWidget(old);
    if (old.foods != widget.foods || old.user != widget.user) {
      setState(() => _buildSections());
    }
  }

  // ── cal ที่เหลือ ─────────────────────────────────────────
  int get _calRemaining {
    final age = TdeeService.calculateAge(widget.user.birthDate);
    final goal = TdeeService.calculateDailyGoal(
      widget.user.weight,
      widget.user.height,
      widget.user.goal,
      age,
      widget.user.gender,
    ).round();
    return (goal + _burnedToday - _calToday).clamp(0, 99999);
  }

  // ── สร้าง pool พื้นฐาน (ไม่ซ้ำที่กินไปแล้ว) ────────────
  List<Food> get _pool {
    var pool =
        widget.foods.where((f) => !_eatenFoodIds.contains(f.id)).toList();
    // กรอง diet
    if (widget.user.dietType != 'Balanced') {
      final byDiet =
          // กฎที่ 6: กรองเมนูที่กินไปแล้ววันนี้
          pool.where((f) => f.category == widget.user.dietType).toList();
      if (byDiet.isNotEmpty) pool = byDiet;
    }
    return pool;
  }

  void _buildSections() {
    final pool = _pool;
    final remaining = _calRemaining;

    // 🎯 Top picks — ตรงกับ goal + fit cal ที่เหลือ
    final fitPool = remaining > 0
        ? pool.where((f) => f.calories <= remaining).toList()
        : pool;

    List<Food> sorted = List.from(fitPool);
    switch (widget.user.goal) {
      case 'Weight Loss':
        sorted.sort((a, b) => a.calories.compareTo(b.calories));
        break;
      case 'Gain weight':
        sorted.sort((a, b) => b.protein.compareTo(a.protein));
        break;
      default:
        sorted.sort((a, b) {
          if (a.isHealthy != b.isHealthy) return a.isHealthy ? -1 : 1;
          return a.calories.compareTo(b.calories);
        });
    }
    sorted.shuffle();
    _topPicks = sorted.take(6).toList();

    // 🔥 Low cal
    final lc = [...pool]..sort((a, b) => a.calories.compareTo(b.calories));
    _lowCalPicks = lc.take(6).toList()..shuffle();

    // 💪 High protein
    final hp = [...pool]..sort((a, b) => b.protein.compareTo(a.protein));
    _highProtein = hp.take(6).toList()..shuffle();

    // ✅ Healthy
    final he = pool.where((f) => f.isHealthy).toList()..shuffle();
    _healthyPicks = he.take(6).toList();
  }

  void _refresh() {
    setState(() => _buildSections());
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 300,
        child: Center(child: CircularProgressIndicator(color: _green)),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Context summary card ───────────────────
          _ContextSummaryCard(
            calToday: _calToday,
            calRemaining: _calRemaining,
            burnedToday: _burnedToday,
            eatenCount: _eatenFoodIds.length,
            goal: widget.user.goal,
            onRefresh: _refresh,
          ),

          const SizedBox(height: 20),

          // ── 🎯 Top picks ──────────────────────────
          _SectionHeader(
            emoji: '🎯',
            title: 'เหมาะกับคุณวันนี้',
            subtitle: _calRemaining > 0
                ? 'เหลือ $_calRemaining kcal · ${widget.user.goal}'
                : widget.user.goal,
          ),
          const SizedBox(height: 10),
          _FoodHorizontalList(foods: _topPicks),

          const SizedBox(height: 24),

          // ── 🔥 Low cal ────────────────────────────
          const _SectionHeader(
            emoji: '🔥',
            title: 'แคลอรี่น้อย',
            subtitle: 'เหมาะสำหรับควบคุมน้ำหนัก',
          ),
          const SizedBox(height: 10),
          _FoodHorizontalList(foods: _lowCalPicks),

          const SizedBox(height: 24),

          // ── 💪 High protein ───────────────────────
          const _SectionHeader(
            emoji: '💪',
            title: 'โปรตีนสูง',
            subtitle: 'เสริมกล้ามเนื้อ ฟื้นตัวเร็ว',
          ),
          const SizedBox(height: 10),
          _FoodHorizontalList(foods: _highProtein),

          const SizedBox(height: 24),

          // ── ✅ Healthy ────────────────────────────
          const _SectionHeader(
            emoji: '✅',
            title: 'เพื่อสุขภาพ',
            subtitle: 'Clean eating · สารอาหารครบ',
          ),
          const SizedBox(height: 10),
          _FoodHorizontalList(foods: _healthyPicks),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Context Summary Card
// ─────────────────────────────────────────────────────────
class _ContextSummaryCard extends StatelessWidget {
  final int calToday;
  final int calRemaining;
  final int burnedToday;
  final int eatenCount;
  final String goal;
  final VoidCallback onRefresh;

  const _ContextSummaryCard({
    required this.calToday,
    required this.calRemaining,
    required this.burnedToday,
    required this.eatenCount,
    required this.goal,
    required this.onRefresh,
  });

  static const _green = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // header
            Row(
              children: [
                const Icon(Icons.today, color: _green, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'สถานะวันนี้',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onRefresh,
                  child: const Icon(Icons.refresh, color: _green, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // stats row
            Row(
              children: [
                _StatItem(
                  label: 'กินแล้ว',
                  value: '$calToday',
                  unit: 'kcal',
                  color: Colors.deepOrange,
                ),
                const SizedBox(width: 8),
                _StatItem(
                  label: 'เหลืออีก',
                  value: '$calRemaining',
                  unit: 'kcal',
                  color: _green,
                  highlight: true,
                ),
                if (burnedToday > 0) ...[
                  const SizedBox(width: 8),
                  _StatItem(
                    label: 'เผาไป',
                    value: '$burnedToday',
                    unit: 'kcal',
                    color: Colors.orange.shade700,
                  ),
                ],
                const SizedBox(width: 8),
                _StatItem(
                  label: 'กินไปแล้ว',
                  value: '$eatenCount',
                  unit: 'เมนู',
                  color: Colors.grey.shade600,
                ),
              ],
            ),
            // goal badge
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: _green.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _green.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.flag_outlined, size: 13, color: _green),
                  const SizedBox(width: 4),
                  Text(
                    'เป้าหมาย: $goal',
                    style: const TextStyle(
                        fontSize: 12,
                        color: _green,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;
  final bool highlight;

  const _StatItem({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: highlight
            ? BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.2)),
              )
            : null,
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              unit,
              style: TextStyle(fontSize: 10, color: color),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.black45),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Section Header
// ─────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.emoji,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: Colors.black45),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// Horizontal scrollable food list
// ─────────────────────────────────────────────────────────
class _FoodHorizontalList extends StatelessWidget {
  final List<Food> foods;

  const _FoodHorizontalList({required this.foods});

  @override
  Widget build(BuildContext context) {
    if (foods.isEmpty) {
      return Container(
        height: 140,
        alignment: Alignment.center,
        child: const Text('ไม่มีเมนูที่ตรงกัน',
            style: TextStyle(color: Colors.black38)),
      );
    }

    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: foods.length,
        itemBuilder: (_, i) => _FoodCard(food: foods[i]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Food Card — horizontal scroll card
// ─────────────────────────────────────────────────────────
class _FoodCard extends StatelessWidget {
  final Food food;

  const _FoodCard({required this.food});

  static const _green = Color(0xFF2E7D32);

  static String _emojiFor(Food food) {
    if (food.emoji != null && food.emoji!.isNotEmpty) return food.emoji!;
    final n = food.name.toLowerCase();
    if (n.contains('ปลาหมึก')) return '🍢';
    if (n.contains('กุ้ง')) return '🦐';
    if (n.contains('ปลา') || n.contains('ทูน่า') || n.contains('แซลมอน'))
      return '🐟';
    if (n.contains('ไก่') || n.contains('อกไก่') || n.contains('เป็ด'))
      return '🍗';
    if (n.contains('หมูสามชั้น') ||
        n.contains('คอหมู') ||
        n.contains('หมูกระทะ') ||
        n.contains('หมู') ||
        n.contains('สันใน')) return '🍖';
    if (n.contains('เนื้อ') || n.contains('สเต็ก')) return '🥩';
    if (n.contains('ไข่')) return '🥚';
    if (n.contains('เต้าหู้')) return '🍱';
    if (n.contains('ก๋วยเตี๋ยว') ||
        n.contains('บะหมี่') ||
        n.contains('ผัดไทย') ||
        n.contains('สปาเกตตี') ||
        n.contains('มักกะโรนี') ||
        n.contains('สุกี้')) return '🍜';
    if (n.contains('ข้าวต้ม')) return '🍚';
    if (n.contains('ข้าว')) return '🍱';
    if (n.contains('ต้มยำ') ||
        n.contains('ต้มข่า') ||
        n.contains('ต้มจืด') ||
        n.contains('ซุป') ||
        n.contains('แกงเลียง') ||
        n.contains('แกงจืด')) return '🍲';
    if (n.contains('แกง')) return '🍛';
    if (n.contains('ส้มตำ') ||
        n.contains('ยำ') ||
        n.contains('ลาบ') ||
        n.contains('สลัด')) return '🥗';
    if (n.contains('เห็ด')) return '🍄';
    if (n.contains('ผัก') || n.contains('กะเพรา')) return '🥗';
    if (n.contains('ผัด')) return '🥘';
    switch (food.category) {
      case 'High Protein':
        return '🍗';
      case 'Keto':
        return '🥩';
      case 'Vegetarian':
        return '🥗';
      case 'Balanced':
        return '🍱';
      default:
        return '🥗';
    }
  }

  Color get _catColor {
    switch (food.category) {
      case 'Low Carb':
        return const Color(0xFF1565C0);
      case 'High Protein':
        return const Color(0xFF6A1B9A);
      case 'Vegetarian':
        return const Color(0xFF2E7D32);
      case 'Keto':
        return const Color(0xFFE65100);
      case 'Balanced':
        return const Color(0xFF00695C);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => FoodDetailScreen(food: food)),
      ),
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // emoji section
            Container(
              height: 90,
              decoration: BoxDecoration(
                color: _catColor.withOpacity(0.08),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Text(
                      _emojiFor(food),
                      style: const TextStyle(fontSize: 42),
                    ),
                  ),
                  // category badge
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _catColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        food.category.length > 7
                            ? food.category.substring(0, 7)
                            : food.category,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 7,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      food.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          height: 1.3),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(Icons.local_fire_department,
                            size: 11, color: Colors.deepOrange),
                        const SizedBox(width: 2),
                        Text(
                          '${food.calories} kcal',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepOrange),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
