import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Google Sign In
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // =========================================================
  // CURRENT USER
  // =========================================================

  User? get currentUser {
    return _auth.currentUser;
  }

  // =========================================================
  // AUTH STATE
  // =========================================================

  Stream<User?> get authStateChanges {
    return _auth.authStateChanges();
  }

  // =========================================================
  // EMAIL REGISTER
  // =========================================================

  Future<UserCredential> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    final UserCredential credential =
    await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    // Save display name in Firebase Authentication
    await credential.user?.updateDisplayName(
      name.trim(),
    );

    return credential;
  }

  // =========================================================
  // EMAIL LOGIN
  // =========================================================

  Future<UserCredential> loginWithEmail({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // =========================================================
  // FORGOT PASSWORD
  // =========================================================

  Future<void> resetPassword(
      String email,
      ) async {
    await _auth.sendPasswordResetEmail(
      email: email.trim(),
    );
  }

  // =========================================================
  // GOOGLE LOGIN
  // =========================================================

  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Open Google account selection
      final GoogleSignInAccount? googleUser =
      await _googleSignIn.signIn();

      // User cancelled Google login
      if (googleUser == null) {
        return null;
      }

      // Get Google authentication
      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      // Create Firebase credential
      final AuthCredential credential =
      GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final UserCredential userCredential =
      await _auth.signInWithCredential(
        credential,
      );

      return userCredential;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw Exception(
        'Google Sign-In failed: $e',
      );
    }
  }

  // =========================================================
  // SEND PHONE OTP
  // =========================================================

  Future<void> sendPhoneOTP({
    required String phoneNumber,

    required void Function(
        String verificationId,
        ) onCodeSent,

    required void Function(
        FirebaseAuthException error,
        ) onVerificationFailed,

    required void Function(
        PhoneAuthCredential credential,
        ) onVerificationCompleted,

    required void Function(
        String verificationId,
        ) onCodeAutoRetrievalTimeout,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,

      verificationCompleted:
      onVerificationCompleted,

      verificationFailed:
      onVerificationFailed,

      codeSent: (
          String verificationId,
          int? resendToken,
          ) {
        onCodeSent(
          verificationId,
        );
      },

      codeAutoRetrievalTimeout:
      onCodeAutoRetrievalTimeout,
    );
  }

  // =========================================================
  // VERIFY OTP
  // =========================================================

  Future<UserCredential> verifyOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    final PhoneAuthCredential credential =
    PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );

    return await _auth.signInWithCredential(
      credential,
    );
  }
// =========================================================
// DELETE USER PROFILE
// =========================================================

  Future<void> deleteUserProfile() async {
    final User? user = _auth.currentUser;

    if (user == null) {
      throw Exception('No user is currently logged in.');
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .delete();
  }

// =========================================================
// DELETE FIREBASE ACCOUNT
// =========================================================

  Future<void> deleteAccount() async {
    final User? user = _auth.currentUser;

    if (user == null) {
      throw Exception('No user is currently logged in.');
    }

    // First delete Firestore data
    await deleteUserProfile();

    // Then delete Firebase Auth account
    await user.delete();
  }
  // =========================================================
  // LOGOUT
  // =========================================================

  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Ignore Google sign-out errors
    }

    await _auth.signOut();
  }
}