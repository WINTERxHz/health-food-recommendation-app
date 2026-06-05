import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final weightController = TextEditingController();
  final heightController = TextEditingController();

  String selectedGoal = "Maintain";
  String selectedDiet = "Balanced";
  String selectedGender = "Male";
  bool isLoading = false;

  double calculateBMI(double weight, double height) {
    double h = height / 100;
    return weight / (h * h);
  }

  Future<void> saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => isLoading = true);

    try {
      double weight = double.tryParse(weightController.text) ?? 0;
      double height = double.tryParse(heightController.text) ?? 0;
      double bmi = calculateBMI(weight, height);

      await FirebaseFirestore.instance.collection("users").doc(user.uid).set({
        "weight": weight,
        "height": height,
        "bmi": bmi,
        "goal": selectedGoal,
        "dietType": selectedDiet,
        "gender": selectedGender,
      }, SetOptions(merge: true));

      // ✅ navigate ไป HomeScreen
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
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
        title: const Text(
          "Health Setup",
          style: TextStyle(color: primaryGreen),
        ),
        iconTheme: const IconThemeData(color: primaryGreen),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Icon(
                Icons.health_and_safety,
                size: 80,
                color: primaryGreen,
              ),
              const SizedBox(height: 20),
              const Text(
                "Tell us about your health",
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: primaryGreen),
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.green.withOpacity(0.1),
                        blurRadius: 25,
                        offset: const Offset(0, 15))
                  ],
                ),
                child: Column(
                  children: [
                    /// Weight
                    TextField(
                      controller: weightController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.monitor_weight),
                        labelText: "Weight (kg)",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                    ),

                    const SizedBox(height: 16),

                    /// Height
                    TextField(
                      controller: heightController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.height),
                        labelText: "Height (cm)",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedGender,
                      items: ["Male", "Female"]
                          .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (val) {
                        setState(() => selectedGender = val!);
                      },
                      decoration: InputDecoration(
                        labelText: "Gender",
                        prefixIcon: const Icon(Icons.wc),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                    ),

                    const SizedBox(height: 16),

                    /// Goal
                    DropdownButtonFormField(
                      initialValue: selectedGoal,
                      items: ["Weight Loss", "Maintain", "Gain weight"]
                          .map((e) => DropdownMenuItem(
                                value: e,
                                child: Text(e),
                              ))
                          .toList(),
                      onChanged: (val) {
                        setState(() => selectedGoal = val!);
                      },
                      decoration: InputDecoration(
                        labelText: "Goal",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                    ),

                    const SizedBox(height: 16),

                    /// Diet Type
                    DropdownButtonFormField(
                      initialValue: selectedDiet,
                      items: ["Balanced", "Low Carb", "Vegetarian", "Keto"]
                          .map((e) => DropdownMenuItem(
                                value: e,
                                child: Text(e),
                              ))
                          .toList(),
                      onChanged: (val) {
                        setState(() => selectedDiet = val!);
                      },
                      decoration: InputDecoration(
                        labelText: "Diet Type",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                    ),

                    const SizedBox(height: 30),

                    isLoading
                        ? const CircularProgressIndicator(color: primaryGreen)
                        : SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: saveProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryGreen,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                "Finish Setup",
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
