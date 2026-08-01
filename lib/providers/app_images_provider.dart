import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/supabase_service.dart';

/// Peta semua gambar tampilan app yang bisa diganti lewat akun Admin,
/// contoh key: 'landing_hero', 'feature_card_1', 'feature_card_2',
/// 'feature_card_3'. Bila key belum diatur admin, value-nya '' (kosong)
/// dan UI akan pakai placeholder bawaan.
final appImagesProvider = FutureProvider<Map<String, String>>((ref) async {
  try {
    return await SupabaseService.instance.getAppImages();
  } catch (_) {
    return {};
  }
});
