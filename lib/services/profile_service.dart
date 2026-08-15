import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

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

  Future<DocumentSnapshot<Map<String, dynamic>>>
  getUserProfile() async {
    final uid = currentUserId;

    if (uid == null) {
      throw Exception(
        'User is not logged in.',
      );
    }

    return await _firestore
        .collection('users')
        .doc(uid)
        .get();
  }

  // =========================================================
  // CREATE PROFILE
  // =========================================================

  Future<void> createProfile({
    required String username,
    required String fullName,
    String phone = '',
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'User is not logged in.',
      );
    }

    final profileRef = _firestore
        .collection('users')
        .doc(user.uid);

    final existingProfile =
    await profileRef.get();

    // Profile already exists.
    if (existingProfile.exists) {
      return;
    }

    await profileRef.set({
      'uid': user.uid,
      'username': username.trim(),
      'fullName': fullName.trim(),
      'email': user.email ?? '',
      'phone': phone.trim(),
      'role': 'user',
      'createdAt':
      FieldValue.serverTimestamp(),
      'updatedAt':
      FieldValue.serverTimestamp(),
    });
  }

  // =========================================================
  // UPDATE PROFILE
  // =========================================================

  Future<void> updateProfile({
    required String username,
    required String fullName,
    required String phone,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'User is not logged in.',
      );
    }

    final cleanUsername =
    username.trim();

    final cleanFullName =
    fullName.trim();

    final cleanPhone =
    phone.trim();

    // -------------------------------------------------------
    // VALIDATION
    // -------------------------------------------------------

    if (cleanUsername.isEmpty) {
      throw Exception(
        'Username cannot be empty.',
      );
    }

    if (cleanFullName.isEmpty) {
      throw Exception(
        'Full name cannot be empty.',
      );
    }

    // -------------------------------------------------------
    // UPDATE FIRESTORE
    // -------------------------------------------------------

    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(
      {
        'uid': user.uid,
        'username': cleanUsername,
        'fullName': cleanFullName,
        'email': user.email ?? '',
        'phone': cleanPhone,
        'updatedAt':
        FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    // -------------------------------------------------------
    // UPDATE FIREBASE AUTH DISPLAY NAME
    // -------------------------------------------------------

    if (user.displayName !=
        cleanFullName) {
      await user.updateDisplayName(
        cleanFullName,
      );
    }
  }
}