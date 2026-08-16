import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'firebase_options.dart';
import 'screen/auth/login_screen.dart';
import 'screen/dashboard/dashboard_screen.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  // Flutter engine initialize
  WidgetsFlutterBinding.ensureInitialized();

  // ============================================================
  // FIREBASE INITIALIZATION
  // ============================================================

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ============================================================
  // SUPABASE INITIALIZATION
  // ============================================================

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.anonKey,
  );

  // ============================================================
  // START APP
  // ============================================================

  runApp(const LostFoundApp());
}


// ================================================================
// MAIN APP
// ================================================================

class LostFoundApp extends StatelessWidget {
  const LostFoundApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'Lost & Found',

      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
      ),

      home: const AuthGate(),
    );
  }
}


// ================================================================
// AUTH GATE
// ================================================================

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: AuthService().authStateChanges,

      builder: (context, snapshot) {

        // --------------------------------------------------------
        // Loading
        // --------------------------------------------------------

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }


        // --------------------------------------------------------
        // User logged in
        // --------------------------------------------------------

        if (snapshot.hasData) {
          return const DashboardScreen();
        }


        // --------------------------------------------------------
        // User not logged in
        // --------------------------------------------------------

        return const LoginScreen();
      },
    );
  }
}
