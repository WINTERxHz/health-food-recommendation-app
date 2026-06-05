import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadProfileImage(String uid, File file) async {
    final ref = _storage.ref().child("profile_images/$uid.jpg");

    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<void> deleteProfileImage(String uid) async {
    await _storage.ref("profile_images/$uid.jpg").delete();
  }
}
