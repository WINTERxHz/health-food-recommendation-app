import 'package:flutter/material.dart';
import '../../services/food_service.dart';

class AddFoodScreen extends StatefulWidget {
  const AddFoodScreen({super.key});

  @override
  State<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen> {
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _calories = TextEditingController();
  final _protein = TextEditingController();
  final _fat = TextEditingController();
  final _carbs = TextEditingController();

  bool _isHealthy = false;
  bool _isLoading = false;

  String _selectedCategory = "Balanced";

  final _foodService = FoodService();

  Future<void> _saveFood() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    await _foodService.addFood(
      name: _name.text.trim(),
      calories: int.parse(_calories.text.trim()),
      protein: int.parse(_protein.text.trim()),
      fat: int.parse(_fat.text.trim()),
      carbs: int.parse(_carbs.text.trim()),
      category: _selectedCategory,
      isHealthy: _isHealthy,
    );

    setState(() => _isLoading = false);

    Navigator.pop(context);
  }

  @override
  void dispose() {
    _name.dispose();
    _calories.dispose();
    _protein.dispose();
    _fat.dispose();
    _carbs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF2E7D32);
    const lightGreen = Color(0xFFE8F5E9);

    return Scaffold(
      backgroundColor: lightGreen,
      appBar: AppBar(
        backgroundColor: lightGreen,
        elevation: 0,
        iconTheme: const IconThemeData(color: primaryGreen),
        title: const Text(
          "Add Food",
          style: TextStyle(color: primaryGreen),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.1),
                    blurRadius: 25,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    /// Food Name
                    TextFormField(
                      controller: _name,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.fastfood),
                        labelText: "Food Name",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),

                    const SizedBox(height: 16),

                    /// Calories
                    TextFormField(
                      controller: _calories,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.local_fire_department),
                        labelText: "Calories",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),

                    const SizedBox(height: 16),

                    /// Protein
                    TextFormField(
                      controller: _protein,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.fitness_center),
                        labelText: "Protein (g)",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    /// Fat
                    TextFormField(
                      controller: _fat,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.water_drop),
                        labelText: "Fat (g)",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    /// Carbs
                    TextFormField(
                      controller: _carbs,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.rice_bowl),
                        labelText: "Carbs (g)",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    /// Category
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.category),
                        labelText: "Category",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: "Low Carb",
                          child: Text("Low Carb"),
                        ),
                        DropdownMenuItem(
                          value: "Balanced",
                          child: Text("Balanced"),
                        ),
                        DropdownMenuItem(
                          value: "Vegetarian",
                          child: Text("Vegetarian"),
                        ),
                        DropdownMenuItem(
                          value: "High Protein",
                          child: Text("High Protein"),
                        ),
                        DropdownMenuItem(
                          value: "Keto",
                          child: Text("Keto"),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    /// Healthy Switch
                    SwitchListTile(
                      activeThumbColor: primaryGreen,
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Healthy"),
                      value: _isHealthy,
                      onChanged: (v) => setState(() => _isHealthy = v),
                    ),

                    const SizedBox(height: 24),

                    /// Save Button
                    _isLoading
                        ? const CircularProgressIndicator(color: primaryGreen)
                        : SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _saveFood,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryGreen,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                "Save",
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
