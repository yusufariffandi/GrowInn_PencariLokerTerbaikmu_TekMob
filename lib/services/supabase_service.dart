import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Wrapper tipis di atas Supabase client. Semua akses database & auth
/// di seluruh app GrowIn lewat sini agar mudah diaudit / ditest.
class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  SupabaseClient get client => Supabase.instance.client;
  GoTrueClient get auth => client.auth;
  User? get currentUser => client.auth.currentUser;
  String? get currentUserId => client.auth.currentUser?.id;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? '',
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    );
  }

  // ---------------- AUTH ----------------

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
    required String role, // 'jobseeker' | 'recruiter'
  }) {
    return auth.signUp(
      email: email,
      password: password,
      data: {'name': name, 'role': role},
    );
  }

  Future<AuthResponse> signIn({required String email, required String password}) {
    return auth.signInWithPassword(email: email, password: password);
  }

  /// Lapis pengaman kedua: buat/perbarui baris profil langsung dari Flutter
  /// setelah signUp berhasil, tidak murni bergantung pada trigger database
  /// (yang bisa gagal diam-diam karena RLS/search_path). Aman dipanggil
  /// berkali-kali karena pakai upsert.
  Future<void> upsertProfile(
    String userId, {
    required String email,
    required String name,
    required String role,
    String companyName = '',
  }) async {
    await client.from('profiles').upsert({
      'id': userId,
      'email': email,
      'name': name,
      'role': role,
      if (companyName.isNotEmpty) 'company_name': companyName,
    });
  }

  Future<void> signOut() => auth.signOut();

  Future<void> resetPassword(String email) => auth.resetPasswordForEmail(email);

  // ---------------- PROFILE ----------------

  Future<Map<String, dynamic>?> getProfile(String userId) async {
    final res = await client.from('profiles').select().eq('id', userId).maybeSingle();
    return res;
  }

  Future<void> updateProfile(String userId, Map<String, dynamic> data) async {
    await client.from('profiles').update(data).eq('id', userId);
  }

  // ---------------- JOBS ----------------

  Future<List<Map<String, dynamic>>> getJobs({String? city, String? query}) async {
    var builder = client.from('jobs').select().eq('is_active', true);
    if (city != null && city.isNotEmpty) builder = builder.eq('city', city);
    if (query != null && query.isNotEmpty) builder = builder.ilike('title', '%$query%');
    final res = await builder.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  Future<List<Map<String, dynamic>>> getJobsByRecruiter(String recruiterId) async {
    final res = await client
        .from('jobs')
        .select()
        .eq('recruiter_id', recruiterId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  Future<Map<String, dynamic>> postJob(Map<String, dynamic> jobData) async {
    final res = await client.from('jobs').insert(jobData).select().single();
    return res;
  }

  Future<Map<String, dynamic>> updateJob(String jobId, Map<String, dynamic> jobData) async {
    final res = await client.from('jobs').update(jobData).eq('id', jobId).select().single();
    return res;
  }

  // ---------------- APPLICATIONS ----------------

  Future<List<Map<String, dynamic>>> getMyApplications(String userId) async {
    final res = await client
        .from('applications')
        .select('*, jobs(*)')
        .eq('user_id', userId)
        .order('applied_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  Future<List<Map<String, dynamic>>> getApplicationsForJob(String jobId) async {
    final res = await client
        .from('applications')
        .select('*, profiles(*)')
        .eq('job_id', jobId)
        .order('applied_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  Future<void> applyToJob(Map<String, dynamic> applicationData) async {
    await client.from('applications').insert(applicationData);
    // Beritahu recruiter pemilik lowongan bahwa ada pelamar baru.
    try {
      final jobId = applicationData['job_id'];
      final job = await client.from('jobs').select('recruiter_id, title').eq('id', jobId).maybeSingle();
      if (job != null && job['recruiter_id'] != null) {
        await createNotification(
          userId: job['recruiter_id'],
          category: 'status',
          title: 'Pelamar baru',
          body: 'Ada pelamar baru untuk lowongan "${job['title'] ?? ''}".',
          actionUrl: '/recruiter/candidates/$jobId',
        );
      }
    } catch (_) {
      // Jangan sampai gagal kirim notifikasi menggagalkan proses lamaran.
    }
  }

  Future<void> updateApplicationStatus(String applicationId, String status) async {
    final app = await client
        .from('applications')
        .update({'status': status})
        .eq('id', applicationId)
        .select('user_id, job_id, jobs(title)')
        .maybeSingle();
    if (app != null && app['user_id'] != null) {
      try {
        final jobTitle = (app['jobs'] as Map?)?['title'] ?? 'lowongan';
        await createNotification(
          userId: app['user_id'],
          category: 'status',
          title: 'Status lamaran diperbarui',
          body: 'Status lamaranmu untuk "$jobTitle" kini: $status.',
          actionUrl: '/tracker',
        );
      } catch (_) {}
    }
  }

  // ---------------- SAVED JOBS ----------------

  Future<void> toggleSaveJob(String userId, String jobId, bool save) async {
    if (save) {
      await client.from('saved_jobs').insert({'user_id': userId, 'job_id': jobId});
    } else {
      await client.from('saved_jobs').delete().eq('user_id', userId).eq('job_id', jobId);
    }
  }

  Future<List<Map<String, dynamic>>> getSavedJobs(String userId) async {
    final res = await client.from('saved_jobs').select('*, jobs(*)').eq('user_id', userId);
    return List<Map<String, dynamic>>.from(res);
  }

  // ---------------- CVs ----------------

  Future<List<Map<String, dynamic>>> getMyCVs(String userId) async {
    final res = await client
        .from('cvs')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  Future<Map<String, dynamic>> saveCV(Map<String, dynamic> cvData) async {
    final res = await client.from('cvs').insert(cvData).select().single();
    return res;
  }

  /// Perbarui CV yang sudah tersimpan (dipakai saat mode edit dari CV List),
  /// agar tidak membuat baris baru setiap kali disimpan ulang.
  Future<Map<String, dynamic>> updateCV(String id, Map<String, dynamic> cvData) async {
    final res = await client.from('cvs').update(cvData).eq('id', id).select().single();
    return res;
  }

  Future<void> deleteCV(String id) async {
    await client.from('cvs').delete().eq('id', id);
  }

  // ---------------- COVER LETTERS ----------------

  Future<List<Map<String, dynamic>>> getMyCoverLetters(String userId) async {
    final res = await client
        .from('cover_letters')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  Future<Map<String, dynamic>> saveCoverLetter(Map<String, dynamic> data) async {
    final res = await client.from('cover_letters').insert(data).select().single();
    return res;
  }

  /// Perbarui surat lamaran yang sudah tersimpan (mode edit), agar tidak
  /// membuat baris baru setiap kali disimpan ulang.
  Future<Map<String, dynamic>> updateCoverLetter(String id, Map<String, dynamic> data) async {
    final res =
        await client.from('cover_letters').update(data).eq('id', id).select().single();
    return res;
  }

  Future<void> deleteCoverLetter(String id) async {
    await client.from('cover_letters').delete().eq('id', id);
  }

  // ---------------- MESSAGES ----------------

  Stream<List<Map<String, dynamic>>> messagesStream(String userId, String peerId) {
    return client
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .map((rows) => rows
            .where((r) =>
                (r['sender_id'] == userId && r['receiver_id'] == peerId) ||
                (r['sender_id'] == peerId && r['receiver_id'] == userId))
            .toList());
  }

  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String text,
    String attachmentUrl = '',
  }) async {
    await client.from('messages').insert({
      'sender_id': senderId,
      'receiver_id': receiverId,
      'text': text,
      'attachment_url': attachmentUrl,
    });
    try {
      final sender = await getProfile(senderId);
      await createNotification(
        userId: receiverId,
        category: 'message',
        title: 'Pesan baru dari ${sender?['name'] ?? 'seseorang'}',
        body: text,
        actionUrl: '/chat/$senderId',
      );
    } catch (_) {}
  }

  // ---------------- NOTIFICATIONS ----------------

  Stream<List<Map<String, dynamic>>> notificationsStream(String userId) {
    return client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((rows) => rows.where((r) => r['user_id'] == userId).toList());
  }

  Future<void> markNotificationRead(String id) async {
    await client.from('notifications').update({'is_read': true}).eq('id', id);
  }

  /// Helper umum untuk membuat notifikasi. Dipanggil otomatis saat:
  /// ada pelamar baru (untuk recruiter), status lamaran berubah (untuk
  /// jobseeker), dan ada pesan chat baru (untuk penerima).
  Future<void> createNotification({
    required String userId,
    required String title,
    String body = '',
    String category = 'tips',
    String actionUrl = '',
  }) async {
    await client.from('notifications').insert({
      'user_id': userId,
      'category': category,
      'title': title,
      'body': body,
      'action_url': actionUrl,
    });
  }

  // ---------------- APP IMAGES (dikelola admin) ----------------

  /// Ambil semua gambar tampilan app (key -> url) yang sudah diatur admin,
  /// contoh: 'landing_hero', 'feature_card_1', dst.
  Future<Map<String, String>> getAppImages() async {
    final res = await client.from('app_images').select('key, url');
    final map = <String, String>{};
    for (final r in List<Map<String, dynamic>>.from(res)) {
      map[r['key'] as String] = (r['url'] as String?) ?? '';
    }
    return map;
  }

  Future<void> setAppImage(String key, String url) async {
    await client.from('app_images').upsert({
      'key': key,
      'url': url,
      'updated_by': currentUserId,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  // ---------------- STORAGE ----------------

  Future<String> uploadFile({
    required String bucket,
    required String path,
    required Uint8List bytes,
  }) async {
    await client.storage
        .from(bucket)
        .uploadBinary(path, bytes, fileOptions: const FileOptions(upsert: true));
    return client.storage.from(bucket).getPublicUrl(path);
  }
}
