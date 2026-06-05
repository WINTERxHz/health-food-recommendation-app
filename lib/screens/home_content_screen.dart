import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/food_service.dart';
import '../services/favorite_service.dart';
import '../models/food_model.dart';
import 'admin/admin_dashboard.dart';
import 'food_detail_screen.dart';
import 'favorites_screen.dart';

class HomeContentScreen extends StatefulWidget {
  const HomeContentScreen({super.key});

  @override
  State<HomeContentScreen> createState() => _HomeContentScreenState();
}

class _HomeContentScreenState extends State<HomeContentScreen> {
  static const _green = Color(0xFF2E7D32);
  static const _lightGreen = Color(0xFFE8F5E9);
  static const _darkGreen = Color(0xFF1B5E20);

  final _foodService = FoodService();
  final _favoriteService = FavoriteService();
  final _searchCtrl = TextEditingController();

  String _selectedCategory = "";
  String _searchText = "";
  bool _isAdmin = false;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;
  String get _firstName =>
      FirebaseAuth.instance.currentUser?.displayName?.split(' ').first ?? 'คุณ';

  // ── Categories ────────────────────────────────────────
  static const _categories = [
    {'label': 'ทั้งหมด', 'value': '', 'emoji': '🍽️'},
    {'label': 'Low Carb', 'value': 'Low Carb', 'emoji': '🥗'},
    {'label': 'Balanced', 'value': 'Balanced', 'emoji': '⚖️'},
    {'label': 'High Protein', 'value': 'High Protein', 'emoji': '💪'},
    {'label': 'Vegetarian', 'value': 'Vegetarian', 'emoji': '🌿'},
    {'label': 'Keto', 'value': 'Keto', 'emoji': '🥑'},
  ];

  @override
  void initState() {
    super.initState();
    _checkAdmin();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final token = await user.getIdTokenResult(true);
    if (!mounted) return;
    setState(() => _isAdmin = token.claims?['admin'] == true);
  }

  List<Food> _filter(List<Food> foods) {
    return foods
        .where((f) => f.name.toLowerCase().contains(_searchText.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightGreen,
      body: CustomScrollView(
        slivers: [
          // ── SliverAppBar ──────────────────────────────
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            backgroundColor: _green,
            actions: [
              // ── Favorites button ──────────────────────
              IconButton(
                icon: const Icon(Icons.favorite_border, color: Colors.white70),
                tooltip: 'รายการโปรด',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                ),
              ),
              if (_isAdmin)
                IconButton(
                  icon: const Icon(Icons.admin_panel_settings,
                      color: Colors.white70),
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => AdminDashboard())),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_darkGreen, _green],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'สวัสดี $_firstName 👋',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'วันนี้อยากกินอะไร?',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        // Search bar inside header
                        Container(
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.3)),
                          ),
                          child: TextField(
                            controller: _searchCtrl,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'ค้นหาอาหาร...',
                              hintStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 14),
                              prefixIcon: Icon(Icons.search,
                                  color: Colors.white.withOpacity(0.7),
                                  size: 20),
                              border: InputBorder.none,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              suffixIcon: _searchText.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(Icons.close,
                                          color: Colors.white.withOpacity(0.7),
                                          size: 18),
                                      onPressed: () {
                                        _searchCtrl.clear();
                                        setState(() => _searchText = '');
                                      },
                                    )
                                  : null,
                            ),
                            onChanged: (v) => setState(() => _searchText = v),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Category chips ────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              color: _green,
              child: Container(
                decoration: const BoxDecoration(
                  color: _lightGreen,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((cat) {
                      final selected = _selectedCategory == cat['value'];
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedCategory = cat['value']!),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected ? _green : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                        color: _green.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3))
                                  ]
                                : [],
                            border: Border.all(
                                color:
                                    selected ? _green : Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Text(cat['emoji']!,
                                  style: const TextStyle(fontSize: 14)),
                              const SizedBox(width: 6),
                              Text(
                                cat['label']!,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      selected ? Colors.white : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),

          // ── Food Grid ─────────────────────────────────
          if (_uid == null)
            const SliverFillRemaining(
              child: Center(child: Text('Please login')),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
              sliver: StreamBuilder<List<String>>(
                stream: _favoriteService.getFavoriteIds(_uid!),
                builder: (context, favSnap) {
                  final favIds = favSnap.data ?? [];
                  return StreamBuilder<List<Food>>(
                    stream: _foodService.getFoods(category: _selectedCategory),
                    builder: (context, snap) {
                      if (!snap.hasData) {
                        return const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.only(top: 60),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        );
                      }

                      final foods = _filter(snap.data!);

                      if (foods.isEmpty) {
                        return const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.only(top: 60),
                            child: Center(
                              child: Column(
                                children: [
                                  Text('🌿', style: TextStyle(fontSize: 48)),
                                  SizedBox(height: 12),
                                  Text('ไม่พบเมนูที่ค้นหา',
                                      style: TextStyle(color: Colors.black45)),
                                ],
                              ),
                            ),
                          ),
                        );
                      }

                      return SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => _FoodCard(
                            food: foods[i],
                            isFav: favIds.contains(foods[i].id),
                            onFavTap: () => _favoriteService.toggleFavorite(
                                _uid!, foods[i].id),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      FoodDetailScreen(food: foods[i])),
                            ),
                          ),
                          childCount: foods.length,
                        ),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.85,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ── Food Card Widget ──────────────────────────────────────
