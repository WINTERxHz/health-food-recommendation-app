import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/food_model.dart';
import '../services/food_log_service.dart';
import '../services/favorite_service.dart';

class FoodDetailScreen extends StatefulWidget {
  final Food food;

  const FoodDetailScreen({super.key, required this.food});

  @override
  State<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends State<FoodDetailScreen> {
  static const _primaryGreen = Color(0xFF2E7D32);
  static const _lightGreen = Color(0xFFE8F5E9);

  final _logService = FoodLogService();
  final _favService = FavoriteService();

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;
  String _selectedMeal = 'Lunch';

  static const _meals = ['Breakfast', 'Lunch', 'Dinner'];

  Future<void> _addToLog() async {
    if (_uid == null) return;
    await _logService.addLog(
      uid: _uid!,
      food: widget.food,
      mealType: _selectedMeal,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("${widget.food.name} added to $_selectedMeal"),
      backgroundColor: _primaryGreen,
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final food = widget.food;

    return Scaffold(
      backgroundColor: _lightGreen,
      appBar: AppBar(
        backgroundColor: _primaryGreen,
        title: Text(food.name),
        actions: [
          // Favorite toggle
          if (_uid != null)
            StreamBuilder<List<String>>(
              stream: _favService.getFavoriteIds(_uid!),
              builder: (_, snap) {
                final isFav = snap.data?.contains(food.id) ?? false;
                return IconButton(
                  icon: Icon(
                    isFav ? Icons.favorite : Icons.favorite_border,
                    color: isFav ? Colors.redAccent : Colors.white,
                  ),
                  onPressed: () => _favService.toggleFavorite(_uid!, food.id),
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero icon ────────────────────────
            Center(
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.green.withOpacity(0.15),
                        blurRadius: 30,
                        offset: const Offset(0, 10)),
                  ],
                ),
                child: Icon(
                  food.isHealthy ? Icons.eco : Icons.fastfood,
                  size: 64,
                  color: food.isHealthy ? _primaryGreen : Colors.orange,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Name + badges ────────────────────
            Center(
              child: Column(children: [
                Text(food.name,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _Badge(label: food.category, color: _primaryGreen),
                  const SizedBox(width: 8),
                  if (food.isHealthy)
                    _Badge(label: "✓ Healthy", color: Colors.green.shade600),
                ]),
              ]),
            ),

            const SizedBox(height: 24),

            // ── Calories big card ────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.deepOrange.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.deepOrange.withOpacity(0.2)),
              ),
              child: Column(children: [
                const Text("Calories",
                    style: TextStyle(color: Colors.deepOrange, fontSize: 14)),
                const SizedBox(height: 4),
                Text("${food.calories}",
                    style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange)),
                const Text("kcal",
                    style: TextStyle(color: Colors.deepOrange, fontSize: 14)),
              ]),
            ),

            const SizedBox(height: 16),

            // ── Macros ───────────────────────────
            Row(children: [
              _MacroCard(
                  label: "Protein",
                  value: "${food.protein}g",
                  color: Colors.blue,
                  icon: Icons.fitness_center),
              const SizedBox(width: 10),
              _MacroCard(
                  label: "Fat",
                  value: "${food.fat}g",
                  color: Colors.amber.shade700,
                  icon: Icons.water_drop),
              const SizedBox(width: 10),
              _MacroCard(
                  label: "Carbs",
                  value: "${food.carbs}g",
                  color: Colors.purple,
                  icon: Icons.rice_bowl),
            ]),

            const SizedBox(height: 24),

            // ── Add to Log section ───────────────
            const Text("Add to Food Log",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // Meal selector
            Row(
              children: _meals.map((meal) {
                final selected = meal == _selectedMeal;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedMeal = meal),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? _primaryGreen : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              selected ? _primaryGreen : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        meal,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : Colors.black54,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _addToLog,
                icon: const Icon(Icons.add),
                label: Text("Add to $_selectedMeal"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(
              color: color, fontWeight: FontWeight.w600, fontSize: 13)),
    );
  }
}

class _MacroCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _MacroCard(
      {required this.label,
      required this.value,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(color: Colors.black45, fontSize: 11)),
        ]),
      ),
    );
  }
}
