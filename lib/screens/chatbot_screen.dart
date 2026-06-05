// screens/chatbot_screen.dart
// ─────────────────────────────────────────────────────────
// UI ของหน้า Chatbot — แก้ตรงนี้เพื่อ:
//   • เปลี่ยนสี / ขนาด font / layout
//   • เพิ่ม / ลด suggestion chips
//   • แก้ข้อความทักทาย
//
// Logic การตอบอยู่ใน: services/chat_rule_engine.dart
// โมเดลข้อความอยู่ใน: models/chat_message.dart
// ─────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message.dart';
import '../models/food_model.dart';
import '../models/user_model.dart';
import '../services/food_service.dart';
import '../services/chat_rule_engine.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  static const _green = Color(0xFF2E7D32);
  static const _lightGreen = Color(0xFFE8F5E9);

  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _foodService = FoodService();

  final List<ChatMessage> _messages = [];
  List<Food> _allFoods = [];
  UserModel? _userModel;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // ── Suggestion chips — แก้ตรงนี้เพื่อเปลี่ยนปุ่มลัด ──
  final _suggestions = [
    '🥗 กินอะไรลดน้ำหนักได้บ้าง?',
    '💪 อาหาร High Protein มีอะไรบ้าง?',
    '🥑 แนะนำ Low Carb หน่อย',
    '✅ อาหารเพื่อสุขภาพ',
    '🍽️ มีอาหารอะไรบ้าง?',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────
  // Data Loading
  // ─────────────────────────────────────────────────────

  Future<void> _loadData() async {
    if (_uid != null) {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(_uid).get();
      if (doc.exists && mounted) {
        setState(() => _userModel = UserModel.fromMap(doc.data()!));
      }
    }

    _foodService.getFoods().first.then((foods) {
      if (mounted) setState(() => _allFoods = foods);
    });

    // ข้อความทักทาย — แก้ตรงนี้
    final name = _userModel?.firstName ?? '';
    _addBotMessage(
      'สวัสดี${name.isNotEmpty ? ' คุณ$name' : ''}ครับ! 🥗\n'
      'ผมช่วยแนะนำอาหารได้เลยครับ\n'
      'ลองพิมพ์ว่า "อยากลดน้ำหนัก" หรือ "อาหาร High Protein" ได้เลย',
    );
  }

  // ─────────────────────────────────────────────────────
  // Message Helpers
  // ─────────────────────────────────────────────────────

  void _addBotMessage(String text) {
    setState(() => _messages.add(ChatMessage(text: text, isUser: false)));
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ─────────────────────────────────────────────────────
  // Send & Process — Logic อยู่ใน ChatRuleEngine
  // ─────────────────────────────────────────────────────

  void _send(String text) {
    if (text.trim().isEmpty) return;
    _textCtrl.clear();
    setState(() => _messages.add(ChatMessage(text: text.trim(), isUser: true)));
    _scrollToBottom();
    Future.delayed(
        const Duration(milliseconds: 400), () => _processInput(text));
  }

  void _processInput(String input) {
    if (_allFoods.isEmpty) {
      _addBotMessage('⏳ กำลังโหลดข้อมูลอาหาร กรุณารอสักครู่แล้วลองใหม่ครับ');
      return;
    }

    final result = ChatRuleEngine.match(input, _allFoods);

    if (result == null) {
      _addBotMessage(
        'ขออภัยครับ ไม่เข้าใจคำถามนี้ 😅\n'
        'ลองพิมพ์แบบนี้ได้เลยครับ:\n'
        '• "อยากลดน้ำหนัก"\n'
        '• "อาหาร High Protein"\n'
        '• "Low Carb มีอะไรบ้าง"\n'
        '• "อาหารเพื่อสุขภาพ"',
      );
      return;
    }

    if (result.foods.isEmpty) {
      _addBotMessage('ขออภัยครับ ไม่พบอาหารที่ตรงกับเงื่อนไขนี้ในระบบ 🙏');
      return;
    }

    final buf = StringBuffer();
    buf.writeln(result.intro);
    buf.writeln();
    for (final f in result.foods) {
      buf.writeln('🍴 ${f.name}');
      buf.writeln(
          '   🔥 ${f.calories} kcal  •  P: ${f.protein}g  •  C: ${f.carbs}g  •  F: ${f.fat}g');
    }

    if (_userModel != null) {
      buf.writeln();
      buf.write('💡 ');
      switch (_userModel!.goal) {
        case 'Lose Weight':
          buf.write(
              'เหมาะกับเป้าหมายลดน้ำหนักของคุณครับ ควรรับไม่เกิน 1,500 kcal/วัน');
          break;
        case 'Gain weight':
          final targetProtein = (_userModel!.weight * 1.6).toStringAsFixed(0);
          buf.write(
              'เหมาะสำหรับเพิ่มน้ำหนัก ควรได้โปรตีน ${targetProtein}g/วัน');
          break;
        default:
          buf.write('เหมาะกับเป้าหมายรักษาน้ำหนักของคุณครับ');
      }
    }

    _addBotMessage(buf.toString());
  }

  // ─────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightGreen,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          if (_messages.length <= 1) _buildSuggestions(),
          _buildInputBar(),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: _green,
      title: const Row(
        children: [
          Text('🥗', style: TextStyle(fontSize: 20)),
          SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nutrition Chat',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              Text('Rule-Based System',
                  style: TextStyle(fontSize: 11, color: Colors.white70)),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white70),
          tooltip: 'ล้างแชท',
          onPressed: () {
            setState(() => _messages.clear());
            _addBotMessage('เริ่มใหม่แล้วครับ 🌿 ถามได้เลย!');
          },
        ),
      ],
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      itemCount: _messages.length,
      itemBuilder: (_, i) => _buildBubble(_messages[i]),
    );
  }

  Widget _buildBubble(ChatMessage msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!msg.isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                  color: _green, borderRadius: BorderRadius.circular(10)),
              child: const Center(
                  child: Text('🥗', style: TextStyle(fontSize: 16))),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: msg.isUser ? _green : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(msg.isUser ? 18 : 4),
                  bottomRight: Radius.circular(msg.isUser ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Text(
                msg.text,
                style: TextStyle(
                    color: msg.isUser ? Colors.white : Colors.black87,
                    fontSize: 14,
                    height: 1.5),
              ),
            ),
          ),
          if (msg.isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.person, size: 18, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('  ลองถามได้เลย 💬',
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _suggestions
                .map((s) => GestureDetector(
                      onTap: () => _send(s),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: _lightGreen,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _green.withOpacity(0.3)),
                        ),
                        child: Text(s,
                            style: const TextStyle(
                                fontSize: 12,
                                color: _green,
                                fontWeight: FontWeight.w500)),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textCtrl,
              maxLines: 3,
              minLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: _send,
              decoration: InputDecoration(
                hintText: 'ถามเรื่องอาหารได้เลย...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: _green, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _send(_textCtrl.text),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: _green, borderRadius: BorderRadius.circular(22)),
              child:
                  const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
