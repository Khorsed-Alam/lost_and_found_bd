import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  // Supabase client
  final SupabaseClient client = Supabase.instance.client;

  // ------------------------------------------------------------
  // Test Supabase connection
  // ------------------------------------------------------------

  Future<void> testConnection() async {
    try {
      final response = await client
          .from('test_connection')
          .select();

      debugPrint('====================================');
      debugPrint('✅ SUPABASE DATABASE CONNECTED');
      debugPrint('Response: $response');
      debugPrint('====================================');
    } catch (e) {
      debugPrint('====================================');
      debugPrint('❌ SUPABASE DATABASE ERROR');
      debugPrint(e.toString());
      debugPrint('====================================');
    }
  }
}
