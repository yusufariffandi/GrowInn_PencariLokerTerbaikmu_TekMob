import 'package:supabase_flutter/supabase_flutter.dart';

/// Menerjemahkan error dari Supabase Auth (signUp/signIn) menjadi pesan
/// yang sesuai dengan penyebab aslinya — bukan asal ditebak "email sudah
/// terdaftar" untuk semua jenis kegagalan.
String friendlyAuthError(Object? error, {required String action}) {
  if (error == null) return 'Terjadi kesalahan yang tidak diketahui.';

  final raw = error is AuthException ? error.message : error.toString();
  final msg = raw.toLowerCase();

  if (msg.contains('already registered') || msg.contains('already exists') || msg.contains('user already')) {
    return 'Email ini sudah terdaftar. Coba masuk (login) atau gunakan email lain.';
  }
  if (msg.contains('rate limit') || msg.contains('too many requests') || msg.contains('429')) {
    return 'Terlalu banyak percobaan dalam waktu singkat. Tunggu beberapa menit lalu coba lagi.';
  }
  if (msg.contains('error sending confirmation') || msg.contains('error sending email') || msg.contains('smtp')) {
    return 'Akun mungkin berhasil dibuat, tapi email konfirmasi gagal dikirim (SMTP Supabase belum '
        'dikonfigurasi). Cek Authentication > Providers > Email di dashboard Supabase.';
  }
  if (msg.contains('password') && (msg.contains('weak') || msg.contains('short') || msg.contains('least'))) {
    return 'Kata sandi tidak memenuhi syarat minimum dari Supabase. Coba kata sandi yang lebih panjang/kuat.';
  }
  if (msg.contains('invalid email') || msg.contains('unable to validate email')) {
    return 'Format email tidak valid.';
  }
  if (msg.contains('network') || msg.contains('socket') || msg.contains('failed host lookup')) {
    return 'Tidak bisa terhubung ke server. Cek koneksi internet kamu.';
  }
  if (msg.contains('database error') || msg.contains('unexpected_failure') || msg.contains('saving new user')) {
    return 'Server gagal menyimpan akun baru (kemungkinan ada masalah trigger/RLS di tabel profiles). '
        'Cek Logs > Auth di dashboard Supabase untuk detail.';
  }

  // Fallback: tampilkan pesan asli apa adanya supaya tetap bisa didiagnosis,
  // daripada menyembunyikannya di balik pesan generik yang belum tentu benar.
  return '$action gagal: $raw';
}