class _FoodCard extends StatelessWidget {
  final Food food;
  final bool isFav;
  final VoidCallback onFavTap;
  final VoidCallback onTap;

  const _FoodCard({
    required this.food,
    required this.isFav,
    required this.onFavTap,
    required this.onTap,
  });

  static const _green = Color(0xFF2E7D32);

  // ── emoji ตรงกับแต่ละเมนู (ใช้เฉพาะ emoji ที่ support ทุก platform) ──
  static String _emojiFor(Food food) {
    if (food.emoji != null && food.emoji!.isNotEmpty) return food.emoji!;
    final n = food.name.toLowerCase();
    if (n.contains('ปลาหมึก')) return '🍢';
    if (n.contains('กุ้ง')) return '🦐';
    if (n.contains('ปลา') || n.contains('ทูน่า') || n.contains('แซลมอน'))
      return '🐟';
    if (n.contains('ไก่') || n.contains('อกไก่') || n.contains('เป็ด'))
      return '🍗';
    if (n.contains('หมูสามชั้น') ||
        n.contains('คอหมู') ||
        n.contains('หมูกระทะ') ||
        n.contains('หมู') ||
        n.contains('สันใน')) return '🍖';
    if (n.contains('เนื้อ') || n.contains('สเต็ก')) return '🥩';
    if (n.contains('ไข่')) return '🥚';
    if (n.contains('เต้าหู้')) return '🍱';
    if (n.contains('ก๋วยเตี๋ยว') ||
        n.contains('บะหมี่') ||
        n.contains('ผัดไทย') ||
        n.contains('สปาเกตตี') ||
        n.contains('มักกะโรนี') ||
        n.contains('สุกี้')) return '🍜';
    if (n.contains('ข้าวต้ม')) return '🍚';
    if (n.contains('ข้าว')) return '🍱';
    if (n.contains('ต้มยำ') ||
        n.contains('ต้มข่า') ||
        n.contains('ต้มจืด') ||
        n.contains('ซุป') ||
        n.contains('แกงเลียง') ||
        n.contains('แกงจืด')) return '🍲';
    if (n.contains('แกง')) return '🍛';
    if (n.contains('ส้มตำ') ||
        n.contains('ยำ') ||
        n.contains('ลาบ') ||
        n.contains('สลัด')) return '🥗';
    if (n.contains('เห็ด')) return '🍄';
    if (n.contains('ผัก') || n.contains('กะเพรา')) return '🥗';
    if (n.contains('ผัด')) return '🥘';
    switch (food.category) {
      case 'High Protein':
        return '🍗';
      case 'Keto':
        return '🥩';
      case 'Vegetarian':
        return '🥗';
      case 'Balanced':
        return '🍱';
      default:
        return '🥗';
    }
  }

  Color get _categoryColor {
    switch (food.category) {
      case 'Low Carb':
        return const Color(0xFF1565C0);
      case 'High Protein':
        return const Color(0xFF6A1B9A);
      case 'Vegetarian':
        return const Color(0xFF2E7D32);
      case 'Keto':
        return const Color(0xFFE65100);
      case 'Balanced':
        return const Color(0xFF00695C);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top: emoji + fav ─────────────────────
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              child: Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _categoryColor.withOpacity(0.08),
                ),
                child: Stack(
                  children: [
                    // emoji กลางการ์ด
                    Center(
                      child: Text(
                        _emojiFor(food),
                        style: const TextStyle(fontSize: 50),
                      ),
                    ),

                    // fav button
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: onFavTap,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4)
                            ],
                          ),
                          child: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            size: 16,
                            color: isFav ? Colors.redAccent : Colors.grey,
                          ),
                        ),
                      ),
                    ),

                    // category badge
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: _categoryColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          food.category,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Bottom: info ─────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      food.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          height: 1.3),
                    ),
                    const Spacer(),
                    // Calories highlight
                    Row(
                      children: [
                        const Icon(Icons.local_fire_department,
                            size: 13, color: Colors.deepOrange),
                        const SizedBox(width: 2),
                        Text(
                          '${food.calories} kcal',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepOrange),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Macro mini badges
                    Row(
                      children: [
                        _MiniBadge('P${food.protein}', Colors.blue),
                        const SizedBox(width: 3),
                        _MiniBadge('F${food.fat}', Colors.amber.shade700),
                        const SizedBox(width: 3),
                        _MiniBadge('C${food.carbs}', Colors.purple),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final String text;
  final Color color;
  const _MiniBadge(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        text,
        style:
            TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
