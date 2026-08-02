import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../models/profile_model.dart';

/// Stream status autentikasi Supabase (login/logout).
final authStateProvider = StreamProvider<AuthState>((ref) {
  return SupabaseService.instance.auth.onAuthStateChange;
});

/// User Supabase yang sedang login (null bila belum login).
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.value?.session?.user ?? SupabaseService.instance.currentUser;
});

/// Profil lengkap (termasuk role: jobseeker/recruiter) dari tabel `profiles`.
final currentProfileProvider = FutureProvider<ProfileModel?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  final data = await SupabaseService.instance.getProfile(user.id);
  if (data == null) return null;
  return ProfileModel.fromJson(data);
});

/// Notifier sederhana untuk aksi auth (sign in/up/out) dengan status loading & error.
class AuthController extends StateNotifier<AsyncValue<void>> {
  AuthController() : super(const AsyncValue.data(null));

  Future<bool> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await SupabaseService.instance.signIn(email: email, password: password);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> signUp(
    String email,
    String password,
    String name,
    String role, {
    String companyName = '',
  }) async {
    state = const AsyncValue.loading();
    try {
      final res = await SupabaseService.instance
          .signUp(email: email, password: password, name: name, role: role);
      final uid = res.user?.id;
      if (uid != null) {
        // Jangan sampai kegagalan di sini menggagalkan signUp yang sudah
        // berhasil di sisi Auth — profil masih bisa dibuat ulang nanti.
        try {
          await SupabaseService.instance.upsertProfile(
            uid,
            email: email,
            name: name,
            role: role,
            companyName: companyName,
          );
        } catch (_) {}
      }
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> signOut() async {
    await SupabaseService.instance.signOut();
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) => AuthController());
