import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // =========================================================
  // CURRENT USER
  // =========================================================

  User? get currentUser {
    return _auth.currentUser;
  }

  // =========================================================
  // CURRENT USER UID
  // =========================================================

  String? get currentUserId {
    return _auth.currentUser?.uid;
  }

  // =========================================================
  // GET CURRENT USER PROFILE
  // =========================================================

  Future<DocumentSnapshot<Map<String, dynamic>>> getUserProfile() async {
    final uid = currentUserId;

    if (uid == null) {
      throw Exception('User is not logged in.');
    }

    return await _firestore.collection('users').doc(uid).get();
  }

  // =========================================================
  // STREAM CURRENT USER PROFILE
  // =========================================================

  Stream<DocumentSnapshot<Map<String, dynamic>>> streamUserProfile() {
    final uid = currentUserId;
    if (uid == null) {
      return const Stream.empty();
    }
    return _firestore.collection('users').doc(uid).snapshots();
  }

  // =========================================================
  // CREATE PROFILE
  // =========================================================

  Future<void> createProfile({
    required String username,
    required String fullName,
    String phone = '',
    String? photoUrl,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User is not logged in.');
    }

    final profileRef = _firestore.collection('users').doc(user.uid);
    final existingProfile = await profileRef.get();

    if (existingProfile.exists) {
      return;
    }

    await profileRef.set({
      'uid': user.uid,
      'username': username.trim(),
      'fullName': fullName.trim(),
      'name': fullName.trim(),
      'email': user.email ?? '',
      'phone': phone.trim(),
      'photoUrl': photoUrl ?? user.photoURL ?? '',
      'role': 'user',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // =========================================================
  // UPDATE PROFILE
  // =========================================================

  Future<void> updateProfile({
    required String username,
    required String fullName,
    required String phone,
    String? photoUrl,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User is not logged in.');
    }

    final cleanUsername = username.trim();
    final cleanFullName = fullName.trim();
    final cleanPhone = phone.trim();

    if (cleanUsername.isEmpty) {
      throw Exception('Username cannot be empty.');
    }

    if (cleanFullName.isEmpty) {
      throw Exception('Full name cannot be empty.');
    }

    final Map<String, dynamic> updateData = {
      'uid': user.uid,
      'username': cleanUsername,
      'fullName': cleanFullName,
      'name': cleanFullName,
      'email': user.email ?? '',
      'phone': cleanPhone,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (photoUrl != null && photoUrl.isNotEmpty) {
      updateData['photoUrl'] = photoUrl;
    }

    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(updateData, SetOptions(merge: true));

    if (user.displayName != cleanFullName) {
      await user.updateDisplayName(cleanFullName);
    }
    if (photoUrl != null && photoUrl.isNotEmpty && user.photoURL != photoUrl) {
      await user.updatePhotoURL(photoUrl);
    }
  }

  // =========================================================
  // UPDATE PROFILE PHOTO
  // =========================================================

  Future<void> updateProfilePhoto(String photoUrl) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User is not logged in.');
    }

    await _firestore.collection('users').doc(user.uid).set({
      'photoUrl': photoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await user.updatePhotoURL(photoUrl);
  }
}