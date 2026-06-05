import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../login_screen.dart';

/// หน้า Settings สำหรับ Admin — แสดงข้อมูล account + ตัวเลือกระบบ
class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  static const _primaryDark = Color(0xFF1B5E20);
  static const _bg = Color(0xFFF1F8E9);

  final _authService = AuthService();
  User? get _user => FirebaseAuth.instance.currentUser;

  UserModel? _userModel;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = _user;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
    var doc = await ref.get();

    // ถ้าไม่มี document → สร้างให้อัตโนมัติจากข้อมูล Firebase Auth
    if (!doc.exists) {
      final nameParts = (user.displayName ?? '').split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts.first : 'Admin';
      final lastName =
          nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      await ref.set({
        'firstName': firstName,
        'lastName': lastName,
        'email': user.email ?? '',
        'photoUrl': user.photoURL,
        'goal': 'Maintain',
        'dietType': 'Balanced',
        'weight': 0.0,
        'height': 0.0,
        'bmi': 0.0,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      doc = await ref.get();
    }

    if (mounted) {
      setState(() {
        _userModel = doc.exists ? UserModel.fromMap(doc.data()!) : null;
        _isLoading = false;
      });
    }
  }

  void _showChangePasswordSheet() {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (_) {
        return Padding(
          padding: MediaQuery.of(_).viewInsets + const EdgeInsets.all(20),
          child: StatefulBuilder(builder: (ctx, setState) {
            return Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text("Change Password",
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: currentCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "Current Password",
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: newCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "New Password",
                      prefixIcon: const Icon(Icons.lock),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (v.length < 6) return 'At least 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: confirmCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "Confirm New Password",
                      prefixIcon: const Icon(Icons.lock_reset),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (v != newCtrl.text) return 'Passwords do not match';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              setState(() => isSaving = true);
                              try {
                                await _authService.updatePassword(
                                  currentPassword: currentCtrl.text,
                                  newPassword: newCtrl.text,
                                );
                                if (!mounted) return;
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text("Password changed successfully"),
                                    backgroundColor: _primaryDark,
                                  ),
                                );
                              } catch (e) {
                                setState(() => isSaving = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(e
                                        .toString()
                                        .replaceAll('Exception: ', '')),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryDark,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Text("Change Password",
                              style:
                                  TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          }),
        );
      },
    );
  }

  Future<void> _confirmLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Logout", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _primaryDark,
        title: const Text("Admin Settings"),
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.admin_panel_settings, size: 14, color: Colors.white),
                SizedBox(width: 4),
                Text("ADMIN",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 32),

            // ── Admin Avatar ──────────────────────
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1B5E20),
                    Colors.green.shade400,
                  ],
                ),
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white,
                backgroundImage: _userModel?.photoUrl != null
                    ? NetworkImage(_userModel!.photoUrl!)
                    : null,
                child: _userModel?.photoUrl == null
                    ? const Icon(Icons.admin_panel_settings,
                        size: 44, color: Color(0xFF1B5E20))
                    : null,
              ),
            ),

            const SizedBox(height: 12),

            // ── Admin badge ───────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF1B5E20),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text("ADMINISTRATOR",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── ชื่อ / อีเมล ──────────────────────
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (_userModel == null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: Colors.orange.shade700, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          "Profile not found",
                          style: TextStyle(
                              color: Colors.orange.shade700,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () {
                        setState(() => _isLoading = true);
                        _loadProfile();
                      },
                      icon: const Icon(Icons.refresh, size: 16),
                      label:
                          const Text("Retry", style: TextStyle(fontSize: 13)),
                      style: TextButton.styleFrom(
                        foregroundColor: _primaryDark,
                      ),
                    ),
                  ],
                ),
              )
            else
              Text(
                _userModel!.fullName.isNotEmpty
                    ? _userModel!.fullName
                    : "Admin",
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

            if (!_isLoading)
              Text(
                _user?.email ?? "",
                style: const TextStyle(color: Colors.black45, fontSize: 13),
              ),

            const SizedBox(height: 28),

            // ── Account Settings ──────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _SettingsSection(
                title: "Account",
                children: [
                  _SettingsTile(
                    icon: Icons.lock_outline,
                    label: "Change Password",
                    onTap: _showChangePasswordSheet,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── About ─────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _SettingsSection(
                title: "About",
                children: [
                  const _SettingsTile(
                    icon: Icons.info_outline,
                    label: "App Version",
                    trailing: Text("1.0.0",
                        style: TextStyle(color: Colors.black45, fontSize: 13)),
                    onTap: null,
                  ),
                  _SettingsTile(
                    icon: Icons.security,
                    label: "Role",
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B5E20).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text("Admin",
                          style: TextStyle(
                              color: Color(0xFF1B5E20),
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ),
                    onTap: null,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── Logout ────────────────────────────
            ElevatedButton.icon(
              onPressed: _confirmLogout,
              icon: const Icon(Icons.logout),
              label: const Text("Logout"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Shared Widgets
// ─────────────────────────────────────────────────────────
class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black45)),
        ),
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 2,
          child: Column(
            children: children
                .expand((w) => [
                      w,
                      if (w != children.last)
                        const Divider(height: 1, indent: 16, endIndent: 16),
                    ])
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.trailing,
    this.onTap,
  });

  static const _primaryDark = Color(0xFF1B5E20);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: _primaryDark),
      title: Text(label),
      trailing:
          trailing ?? (onTap != null ? const Icon(Icons.chevron_right) : null),
      onTap: onTap,
    );
  }
}
