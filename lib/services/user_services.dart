import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  Future<void> createUserProfile(
      UserModel user,
      ) async {
    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(
      user.toMap(),
      SetOptions(merge: true),
    );
  }

  Future<UserModel?> getUserProfile(
      String uid,
      ) async {
    final doc = await _firestore
        .collection('users')
        .doc(uid)
        .get();

    if (!doc.exists) {
      return null;
    }

    return UserModel.fromMap(
      doc.data()!,
    );
  }

  Future<void> updateUserProfile(
      String uid,
      Map<String, dynamic> data,
      ) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .update(data);
  }
}