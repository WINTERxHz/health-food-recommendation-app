import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/food_model.dart';
import '../services/favorite_service.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  static const _primaryGreen = Color(0xFF2E7D32);
  static const _lightGreen = Color(0xFFE8F5E9);

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(body: Center(child: Text("Please login")));
    }

    final favoriteService = FavoriteService();

    return Scaffold(
      backgroundColor: _lightGreen,
      appBar: AppBar(
        backgroundColor: _primaryGreen,
        title: const Text("Favorites"),
        centerTitle: false,
      ),
      body: StreamBuilder<List<Food>>(
        stream: favoriteService.getFavoriteFoods(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: _primaryGreen));
          }

          final foods = snapshot.data ?? [];

          if (foods.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.favorite_border,
                      size: 72, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text(
                    "No favorites yet",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black45),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Tap ❤️ on any food to save it here",
                    style: TextStyle(color: Colors.black38),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: foods.length,
            itemBuilder: (context, index) {
              return _FoodFavoriteCard(
                food: foods[index],
                uid: uid,
                favoriteService: favoriteService,
              );
            },
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Card แต่ละรายการ
// ─────────────────────────────────────────────────────────
class _FoodFavoriteCard extends StatelessWidget {
  final Food food;
  final String uid;
  final FavoriteService favoriteService;

  const _FoodFavoriteCard({
    required this.food,
    required this.uid,
    required this.favoriteService,
  });

  static const _primaryGreen = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                food.isHealthy ? Icons.eco : Icons.fastfood,
                color: food.isHealthy ? _primaryGreen : Colors.orange,
                size: 28,
              ),
            ),

            const SizedBox(width: 14),

            /// Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          food.name,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (food.isHealthy)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _primaryGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            "Healthy",
                            style: TextStyle(
                                color: _primaryGreen,
                                fontSize: 11,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  Text(
                    food.category,
                    style: const TextStyle(color: Colors.black45, fontSize: 12),
                  ),

                  const SizedBox(height: 10),

                  /// Macros
                  Row(
                    children: [
                      _MacroBadge(
                          label: "Cal",
                          value: "${food.calories}",
                          color: Colors.deepOrange),
                      const SizedBox(width: 6),
                      _MacroBadge(
                          label: "P",
                          value: "${food.protein}g",
                          color: Colors.blue),
                      const SizedBox(width: 6),
                      _MacroBadge(
                          label: "F",
                          value: "${food.fat}g",
                          color: Colors.amber.shade700),
                      const SizedBox(width: 6),
                      _MacroBadge(
                          label: "C",
                          value: "${food.carbs}g",
                          color: Colors.purple),
                    ],
                  ),
                ],
              ),
            ),

            /// Remove from favorites
            IconButton(
              icon: const Icon(Icons.favorite, color: Colors.redAccent),
              tooltip: "Remove from favorites",
              onPressed: () => favoriteService.toggleFavorite(uid, food.id),
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MacroBadge(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        "$label $value",
        style:
            TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
