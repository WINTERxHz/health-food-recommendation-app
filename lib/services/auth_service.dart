import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    DateTime? birthDate,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;

      await _db.collection('users').doc(uid).set({
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'birthDate': birthDate?.toIso8601String(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthError(e));
    }
  }

  Future<User?> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  // ✅ Google Sign-In
  Future<User?> signInWithGoogle() async {
    try {
      // เปิด Google account picker
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // user กด cancel

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await _auth.signInWithCredential(credential);
      final user = result.user!;

      // บันทึก/อัปเดต profile ใน Firestore (merge เพื่อไม่ทับข้อมูลเดิม)
      final nameParts = (user.displayName ?? '').split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts.first : '';
      final lastName =
          nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      await _db.collection('users').doc(user.uid).set({
        'firstName': firstName,
        'lastName': lastName,
        'email': user.email ?? '',
        'photoUrl': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthError(e));
    } catch (e) {
      throw Exception('Google Sign-In failed: $e');
    }
  }

  Future<void> updateName({
    required String uid,
    required String firstName,
    required String lastName,
  }) async {
    await _db.collection('users').doc(uid).update({
      'firstName': firstName,
      'lastName': lastName,
    });
  }

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) throw Exception("Not logged in");

    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );

    try {
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthError(e));
    }
  }

  Future<void> logout() async {
    await _googleSignIn.signOut(); // sign out Google ด้วยเสมอ
    await _auth.signOut();
  }

  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Email นี้ถูกใช้แล้ว';
      case 'invalid-email':
        return 'รูปแบบ Email ไม่ถูกต้อง';
      case 'weak-password':
        return 'รหัสผ่านสั้นเกินไป (ต้องมีอย่างน้อย 6 ตัว)';
      case 'user-not-found':
        return 'ไม่พบผู้ใช้';
      case 'wrong-password':
      case 'invalid-credential':
        return 'รหัสผ่านไม่ถูกต้อง';
      case 'requires-recent-login':
        return 'กรุณา login ใหม่ก่อนเปลี่ยนรหัสผ่าน';
      default:
        return 'เกิดข้อผิดพลาด: ${e.message}';
    }
  }
}
