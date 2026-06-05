import 'package:flutter/material.dart';
import 'home_content_screen.dart';
import 'food_log_screen.dart';
import 'for_you_screen.dart';
import 'favorites_screen.dart';
import 'stats_screen.dart';
import 'profile_screen.dart';
import 'chatbot_screen.dart';
import 'water_tracker_screen.dart';
import 'exercise_log_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _primaryGreen = Color(0xFF2E7D32);

  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomeContentScreen(), // 0 - Home
    FoodLogScreen(), // 1 - Log
    ForYouScreen(), // 2 - For You ⭐
    StatsScreen(), // 3 - Stats
    ProfileScreen(), // 4 - Profile
  ];

  void _openChat() {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const ChatbotScreen()));
  }

  void _openWater() {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const WaterTrackerScreen()));
  }

  void _openExercise() {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const ExerciseLogScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),

      // ── FAB with SpeedDial ─────────────────────────────
      floatingActionButton: _HealthFAB(
        onChat: _openChat,
        onWater: _openWater,
        onExercise: _openExercise,
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: _primaryGreen,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.edit_calendar_outlined),
            activeIcon: Icon(Icons.edit_calendar),
            label: 'Log',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.recommend_outlined),
            activeIcon: Icon(Icons.recommend),
            label: 'For You',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Stats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Speed Dial FAB — Chat / Water / Exercise
// ─────────────────────────────────────────────────────────
class _HealthFAB extends StatefulWidget {
  final VoidCallback onChat;
  final VoidCallback onWater;
  final VoidCallback onExercise;

  const _HealthFAB({
    required this.onChat,
    required this.onWater,
    required this.onExercise,
  });

  @override
  State<_HealthFAB> createState() => _HealthFABState();
}

class _HealthFABState extends State<_HealthFAB>
    with SingleTickerProviderStateMixin {
  static const _green = Color(0xFF2E7D32);
  bool _open = false;
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _open = !_open);
    _open ? _ctrl.forward() : _ctrl.reverse();
  }

  Widget _miniButton({
    required String emoji,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ScaleTransition(
      scale: _scale,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Text(label, style: const TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 8),
          FloatingActionButton.small(
            heroTag: label,
            backgroundColor: color,
            onPressed: () {
              _toggle();
              onTap();
            },
            child: Text(emoji, style: const TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_open) ...[
          _miniButton(
            emoji: '🥗',
            label: 'Nutrition Chat',
            color: _green,
            onTap: widget.onChat,
          ),
          const SizedBox(height: 10),
          _miniButton(
            emoji: '💧',
            label: 'Water Tracker',
            color: const Color(0xFF1565C0),
            onTap: widget.onWater,
          ),
          const SizedBox(height: 10),
          _miniButton(
            emoji: '🏃',
            label: 'Exercise Log',
            color: const Color(0xFFE65100),
            onTap: widget.onExercise,
          ),
          const SizedBox(height: 10),
        ],
        FloatingActionButton(
          heroTag: 'main_fab',
          backgroundColor: _green,
          onPressed: _toggle,
          child: AnimatedRotation(
            turns: _open ? 0.125 : 0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.add, size: 28),
          ),
        ),
      ],
    );
  }
}
