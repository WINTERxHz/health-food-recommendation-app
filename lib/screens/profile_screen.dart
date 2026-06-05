import 'dart:io';
import 'package:appfoodh/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../services/storage_service.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/health_profile_card.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? get _user => FirebaseAuth.instance.currentUser;

  final AuthService _authService = AuthService();
  final ProfileService _profileService = ProfileService();
  final StorageService _storageService = StorageService();
  final ImagePicker _picker = ImagePicker();

  UserModel? _userModel;
  bool _isLoading = true;
  bool _isUploading = false;

  static const _primaryGreen = Color(0xFF2E7D32);
  static const _lightGreen = Color(0xFFE8F5E9);

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (_user == null) return;
    final data = await _profileService.getProfile(_user!.uid);
    if (!mounted) return;
    setState(() {
      _userModel = data;
      _isLoading = false;
    });
  }

  // ─────────────────────────────────────────
  // Bottom Sheet: เปลี่ยนชื่อ
  // ─────────────────────────────────────────
  void _showChangeNameSheet() {
    if (_userModel == null) return;

    final firstNameController =
        TextEditingController(text: _userModel!.firstName);
    final lastNameController =
        TextEditingController(text: _userModel!.lastName);
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
          padding: MediaQuery.of(_).viewInsets +
              const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: StatefulBuilder(
            builder: (ctx, setModalState) {
              return Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      "Change Name",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    /// First Name
                    TextFormField(
                      controller: firstNameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: "First Name",
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),

                    const SizedBox(height: 12),

                    /// Last Name
                    TextFormField(
                      controller: lastNameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: "Last Name",
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;
                                setModalState(() => isSaving = true);

                                try {
                                  await _authService.updateName(
                                    uid: _user!.uid,
                                    firstName: firstNameController.text.trim(),
                                    lastName: lastNameController.text.trim(),
                                  );

                                  if (!mounted) return;
                                  setState(() {
                                    _userModel = _userModel!.copyWith(
                                      firstName:
                                          firstNameController.text.trim(),
                                      lastName: lastNameController.text.trim(),
                                    );
                                  });
                                  Navigator.pop(ctx);
                                  _showSnackBar("Name updated successfully",
                                      isError: false);
                                } catch (e) {
                                  setModalState(() => isSaving = false);
                                  _showSnackBar(e.toString());
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryGreen,
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
                            : const Text("Save",
                                style: TextStyle(
                                    fontSize: 16, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────
  // Bottom Sheet: เปลี่ยนรหัสผ่าน
  // ─────────────────────────────────────────
  void _showChangePasswordSheet() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    bool isSaving = false;
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (_) {
        return Padding(
          padding: MediaQuery.of(_).viewInsets +
              const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: StatefulBuilder(
            builder: (ctx, setModalState) {
              return Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      "Change Password",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    /// Current Password
                    TextFormField(
                      controller: currentPasswordController,
                      obscureText: obscureCurrent,
                      decoration: InputDecoration(
                        labelText: "Current Password",
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(obscureCurrent
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () => setModalState(
                              () => obscureCurrent = !obscureCurrent),
                        ),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),

                    const SizedBox(height: 12),

                    /// New Password
                    TextFormField(
                      controller: newPasswordController,
                      obscureText: obscureNew,
                      decoration: InputDecoration(
                        labelText: "New Password",
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(obscureNew
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () =>
                              setModalState(() => obscureNew = !obscureNew),
                        ),
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

                    /// Confirm Password
                    TextFormField(
                      controller: confirmPasswordController,
                      obscureText: obscureConfirm,
                      decoration: InputDecoration(
                        labelText: "Confirm New Password",
                        prefixIcon: const Icon(Icons.lock_reset),
                        suffixIcon: IconButton(
                          icon: Icon(obscureConfirm
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () => setModalState(
                              () => obscureConfirm = !obscureConfirm),
                        ),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (v != newPasswordController.text) {
                          return 'Passwords do not match';
                        }
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
                                setModalState(() => isSaving = true);

                                try {
                                  await _authService.updatePassword(
                                    currentPassword:
                                        currentPasswordController.text,
                                    newPassword: newPasswordController.text,
                                  );

                                  if (!mounted) return;
                                  Navigator.pop(ctx);
                                  _showSnackBar("Password changed successfully",
                                      isError: false);
                                } catch (e) {
                                  setModalState(() => isSaving = false);
                                  _showSnackBar(e
                                      .toString()
                                      .replaceAll('Exception: ', ''));
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryGreen,
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
                                style: TextStyle(
                                    fontSize: 16, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────
  // Bottom Sheet: แก้ไข Health Profile
  // ─────────────────────────────────────────
  void _showEditHealthSheet() {
    if (_userModel == null) return;

    final weightController =
        TextEditingController(text: _userModel!.weight.toString());
    final heightController =
        TextEditingController(text: _userModel!.height.toString());

    String selectedDiet = _userModel!.dietType;
    String selectedGoal = _userModel!.goal;

    // 1. เพิ่มตัวแปรสำหรับเก็บเพศและวันเกิดที่ดึงมาจากโมเดลปัจจุบัน
    String selectedGender = _userModel!.gender;
    DateTime? selectedBirthDate = _userModel!.birthDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (_) {
        return Padding(
          padding: MediaQuery.of(_).viewInsets +
              const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: StatefulBuilder(
            builder: (ctx, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "Edit Health Profile",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // --- (โค้ด Dropdown Goal, Diet, Weight, Height เดิม) ---
                  DropdownButtonFormField<String>(
                    initialValue: selectedGoal,
                    decoration: InputDecoration(
                      labelText: "Goal",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    items: ["Weight Loss", "Maintain", "Gain weight"]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedGoal = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedDiet,
                    decoration: InputDecoration(
                      labelText: "Diet Type",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    items: ["Balanced", "Low Carb", "Vegetarian", "Keto"]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedDiet = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: weightController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Weight (kg)",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: heightController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Height (cm)",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  // --------------------------------------------------

                  const SizedBox(height: 12),

                  // 2. เพิ่ม Dropdown สำหรับเลือกเพศ
                  DropdownButtonFormField<String>(
                    initialValue: selectedGender,
                    decoration: InputDecoration(
                      labelText: "Gender",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    items: ["Male", "Female"]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null)
                        setModalState(() => selectedGender = val);
                    },
                  ),
                  const SizedBox(height: 12),

                  // 3. เพิ่มปุ่มเลือกวันเกิด (Date of Birth)
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedBirthDate ??
                            DateTime(1990), // ตั้งต้นปี 1990 ถ้าไม่มีข้อมูล
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setModalState(() => selectedBirthDate = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: "Date of Birth",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        selectedBirthDate == null
                            ? "Select Date"
                            : "${selectedBirthDate!.day}/${selectedBirthDate!.month}/${selectedBirthDate!.year}",
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        final weight =
                            double.tryParse(weightController.text) ?? 0;
                        final height =
                            double.tryParse(heightController.text) ?? 0;
                        final bmi =
                            _profileService.calculateBMI(weight, height);

                        // 4. บันทึกเพศและวันเกิด เข้าไปใน UserModel
                        final updated = _userModel!.copyWith(
                            dietType: selectedDiet,
                            goal: selectedGoal,
                            weight: weight,
                            height: height,
                            bmi: bmi,
                            gender: selectedGender, // เซฟเพศ
                            birthDate: selectedBirthDate // เซฟวันเกิด
                            );

                        await _profileService.updateProfile(
                            _user!.uid, updated);
                        if (!mounted) return;
                        setState(() => _userModel = updated);
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryGreen,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Save",
                          style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _confirmLogout() async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text("Logout", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    if (_userModel == null) return;

    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
    );
    if (cropped == null) return;

    setState(() => _isUploading = true);

    final url = await _storageService.uploadProfileImage(
        _user!.uid, File(cropped.path));

    final updated = _userModel!.copyWith(photoUrl: url);
    await _profileService.updateProfile(_user!.uid, updated);

    if (!mounted) return;
    setState(() {
      _userModel = updated;
      _isUploading = false;
    });
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : _primaryGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_userModel == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Profile")),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Profile not found."),
              const SizedBox(height: 16),
              ElevatedButton(
                  onPressed: _loadProfile, child: const Text("Retry")),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _lightGreen,
      appBar: AppBar(
        backgroundColor: _lightGreen,
        elevation: 0,
        title: const Text("Profile", style: TextStyle(color: _primaryGreen)),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 32),

            /// Avatar
            ProfileAvatar(
              photoUrl: _userModel!.photoUrl,
              isUploading: _isUploading,
              onTap: _pickImage,
            ),

            const SizedBox(height: 12),

            /// ✅ แสดงชื่อ user แทน email
            Text(
              _userModel!.fullName.isNotEmpty
                  ? _userModel!.fullName
                  : "No name set",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _primaryGreen,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              _user?.email ?? "",
              style: const TextStyle(color: Colors.black45, fontSize: 13),
            ),

            // const SizedBox(height: 20),
            // ElevatedButton(
            //   onPressed: () async {
            //     // เรียกใช้ฟังก์ชันยิงทันทีที่คุณเขียนไว้
            //     await NotificationService().showInstantNotification(
            //       title: 'ทดสอบแจ้งเตือน 🚀',
            //       body: 'ระบบพื้นฐานทำงานได้ 100% ครับ!',
            //     );
            //   },
            //   child: const Text('ทดสอบยิงแจ้งเตือน'),
            // ),

            /// Health Profile Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: HealthProfileCard(
                user: _userModel!,
                onEdit: _showEditHealthSheet,
              ),
            ),

            const SizedBox(height: 16),

            /// Account Settings Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                elevation: 3,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.badge_outlined,
                          color: _primaryGreen),
                      title: const Text("Change Name"),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _showChangeNameSheet,
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      leading:
                          const Icon(Icons.lock_outline, color: _primaryGreen),
                      title: const Text("Change Password"),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _showChangePasswordSheet,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            /// Logout
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

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
