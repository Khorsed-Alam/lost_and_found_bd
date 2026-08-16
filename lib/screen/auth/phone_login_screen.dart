import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/user_services.dart';
import 'otp_screen.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() =>
      _PhoneLoginScreenState();
}

class _PhoneLoginScreenState
    extends State<PhoneLoginScreen> {
  final TextEditingController phoneController =
  TextEditingController();

  final AuthService authService =
  AuthService();

  bool loading = false;

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  // =========================================================
  // SEND OTP
  // =========================================================

  Future<void> sendOTP() async {
    final String phone =
    phoneController.text.trim();

    // Empty check
    if (phone.isEmpty) {
      showMessage(
        'Please enter your phone number.',
      );
      return;
    }

    // International format check
    if (!phone.startsWith('+')) {
      showMessage(
        'Please use international format.\n'
            'Example: +8801XXXXXXXXX',
      );
      return;
    }

    // Basic length check
    if (phone.length < 10) {
      showMessage(
        'Please enter a valid phone number.',
      );
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      await authService.sendPhoneOTP(
        phoneNumber: phone,

        // ===================================================
        // OTP SENT
        // ===================================================

        onCodeSent: (
            String verificationId,
            ) {
          if (!mounted) return;

          setState(() {
            loading = false;
          });

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) {
                return OTPScreen(
                  verificationId:
                  verificationId,
                  phoneNumber: phone,
                );
              },
            ),
          );
        },

        // ===================================================
        // VERIFICATION FAILED
        // ===================================================

        onVerificationFailed: (
            FirebaseAuthException error,
            ) {
          if (!mounted) return;

          setState(() {
            loading = false;
          });

          String message =
              'Phone verification failed.';

          if (error.code ==
              'invalid-phone-number') {
            message =
            'The phone number is invalid.';
          } else if (error.code ==
              'too-many-requests') {
            message =
            'Too many requests. Please try again later.';
          } else if (error.code ==
              'quota-exceeded') {
            message =
            'SMS quota exceeded. Please try again later.';
          } else if (error.message != null) {
            message = error.message!;
          }

          showMessage(message);
        },

        // ===================================================
        // AUTOMATIC VERIFICATION
        // ===================================================

        onVerificationCompleted: (
            PhoneAuthCredential credential,
            ) async {
          try {
            final userCredential = await FirebaseAuth.instance
                .signInWithCredential(
              credential,
            );

            if (userCredential.user != null) {
              final userService = UserService();
              final profile = await userService.getUserProfile(userCredential.user!.uid);
              if (profile == null) {
                await userService.createUserProfile(
                  UserModel(
                    uid: userCredential.user!.uid,
                    name: 'User',
                    email: '',
                    phone: phone,
                  ),
                );
              }
            }

            if (!mounted) return;

            setState(() {
              loading = false;
            });

            showMessage(
              'Phone verification successful.',
            );

            // AuthGate will automatically
            // take the user to Dashboard.
          } catch (e) {
            if (!mounted) return;

            setState(() {
              loading = false;
            });

            showMessage(
              'Automatic verification failed.',
            );
          }
        },

        // ===================================================
        // AUTO RETRIEVAL TIMEOUT
        // ===================================================

        onCodeAutoRetrievalTimeout: (
            String verificationId,
            ) {
          if (!mounted) return;

          setState(() {
            loading = false;
          });
        },
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      showMessage(
        'Something went wrong: $e',
      );
    }
  }

  // =========================================================
  // SHOW MESSAGE
  // =========================================================

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // =========================================================
  // UI
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Phone Login',
        ),
      ),

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),

            child: ConstrainedBox(
              constraints:
              const BoxConstraints(
                maxWidth: 430,
              ),

              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.stretch,

                children: [
                  // =================================================
                  // ICON
                  // =================================================

                  const Icon(
                    Icons.phone_android_rounded,
                    size: 80,
                  ),

                  const SizedBox(height: 24),

                  // =================================================
                  // TITLE
                  // =================================================

                  Text(
                    'Login with Phone',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // =================================================
                  // DESCRIPTION
                  // =================================================

                  Text(
                    'Enter your phone number and '
                        'we will send you a verification code.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium,
                  ),

                  const SizedBox(height: 32),

                  // =================================================
                  // PHONE INPUT
                  // =================================================

                  TextField(
                    controller:
                    phoneController,

                    keyboardType:
                    TextInputType.phone,

                    enabled: !loading,

                    decoration:
                    const InputDecoration(
                      labelText:
                      'Phone Number',

                      hintText:
                      '+8801XXXXXXXXX',

                      prefixIcon:
                      Icon(
                        Icons.phone,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Example: +8801712345678',
                    style: TextStyle(
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // =================================================
                  // SEND OTP BUTTON
                  // =================================================

                  SizedBox(
                    height: 52,

                    child: FilledButton(
                      onPressed:
                      loading
                          ? null
                          : sendOTP,

                      child: loading
                          ? const SizedBox(
                        width: 22,
                        height: 22,
                        child:
                        CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                          : const Text(
                        'SEND OTP',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}