// services/tdee_service.dart
// ─────────────────────────────────────────────────────────
// คำนวณ TDEE (Total Daily Energy Expenditure)
// ใช้สูตร Mifflin-St Jeor + Activity Factor
// แก้ตรงนี้ถ้าอยากเปลี่ยนสูตรหรือ activity level
// ─────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

class TdeeService {
  // ── ฟังก์ชันช่วยคำนวณอายุจากวันเกิด ────────────────
  static int calculateAge(DateTime? birthDate) {
    if (birthDate == null) return 30; // ถ้าไม่มีข้อมูลให้ใช้ค่ากลางคือ 30
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  // ── คำนวณ BMR (Basal Metabolic Rate) ────────────────
  // สูตร Mifflin-St Jeor (มาตรฐานที่นิยมใช้)
  // ชาย: (10 × weight) + (6.25 × height) - (5 × age) + 5
  // หญิง: (10 × weight) + (6.25 × height) - (5 × age) - 161
  // * แอพนี้ไม่เก็บ gender/age → ใช้ค่ากลาง (neutral formula)
  static double calculateBMR(
      double weightKg, double heightCm, int age, String gender) {
    double baseBmr = (10 * weightKg) + (6.25 * heightCm) - (5 * age);

    if (gender.toLowerCase() == 'male' || gender == 'ชาย') {
      return baseBmr + 5;
    } else {
      return baseBmr - 161;
    }
  }

  // ── คำนวณ TDEE จาก goal ──────────────────────────────
  // Sedentary × 1.2, Light × 1.375, Moderate × 1.55
  // ใช้ Moderate (1.55) เป็นค่า default เหมาะกับคนทั่วไป
  static double calculateTDEE(
      double weightKg, double heightCm, int age, String gender) {
    return calculateBMR(weightKg, heightCm, age, gender) * 1.55;
  }

  // ── คำนวณแคลอรี่เป้าหมายตาม goal ────────────────────
  static double calculateDailyGoal(
      double weightKg, double heightCm, String goal, int age, String gender) {
    final tdee = calculateTDEE(weightKg, heightCm, age, gender);
    switch (goal) {
      case 'Lose Weight':
        return tdee - 500;
      case 'Gain weight':
        return tdee + 300;
      default:
        return tdee;
    }
  }

  // ── label สำหรับแสดงใน UI ────────────────────────────
  static String goalLabel(String goal) {
    switch (goal) {
      case 'Lose Weight':
        return 'ลดน้ำหนัก (-500 kcal)';
      case 'Gain weight': //gain weight
        return 'เพิ่มกล้ามเนื้อ (+300 kcal)';
      default:
        return 'รักษาน้ำหนัก';
    }
  }

  // ── สีของ progress bar ตามเปอร์เซ็นต์ที่กิน ──────────
  static Color progressColor(double percent) {
    if (percent < 0.7) return const Color(0xFF2E7D32); // เขียว — ยังน้อย
    if (percent < 0.9) return const Color(0xFFF57F17); // เหลือง — ใกล้ถึง
    if (percent <= 1.0) return const Color(0xFF1565C0); // น้ำเงิน — เต็มพอดี
    return const Color(0xFFC62828); // แดง — เกินแล้ว
  }
}
