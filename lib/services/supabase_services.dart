import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class SupabaseService {
  // Supabase client
  final SupabaseClient client = Supabase.instance.client;

  // ============================================================
  // UPLOAD IMAGE GENERIC
  // ============================================================

  Future<String> uploadImage({
    required Uint8List bytes,
    required String filePath,
    String contentType = 'image/jpeg',
  }) async {
    try {
      await client.storage.from(SupabaseConfig.storageBucket).uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(
              contentType: contentType,
              upsert: true,
            ),
          );

      final String publicUrl = client.storage
          .from(SupabaseConfig.storageBucket)
          .getPublicUrl(filePath);

      // Append cache buster to prevent stale cache when updated
      final String freshUrl = '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';
      debugPrint('✅ Image uploaded successfully: $freshUrl');
      return freshUrl;
    } catch (e) {
      debugPrint('❌ Supabase Upload Error: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  // ============================================================
  // UPLOAD PROFILE AVATAR
  // ============================================================

  Future<String> uploadProfileAvatar({
    required String uid,
    required Uint8List bytes,
    String extension = 'jpg',
  }) async {
    final String cleanExt = extension.replaceAll('.', '').toLowerCase();
    final String contentType = cleanExt == 'png'
        ? 'image/png'
        : cleanExt == 'webp'
            ? 'image/webp'
            : 'image/jpeg';

    final String filePath =
        '${SupabaseConfig.profileImagesFolder}/${uid}_avatar.$cleanExt';

    return await uploadImage(
      bytes: bytes,
      filePath: filePath,
      contentType: contentType,
    );
  }

  // ============================================================
  // DELETE IMAGE
  // ============================================================

  Future<void> deleteImage(String filePath) async {
    try {
      await client.storage
          .from(SupabaseConfig.storageBucket)
          .remove([filePath]);
      debugPrint('✅ Image deleted: $filePath');
    } catch (e) {
      debugPrint('⚠️ Supabase Delete Error: $e');
    }
  }

  // ============================================================
  // TEST CONNECTION
  // ============================================================

  Future<void> testConnection() async {
    try {
      final response = await client.from('test_connection').select();
      debugPrint('====================================');
      debugPrint('✅ SUPABASE DATABASE CONNECTED');
      debugPrint('Response: $response');
      debugPrint('====================================');
    } catch (e) {
      debugPrint('====================================');
      debugPrint('❌ SUPABASE DATABASE ERROR: $e');
      debugPrint('====================================');
    }
  }
}
