import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/user_services.dart';

class OTPScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;

  const OTPScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
  });

  @override
  State<OTPScreen> createState() =>
      _OTPScreenState();
}

class _OTPScreenState
    extends State<OTPScreen> {
  final TextEditingController otpController =
  TextEditingController();

  final AuthService authService =
  AuthService();

  bool loading = false;

  @override
  void dispose() {
    otpController.dispose();
    super.dispose();
  }

  // =========================================================
  // VERIFY OTP
  // =========================================================

  Future<void> verifyOTP() async {
    final String otp =
    otpController.text.trim();

    if (otp.isEmpty) {
      showMessage(
        'Please enter the OTP.',
      );
      return;
    }

    if (otp.length != 6) {
      showMessage(
        'OTP must contain 6 digits.',
      );
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      final credential = await authService.verifyOTP(
        verificationId:
        widget.verificationId,
        smsCode: otp,
      );

      if (credential.user != null) {
        final userService = UserService();
        final profile = await userService.getUserProfile(credential.user!.uid);
        if (profile == null) {
          await userService.createUserProfile(
            UserModel(
              uid: credential.user!.uid,
              name: 'User',
              email: '',
              phone: widget.phoneNumber,
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

      // Go back to the first screen.
      // AuthGate will detect the logged-in
      // Firebase user and show Dashboard.
      Navigator.popUntil(
        context,
            (route) => route.isFirst,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      showMessage(
        'Invalid OTP. Please check the code and try again.',
      );
    }
  }

  // =========================================================
  // MESSAGE
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
          'Verify OTP',
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
                  const Icon(
                    Icons.verified_user_rounded,
                    size: 80,
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'Verify Your Number',
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

                  Text(
                    'Enter the 6-digit code sent to\n'
                        '${widget.phoneNumber}',
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 32),

                  TextField(
                    controller:
                    otpController,

                    keyboardType:
                    TextInputType.number,

                    enabled: !loading,

                    maxLength: 6,

                    textAlign:
                    TextAlign.center,

                    style: const TextStyle(
                      fontSize: 24,
                      letterSpacing: 8,
                    ),

                    decoration:
                    const InputDecoration(
                      labelText: 'OTP',
                      hintText: '123456',
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    height: 52,

                    child: FilledButton(
                      onPressed:
                      loading
                          ? null
                          : verifyOTP,

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
                        'VERIFY OTP',
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