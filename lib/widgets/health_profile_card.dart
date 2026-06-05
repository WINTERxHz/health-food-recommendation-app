// widgets/health_profile_card.dart
// เพิ่ม TDEE card ใต้ BMI
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/tdee_service.dart';

class HealthProfileCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onEdit;

  const HealthProfileCard({
    super.key,
    required this.user,
    required this.onEdit,
  });

  static const _primaryGreen = Color(0xFF2E7D32);

  Color _getBMIColor() {
    if (user.bmi < 18.5) return Colors.blue;
    if (user.bmi < 25) return _primaryGreen;
    if (user.bmi < 30) return Colors.orange;
    return Colors.red;
  }

  String _getBMILabel() {
    if (user.bmi < 18.5) return "Underweight";
    if (user.bmi < 25) return "Normal";
    if (user.bmi < 30) return "Overweight";
    return "Obese";
  }

  @override
  Widget build(BuildContext context) {
    final bmiColor = _getBMIColor();

    // คำนวณ TDEE + daily goal
    final age = TdeeService.calculateAge(user.birthDate);
    final tdee =
        TdeeService.calculateTDEE(user.weight, user.height, age, user.gender);
    final dailyGoal = TdeeService.calculateDailyGoal(
        user.weight, user.height, user.goal, age, user.gender);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildRow("Diet", user.dietType),
            _buildRow("Goal", user.goal),

            // เพิ่มการแสดงผล 2 บรรทัดนี้
            _buildRow("Gender", user.gender),
            _buildRow(
                "Age", "${TdeeService.calculateAge(user.birthDate)} years"),

            _buildRow("Weight", "${user.weight.toStringAsFixed(1)} kg"),
            _buildRow("Height", "${user.height.toStringAsFixed(1)} cm"),
            // ── BMI row ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("BMI", style: TextStyle(fontSize: 15)),
                  Row(
                    children: [
                      Text(
                        user.bmi.toStringAsFixed(1),
                        style: TextStyle(
                          color: bmiColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: bmiColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getBMILabel(),
                          style: TextStyle(
                            color: bmiColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(height: 20),

            // ── TDEE Card ────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _primaryGreen.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _primaryGreen.withOpacity(0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.local_fire_department,
                          color: _primaryGreen, size: 18),
                      SizedBox(width: 6),
                      Text(
                        "TDEE & แคลอรี่เป้าหมาย",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: _primaryGreen),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildTdeeRow(
                    "TDEE (ค่าพลังงานรวม)",
                    "${tdee.toStringAsFixed(0)} kcal/วัน",
                    Colors.black54,
                  ),
                  const SizedBox(height: 4),
                  _buildTdeeRow(
                    TdeeService.goalLabel(user.goal),
                    "${dailyGoal.toStringAsFixed(0)} kcal/วัน",
                    _primaryGreen,
                    bold: true,
                  ),
                  const SizedBox(height: 10),
                  // Progress bar แสดง daily goal เทียบ TDEE
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (dailyGoal / tdee).clamp(0.0, 1.5),
                      backgroundColor: Colors.grey.shade200,
                      color: _primaryGreen,
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "* คำนวณจากสูตร Mifflin-St Jeor × Activity 1.55",
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit, size: 18),
                label: const Text("Edit Profile"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 15)),
          Text(value,
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildTdeeRow(String label, String value, Color color,
      {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.black54)),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }
}
