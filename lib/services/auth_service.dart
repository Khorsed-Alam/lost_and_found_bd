import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Google Sign In (lazy initialization for cross-platform stability)
  GoogleSignIn? _googleSignInInstance;
  GoogleSignIn get _googleSignIn => _googleSignInInstance ??= GoogleSignIn(
    // The Web Client ID from google-services.json (client_type: 3)
    // This is required to prevent ApiException 10 on Android.
    serverClientId: '669507956172-rcemi5e7bvmnu5a0spefmqt1prvrbjg2.apps.googleusercontent.com',
  );

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
  // LOGOUT
  // =========================================================

  Future<void> logout() async {
    try {
      await _googleSignInInstance?.signOut();
    } catch (_) {
      // Ignore Google sign-out errors
    }

    await _auth.signOut();
  }
}
