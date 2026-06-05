import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/water_service.dart';
import '../models/water_log_model.dart';

class WaterTrackerScreen extends StatefulWidget {
  const WaterTrackerScreen({super.key});

  @override
  State<WaterTrackerScreen> createState() => _WaterTrackerScreenState();
}

class _WaterTrackerScreenState extends State<WaterTrackerScreen> {
  static const _blue = Color(0xFF1565C0);
  static const _lightBlue = Color(0xFFE3F2FD);
  static const _dailyGoal = 2000;

  final _waterService = WaterService();
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // FIX 1: เก็บ _today เป็น final ใน State ไม่ใช่ส่ง DateTime.now() ตรงๆ
  // เพื่อป้องกัน stream สร้างใหม่ทุก build
  final _today = DateTime.now();

  final _quickAmounts = [150, 200, 250, 350, 500];

  Future<void> _addWater(int amount) async {
    if (_uid == null) return;
    await _waterService.addWater(_uid!, amount);
  }

  // FIX 2: ใช้ mounted check + ScaffoldMessenger เพื่อป้องกัน context หาย
  Future<void> _showCustomDialog() async {
    final ctrl = TextEditingController();

    // FIX 3: ใช้ BuildContext แยก ไม่ใช้ context หลัง await
    if (!mounted) return;

    final result = await showDialog<int>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('กำหนดปริมาณ'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'ปริมาณน้ำ (ml)',
            suffixText: 'ml',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _blue),
            onPressed: () {
              final val = int.tryParse(ctrl.text.trim());
              if (val != null && val > 0) {
                Navigator.pop(dialogCtx, val);
              } else {
                // แสดง error ใน dialog ถ้ากรอกไม่ถูก
                ScaffoldMessenger.of(dialogCtx).showSnackBar(
                  const SnackBar(content: Text('กรุณากรอกตัวเลขที่มากกว่า 0')),
                );
              }
            },
            child: const Text('เพิ่ม'),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      await _addWater(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_uid == null) {
      return const Scaffold(body: Center(child: Text('Please login')));
    }

    return Scaffold(
      backgroundColor: _lightBlue,
      appBar: AppBar(
        backgroundColor: _blue,
        foregroundColor: Colors.white,
        title: const Text('💧 Water Tracker'),
        centerTitle: false,
      ),
      // FIX 1: ส่ง _today แทน DateTime.now() — ป้องกัน stream rebuild
      body: StreamBuilder<List<WaterLogEntry>>(
        stream: _waterService.getLogsForDate(_uid!, _today),
        builder: (context, snapshot) {
          // FIX 4: แสดง loading ระหว่างรอ stream ครั้งแรก
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // FIX 5: แสดง error ถ้า stream มีปัญหา
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final logs = snapshot.data ?? [];
          final total = logs.fold(0, (s, e) => s + e.amount);
          final progress = (total / _dailyGoal).clamp(0.0, 1.0);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // ── Progress Card ──────────────────────────
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24)),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 160,
                              height: 160,
                              child: CircularProgressIndicator(
                                value: progress,
                                strokeWidth: 14,
                                backgroundColor: Colors.blue.shade100,
                                color: _blue,
                              ),
                            ),
                            Column(
                              children: [
                                const Text('💧',
                                    style: TextStyle(fontSize: 36)),
                                Text(
                                  '$total ml',
                                  style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: _blue),
                                ),
                                const Text(
                                  'of $_dailyGoal ml',
                                  style: TextStyle(
                                      color: Colors.black45, fontSize: 13),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: progress >= 1.0
                                ? Colors.green.shade50
                                : Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            progress >= 1.0
                                ? '🎉 Goal reached! Great job!'
                                : '${_dailyGoal - total} ml remaining',
                            style: TextStyle(
                              color: progress >= 1.0 ? Colors.green : _blue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Quick Add ──────────────────────────────
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quick Add',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            ..._quickAmounts.map((ml) => ElevatedButton(
                                  onPressed: () => _addWater(ml),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _blue,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14)),
                                  ),
                                  child: Text('+ $ml ml'),
                                )),
                            OutlinedButton.icon(
                              onPressed: _showCustomDialog,
                              icon: const Icon(Icons.edit, size: 16),
                              label: const Text('Custom'),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: _blue),
                                foregroundColor: _blue,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Today's Log ────────────────────────────
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Today's Log",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${logs.length} entries',
                              style: const TextStyle(
                                  color: Colors.black45, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (logs.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: Column(
                                children: [
                                  Text('💧', style: TextStyle(fontSize: 32)),
                                  SizedBox(height: 8),
                                  Text(
                                    'ยังไม่มีรายการวันนี้',
                                    style: TextStyle(
                                        color: Colors.black38, fontSize: 14),
                                  ),
                                  Text(
                                    'กด + เพื่อเพิ่มปริมาณน้ำ',
                                    style: TextStyle(
                                        color: Colors.black26, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ...logs.map((log) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const CircleAvatar(
                                  backgroundColor: _lightBlue,
                                  child: Text('💧'),
                                ),
                                title: Text(
                                  '${log.amount} ml',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text(
                                  '${log.loggedAt.hour.toString().padLeft(2, '0')}:${log.loggedAt.minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(color: Colors.black45),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.close,
                                      size: 18, color: Colors.black38),
                                  onPressed: () =>
                                      _waterService.deleteWater(_uid!, log.id),
                                ),
                              )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
