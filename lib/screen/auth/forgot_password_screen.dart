import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends State<ForgotPasswordScreen> {
  final emailController = TextEditingController();

  final authService = AuthService();

  bool loading = false;

  Future<void> resetPassword() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      showMessage('Enter your email.');
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      await authService.resetPassword(email);

      showMessage(
        'Password reset email sent. Check your inbox.',
      );
    } on FirebaseAuthException catch (e) {
      showMessage(
        e.message ?? 'Could not send reset email.',
      );
    } catch (e) {
      showMessage(
        'Could not send reset email: $e',
      );
    }

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.lock_reset,
              size: 70,
            ),

            const SizedBox(height: 20),

            const Text(
              'Enter your email address and we will '
                  'send you a password reset link.',
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            TextField(
              controller: emailController,
              keyboardType:
              TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon:
                Icon(Icons.email_outlined),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed:
                loading ? null : resetPassword,
                child: loading
                    ? const CircularProgressIndicator()
                    : const Text('SEND RESET LINK'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
