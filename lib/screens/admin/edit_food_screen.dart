import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/food_service.dart';

class EditFoodScreen extends StatefulWidget {
  final String foodId;

  const EditFoodScreen({super.key, required this.foodId});

  @override
  State<EditFoodScreen> createState() => _EditFoodScreenState();
}

class _EditFoodScreenState extends State<EditFoodScreen> {
  final _formKey = GlobalKey<FormState>();
  final FoodService _foodService = FoodService();

  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _fatController = TextEditingController();
  final _carbsController = TextEditingController();

  String _selectedCategory = "Balanced";
  bool _isHealthy = false;
  bool _isLoading = true;
  bool _isSaving = false;

  static const _categories = [
    "Low Carb",
    "Balanced",
    "Vegetarian",
    "High Protein",
    "Keto",
  ];

  @override
  void initState() {
    super.initState();
    _loadFood();
  }

  Future<void> _loadFood() async {
    final doc = await FirebaseFirestore.instance
        .collection('foods')
        .doc(widget.foodId)
        .get();

    final data = doc.data();

    if (data != null) {
      _nameController.text = data['name'] ?? '';
      _caloriesController.text = (data['calories'] ?? 0).toString();
      _proteinController.text = (data['protein'] ?? 0).toString();
      _fatController.text = (data['fat'] ?? 0).toString();
      _carbsController.text = (data['carbs'] ?? 0).toString();
      _isHealthy = data['isHealthy'] ?? false;

      // ป้องกัน category ที่ไม่อยู่ใน list
      final savedCategory = data['category'] ?? 'Balanced';
      _selectedCategory =
          _categories.contains(savedCategory) ? savedCategory : "Balanced";
    }

    setState(() => _isLoading = false);
  }

  Future<void> _updateFood() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    await _foodService.updateFood(
      widget.foodId,
      {
        'name': _nameController.text.trim(),
        'calories': int.tryParse(_caloriesController.text.trim()) ?? 0,
        'protein': int.tryParse(_proteinController.text.trim()) ?? 0,
        'fat': int.tryParse(_fatController.text.trim()) ?? 0,
        'carbs': int.tryParse(_carbsController.text.trim()) ?? 0,
        'category': _selectedCategory,
        'isHealthy': _isHealthy,
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _fatController.dispose();
    _carbsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF2E7D32);
    const lightGreen = Color(0xFFE8F5E9);

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: lightGreen,
        body: Center(
          child: CircularProgressIndicator(color: primaryGreen),
        ),
      );
    }

    return Scaffold(
      backgroundColor: lightGreen,
      appBar: AppBar(
        backgroundColor: lightGreen,
        elevation: 0,
        iconTheme: const IconThemeData(color: primaryGreen),
        title: const Text(
          "Edit Food",
          style: TextStyle(color: primaryGreen),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Food Name
                    _buildField(
                      controller: _nameController,
                      label: "Food Name",
                      icon: Icons.fastfood,
                      keyboardType: TextInputType.text,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),

                    const SizedBox(height: 16),

                    /// Calories
                    _buildField(
                      controller: _caloriesController,
                      label: "Calories (kcal)",
                      icon: Icons.local_fire_department,
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),

                    const SizedBox(height: 16),

                    /// Protein
                    _buildField(
                      controller: _proteinController,
                      label: "Protein (g)",
                      icon: Icons.fitness_center,
                      keyboardType: TextInputType.number,
                    ),

                    const SizedBox(height: 16),

                    /// Fat
                    _buildField(
                      controller: _fatController,
                      label: "Fat (g)",
                      icon: Icons.water_drop,
                      keyboardType: TextInputType.number,
                    ),

                    const SizedBox(height: 16),

                    /// Carbs
                    _buildField(
                      controller: _carbsController,
                      label: "Carbs (g)",
                      icon: Icons.rice_bowl,
                      keyboardType: TextInputType.number,
                    ),

                    const SizedBox(height: 16),

                    /// Category Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.category),
                        labelText: "Category",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: primaryGreen),
                        ),
                      ),
                      items: _categories
                          .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedCategory = val);
                        }
                      },
                    ),

                    const SizedBox(height: 8),

                    /// Healthy Switch
                    SwitchListTile(
                      activeThumbColor: primaryGreen,
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Healthy"),
                      value: _isHealthy,
                      onChanged: (v) => setState(() => _isHealthy = v),
                    ),

                    const SizedBox(height: 24),

                    /// Update Button
                    _isSaving
                        ? const Center(
                            child:
                                CircularProgressIndicator(color: primaryGreen),
                          )
                        : SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _updateFood,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryGreen,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                "Update",
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

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    const primaryGreen = Color(0xFF2E7D32);
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryGreen),
        ),
      ),
      validator: validator,
    );
  }
}
