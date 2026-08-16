import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/user_services.dart';
import 'forgot_password_screen.dart';
import 'phone_login_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() =>
      _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final authService = AuthService();

  bool loading = false;

  Future<void> login() async {
    if (emailController.text.trim().isEmpty ||
        passwordController.text.isEmpty) {
      showMessage('Please enter email and password.');
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      await authService.loginWithEmail(
        email: emailController.text,
        password: passwordController.text,
      );
    } on FirebaseAuthException catch (e) {
      showMessage(e.message ?? 'Login failed.');
    } catch (e) {
      showMessage('Login failed: $e');
    }

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> googleLogin() async {
    try {
      final credential = await authService.signInWithGoogle();
      if (credential != null && credential.user != null) {
        // Check if user exists in Firestore
        final userService = UserService();
        final profile = await userService.getUserProfile(credential.user!.uid);
        if (profile == null) {
          // Create new profile
          await userService.createUserProfile(
            UserModel(
              uid: credential.user!.uid,
              name: credential.user!.displayName ?? 'User',
              email: credential.user!.email ?? '',
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      showMessage(e.message ?? 'Google login failed.');
    } catch (e) {
      showMessage('Google login failed: $e');
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints:
              const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.search,
                    size: 70,
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'Lost & Found',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 30),

                  TextField(
                    controller: emailController,
                    keyboardType:
                    TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon:
                      Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon:
                      Icon(Icons.lock_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                            const ForgotPasswordScreen(),
                          ),
                        );
                      },
                      child:
                      const Text('Forgot Password?'),
                    ),
                  ),

                  const SizedBox(height: 8),

                  FilledButton(
                    onPressed:
                    loading ? null : login,
                    child: loading
                        ? const CircularProgressIndicator()
                        : const Text('LOGIN'),
                  ),

                  const SizedBox(height: 12),

                  OutlinedButton.icon(
                    onPressed: googleLogin,
                    icon: const Icon(
                      Icons.g_mobiledata,
                    ),
                    label:
                    const Text('Continue with Google'),
                  ),

                  const SizedBox(height: 12),

                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                          const PhoneLoginScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.phone),
                    label:
                    const Text('Login with Phone'),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.center,
                    children: [
                      const Text(
                          "Don't have an account?"),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                              const RegisterScreen(),
                            ),
                          );
                        },
                        child:
                        const Text('Register'),
                      ),
                    ],
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