import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/food_service.dart';
import '../../models/food_model.dart';
import '../login_screen.dart';
import 'add_food_screen.dart';
import 'edit_food_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  final FoodService _foodService = FoodService();

  static const _primaryDark = Color(0xFF1B5E20);
  static const _bg = Color(0xFFF1F8E9);

  String _searchText = "";
  String _selectedCategory = "";

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 🔴 Logout function
  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Logout", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  List<Food> _filter(List<Food> foods) {
    return foods.where((f) {
      final matchSearch =
          f.name.toLowerCase().contains(_searchText.toLowerCase());
      final matchCat =
          _selectedCategory.isEmpty || f.category == _selectedCategory;
      return matchSearch && matchCat;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,

      // ✅ AppBar + Logout
      appBar: AppBar(
        backgroundColor: _primaryDark,
        title: const Text("Manage Foods"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
            onPressed: _logout,
          ),
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

      // ✅ Add Food Button
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _primaryDark,
        icon: const Icon(Icons.add),
        label: const Text("Add Food"),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddFoodScreen()),
          );
        },
      ),

      // ✅ Body
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // 🔍 Search + Filter
            Container(
              color: _primaryDark,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: "Search food...",
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                    ),
                    onChanged: (v) => setState(() => _searchText = v),
                  ),
                  const SizedBox(height: 10),

                  // Category filter
                  SizedBox(
                    height: 32,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        "",
                        "Low Carb",
                        "Balanced",
                        "Vegetarian",
                        "High Protein",
                        "Keto"
                      ]
                          .map((cat) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(cat.isEmpty ? "All" : cat),
                                  selected: _selectedCategory == cat,
                                  selectedColor: Colors.white,
                                  backgroundColor: Colors.white24,
                                  labelStyle: TextStyle(
                                    color: _selectedCategory == cat
                                        ? _primaryDark
                                        : Colors.white,
                                    fontSize: 12,
                                  ),
                                  onSelected: (_) =>
                                      setState(() => _selectedCategory = cat),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),

            // 🍱 Food List
            Expanded(
              child: StreamBuilder<List<Food>>(
                stream: _foodService.getFoods(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final foods = _filter(snapshot.data!);

                  if (foods.isEmpty) {
                    return const Center(child: Text("No food found"));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: foods.length,
                    itemBuilder: (context, index) {
                      final food = foods[index];

                      return ListTile(
                        title: Text(food.name),
                        subtitle: Text("${food.calories} kcal"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        EditFoodScreen(foodId: food.id),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                await _foodService.deleteFood(food.id);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
