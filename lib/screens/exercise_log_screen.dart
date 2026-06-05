import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/exercise_service.dart';
import '../models/exercise_log_model.dart';

class ExerciseLogScreen extends StatefulWidget {
  const ExerciseLogScreen({super.key});

  @override
  State<ExerciseLogScreen> createState() => _ExerciseLogScreenState();
}

class _ExerciseLogScreenState extends State<ExerciseLogScreen> {
  static const _orange = Color(0xFFE65100);
  static const _lightOrange = Color(0xFFFFF3E0);

  final _exerciseService = ExerciseService();
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // FIX: เก็บ _today เป็น final ใน State ป้องกัน stream rebuild
  DateTime _selectedDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  String get _dateLabel {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = _selectedDate.difference(today).inDays;
    if (diff == 0) return 'Today';
    if (diff == -1) return 'Yesterday';
    return '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}';
  }

  void _goToPrevDay() {
    setState(
        () => _selectedDate = _selectedDate.subtract(const Duration(days: 1)));
  }

  void _goToNextDay() {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final cap = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
    if (_selectedDate.isBefore(cap)) {
      setState(
          () => _selectedDate = _selectedDate.add(const Duration(days: 1)));
    }
  }

  void _showAddExerciseSheet() {
    String selectedExercise = ExerciseService.presetExercises.first;
    final durationCtrl = TextEditingController(text: '30');
    int estimatedCal = ExerciseService.estimateCalories(
        exerciseName: selectedExercise, durationMinutes: 30);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) {
        return StatefulBuilder(builder: (ctx, setModal) {
          void recalc() {
            final dur = int.tryParse(durationCtrl.text) ?? 30;
            setModal(() {
              estimatedCal = ExerciseService.estimateCalories(
                  exerciseName: selectedExercise, durationMinutes: dur);
            });
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),

                const Text('Add Exercise',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                // Exercise type chips
                const Text('ประเภทการออกกำลังกาย',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ExerciseService.presetExercises.map((e) {
                    final selected = e == selectedExercise;
                    return ChoiceChip(
                      label: Text(e),
                      selected: selected,
                      selectedColor: _orange,
                      labelStyle: TextStyle(
                          color: selected ? Colors.white : Colors.black87),
                      onSelected: (_) {
                        setModal(() => selectedExercise = e);
                        recalc();
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                // Duration input
                const Text('ระยะเวลา (นาที)',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: durationCtrl,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => recalc(),
                  decoration: InputDecoration(
                    suffixText: 'min',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),

                const SizedBox(height: 16),

                // Estimated calories
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _lightOrange,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_fire_department,
                          color: _orange, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'ประมาณการเผาผลาญ: $estimatedCal kcal',
                        style: const TextStyle(
                            color: _orange, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () async {
                      final dur = int.tryParse(durationCtrl.text) ?? 30;
                      if (dur <= 0) return;
                      await _exerciseService.addExercise(
                        uid: _uid!,
                        name: selectedExercise,
                        durationMinutes: dur,
                        caloriesBurned: estimatedCal,
                        // FIX: ส่ง _selectedDate ไปเป็น loggedAt
                        // เพื่อให้ dateKey ตรงกับวันที่เลือก
                        loggedAt: DateTime(
                          _selectedDate.year,
                          _selectedDate.month,
                          _selectedDate.day,
                          DateTime.now().hour,
                          DateTime.now().minute,
                        ),
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: const Text('บันทึก', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_uid == null) {
      return const Scaffold(body: Center(child: Text('Please login')));
    }

    return Scaffold(
      backgroundColor: _lightOrange,
      appBar: AppBar(
        backgroundColor: _orange,
        foregroundColor: Colors.white,
        title: const Text('🏃 Exercise Log'),
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _orange,
        foregroundColor: Colors.white,
        onPressed: _showAddExerciseSheet,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // ── Date Navigator ──────────────────────────
          Container(
            color: _orange,
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: Colors.white),
                  onPressed: _goToPrevDay,
                ),
                Text(
                  _dateLabel,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: Colors.white),
                  onPressed: _goToNextDay,
                ),
              ],
            ),
          ),

          Expanded(
            // FIX: key บังคับ StreamBuilder สร้าง stream ใหม่เมื่อวันเปลี่ยน
            child: StreamBuilder<List<ExerciseLogEntry>>(
              key: ValueKey(_selectedDate),
              stream: _exerciseService.getLogsForDate(_uid!, _selectedDate),
              builder: (context, snapshot) {
                // Loading state
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Error state
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red)),
                  );
                }

                final logs = snapshot.data ?? [];
                final totalBurned =
                    logs.fold(0, (s, e) => s + e.caloriesBurned);
                final totalMin = logs.fold(0, (s, e) => s + e.durationMinutes);

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // ── Summary Card ──────────────────────
                      Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _SummaryTile(
                                icon: Icons.local_fire_department,
                                label: 'Burned',
                                value: '$totalBurned kcal',
                                color: _orange,
                              ),
                              Container(
                                  width: 1,
                                  height: 50,
                                  color: Colors.grey.shade200),
                              _SummaryTile(
                                icon: Icons.timer_outlined,
                                label: 'Duration',
                                value: '$totalMin min',
                                color: Colors.deepPurple,
                              ),
                              Container(
                                  width: 1,
                                  height: 50,
                                  color: Colors.grey.shade200),
                              _SummaryTile(
                                icon: Icons.fitness_center,
                                label: 'Sessions',
                                value: '${logs.length}',
                                color: Colors.teal,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── Exercise List ─────────────────────
                      if (logs.isEmpty)
                        Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          elevation: 3,
                          child: const Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(
                              child: Column(
                                children: [
                                  Text('🏃', style: TextStyle(fontSize: 48)),
                                  SizedBox(height: 12),
                                  Text('ยังไม่มีรายการวันนี้',
                                      style: TextStyle(
                                          color: Colors.black45, fontSize: 16)),
                                  SizedBox(height: 4),
                                  Text('กด + เพื่อเพิ่มการออกกำลังกาย',
                                      style: TextStyle(
                                          color: Colors.black38, fontSize: 13)),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        ...logs.map((log) => Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              elevation: 2,
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _orange.withOpacity(0.1),
                                  child: const Icon(Icons.fitness_center,
                                      color: _orange, size: 20),
                                ),
                                title: Text(log.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                subtitle: Text(
                                    '${log.durationMinutes} min  •  ${log.caloriesBurned} kcal'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.close,
                                      size: 18, color: Colors.black38),
                                  onPressed: () => _exerciseService
                                      .deleteExercise(_uid!, log.id),
                                ),
                              ),
                            )),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 6),
        Text(value,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.black45)),
      ],
    );
  }
}
