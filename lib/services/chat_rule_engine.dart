// services/chat_rule_engine.dart
// ─────────────────────────────────────────────────────────
// Rule-Based Engine — แก้ตรงนี้เพื่อ:
//   • เพิ่ม keyword ใหม่  → เพิ่ม _Rule(...) ใน rules
//   • เปลี่ยนเงื่อนไขกรอง → แก้ filter: (f) => ...
//   • เปลี่ยนข้อความตอบ  → แก้ intro: '...'
// ─────────────────────────────────────────────────────────

import '../models/food_model.dart';

class ChatRuleResult {
  final String intro;
  final List<Food> foods;
  const ChatRuleResult({required this.intro, required this.foods});
}

class ChatRule {
  final List<String> keywords;
  final bool Function(Food) filter;
  final int Function(Food, Food) sort;
  final String intro;

  const ChatRule({
    required this.keywords,
    required this.filter,
    required this.sort,
    required this.intro,
  });
}

class ChatRuleEngine {
  // ── กฎทั้งหมด —
  static final List<ChatRule> rules = [
    // ลดน้ำหนัก
    ChatRule(
      keywords: [
        'ลดน้ำหนัก',
        'ลดความอ้วน',
        'ไดเอท',
        'diet',
        'lose weight',
        'low cal'
      ],
      filter: (f) => f.calories < 250,
      sort: (a, b) => a.calories.compareTo(b.calories),
      intro: '🥗 อาหารแคลอรี่ต่ำ เหมาะกับการลดน้ำหนัก:',
    ),

    // High Protein
    ChatRule(
      keywords: [
        'โปรตีน',
        'protein',
        'กล้ามเนื้อ',
        'เพิ่มกล้าม',
        'high protein'
      ],
      filter: (f) => f.protein >= 15,
      sort: (a, b) => b.protein.compareTo(a.protein),
      intro: '💪 อาหาร High Protein เหมาะสำหรับสร้างกล้ามเนื้อ:',
    ),

    // Low Carb / Keto
    ChatRule(
      keywords: ['low carb', 'คาร์บต่ำ', 'คีโต', 'keto'],
      filter: (f) => f.carbs < 20,
      sort: (a, b) => a.carbs.compareTo(b.carbs),
      intro: '🥑 อาหาร Low Carb / Keto:',
    ),

    // Vegetarian
    ChatRule(
      keywords: ['vegetarian', 'มังสวิรัติ', 'ไม่กินเนื้อ', 'เจ'],
      filter: (f) =>
          f.category.toLowerCase().contains('vegetarian') ||
          f.category.toLowerCase().contains('salad') ||
          f.category.toLowerCase().contains('veg'),
      sort: (a, b) => a.calories.compareTo(b.calories),
      intro: '🌿 อาหาร Vegetarian:',
    ),

    // Healthy
    ChatRule(
      keywords: ['สุขภาพ', 'healthy', 'ดีต่อสุขภาพ', 'clean'],
      filter: (f) => f.isHealthy,
      sort: (a, b) => a.calories.compareTo(b.calories),
      intro: '✅ อาหารเพื่อสุขภาพ:',
    ),

    // Low Calorie
    ChatRule(
      keywords: ['แคลอรี่น้อย', 'แคลต่ำ', 'แคลน้อย', 'low calorie'],
      filter: (f) => f.calories < 200,
      sort: (a, b) => a.calories.compareTo(b.calories),
      intro: '🔥 อาหารแคลอรี่น้อยมาก (< 200 kcal):',
    ),

    // Low Fat
    ChatRule(
      keywords: ['ไขมันต่ำ', 'low fat', 'ไม่มีไขมัน'],
      filter: (f) => f.fat < 5,
      sort: (a, b) => a.fat.compareTo(b.fat),
      intro: '🩺 อาหาร Low Fat:',
    ),

    // แสดงทั้งหมด / แนะนำทั่วไป
    ChatRule(
      keywords: [
        'ทั้งหมด',
        'all',
        'มีอะไรบ้าง',
        'แนะนำ',
        'recommend',
        'วันนี้กินอะไร',
        'กินอะไรดี'
      ],
      filter: (f) => true,
      sort: (a, b) => a.name.compareTo(b.name),
      intro: '🍽️ รายการอาหารทั้งหมดในระบบ:',
    ),
  ];

  // ── Match input กับ rule แรกที่เจอ ───────────────────────
  static ChatRuleResult? match(String input, List<Food> allFoods) {
    final lower = input.toLowerCase();

    for (final rule in rules) {
      if (rule.keywords.any((k) => lower.contains(k))) {
        final filtered = allFoods.where(rule.filter).toList()..sort(rule.sort);
        return ChatRuleResult(
          intro: rule.intro,
          foods: filtered.take(5).toList(), // แสดงสูงสุด 5 รายการ
        );
      }
    }
    return null; // ไม่มี rule ตรง
  }
}
