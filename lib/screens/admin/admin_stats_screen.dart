import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/food_model.dart';
import '../../services/food_service.dart';

/// Stats หน้า Admin — เน้นภาพรวมฐานข้อมูล + ข้อมูล users ในระบบ
class AdminStatsScreen extends StatelessWidget {
  const AdminStatsScreen({super.key});

  static const _primaryDark = Color(0xFF1B5E20);
  static const _bg = Color(0xFFF1F8E9);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _primaryDark,
        title: const Text("System Statistics"),
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.admin_panel_settings, size: 14, color: Colors.white),
                SizedBox(width: 4),
                Text("ADMIN",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── User Stats ───────────────────────
            _sectionTitle("👥 Users Overview"),
            const SizedBox(height: 10),
            _UserStatsRow(),
            const SizedBox(height: 24),

            // ── Food Database Stats ───────────────
            _sectionTitle("🍽️ Food Database"),
            const SizedBox(height: 10),
            StreamBuilder<List<Food>>(
              stream: FoodService().getFoods(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(color: _primaryDark));
                }
                final foods = snapshot.data!;
                return Column(
                  children: [
                    _FoodOverviewCards(foods: foods),
                    const SizedBox(height: 16),
                    _CategoryBreakdown(foods: foods),
                    const SizedBox(height: 16),
                    _RecentFoods(foods: foods),
                  ],
                );
              },
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(
        title,
        style: const TextStyle(
            fontSize: 17, fontWeight: FontWeight.bold, color: _primaryDark),
      );
}

// ─────────────────────────────────────────────────────────
// User Stats — ดึงจาก Firestore users collection
// ─────────────────────────────────────────────────────────
class _UserStatsRow extends StatelessWidget {
  static const _primaryDark = Color(0xFF1B5E20);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs;
        final total = docs.length;

        // นับ goal distribution
        final goals = <String, int>{};
        final diets = <String, int>{};
        for (final doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final goal = data['goal'] as String? ?? 'Unknown';
          final diet = data['dietType'] as String? ?? 'Unknown';
          goals[goal] = (goals[goal] ?? 0) + 1;
          diets[diet] = (diets[diet] ?? 0) + 1;
        }

        return Column(
          children: [
            // Total Users card
            _AdminStatCard(
              icon: Icons.people,
              label: "Total Users",
              value: "$total",
              color: _primaryDark,
              subtitle: "Registered accounts",
            ),
            const SizedBox(height: 12),
            // Goal breakdown
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Goals Distribution",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 12),
                    ...goals.entries.map((e) => _ProgressRow(
                          label: e.key,
                          count: e.value,
                          total: total,
                          color: _primaryDark,
                        )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Diet breakdown
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Diet Types Distribution",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 12),
                    ...diets.entries.map((e) => _ProgressRow(
                          label: e.key,
                          count: e.value,
                          total: total,
                          color: Colors.blue.shade700,
                        )),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────
// Food Overview Cards
// ─────────────────────────────────────────────────────────
class _FoodOverviewCards extends StatelessWidget {
  final List<Food> foods;
  const _FoodOverviewCards({required this.foods});

  static const _primaryDark = Color(0xFF1B5E20);

  @override
  Widget build(BuildContext context) {
    final healthy = foods.where((f) => f.isHealthy).length;
    final avgCal = foods.isEmpty
        ? 0
        : foods.map((f) => f.calories).reduce((a, b) => a + b) ~/ foods.length;

    return Row(
      children: [
        Expanded(
          child: _AdminStatCard(
            icon: Icons.restaurant_menu,
            label: "Total Foods",
            value: "${foods.length}",
            color: _primaryDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _AdminStatCard(
            icon: Icons.eco,
            label: "Healthy",
            value: "$healthy",
            color: Colors.green.shade600,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _AdminStatCard(
            icon: Icons.local_fire_department,
            label: "Avg. Cal",
            value: "$avgCal",
            color: Colors.deepOrange,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// Category Breakdown
// ─────────────────────────────────────────────────────────
class _CategoryBreakdown extends StatelessWidget {
  final List<Food> foods;
  const _CategoryBreakdown({required this.foods});

  static const _primaryDark = Color(0xFF1B5E20);

  @override
  Widget build(BuildContext context) {
    final Map<String, int> counts = {};
    for (final f in foods) {
      counts[f.category] = (counts[f.category] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Foods by Category",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 12),
            ...sorted.map((e) => _ProgressRow(
                  label: e.key,
                  count: e.value,
                  total: foods.length,
                  color: _primaryDark,
                )),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Recently Added Foods (top 5)
// ─────────────────────────────────────────────────────────
class _RecentFoods extends StatelessWidget {
  final List<Food> foods;
  const _RecentFoods({required this.foods});

  static const _primaryDark = Color(0xFF1B5E20);

  @override
  Widget build(BuildContext context) {
    final recent = foods.take(5).toList();
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Recently Added Foods",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 12),
            ...recent.map((food) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _primaryDark.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          food.isHealthy ? Icons.eco : Icons.fastfood,
                          color: food.isHealthy ? _primaryDark : Colors.orange,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(food.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 14)),
                            Text(food.category,
                                style: const TextStyle(
                                    color: Colors.black45, fontSize: 12)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.deepOrange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "${food.calories} kcal",
                          style: const TextStyle(
                              color: Colors.deepOrange,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Shared Widgets
// ─────────────────────────────────────────────────────────
class _AdminStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final String? subtitle;

  const _AdminStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    fontSize: 26, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(fontSize: 11, color: Colors.black45)),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(subtitle!,
                  style: const TextStyle(fontSize: 10, color: Colors.black38)),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;

  const _ProgressRow({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : count / total;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 13)),
              Text("$count (${(pct * 100).toStringAsFixed(0)}%)",
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: color)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: Colors.black,
              color: color,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
