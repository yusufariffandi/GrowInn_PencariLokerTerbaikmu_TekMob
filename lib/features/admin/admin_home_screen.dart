import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/app_images_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';
import '../../shared/widgets/glass_widgets.dart';
import '../../shared/widgets/admin_image.dart';

/// Daftar semua "slot" gambar yang dipakai di tampilan app dan bisa
/// diganti Admin. Tambahkan entri baru di sini kalau ada slot gambar
/// baru di layar lain.
const List<_ImageSlot> _kImageSlots = [
  _ImageSlot('landing_hero', 'Foto Hero Halaman Depan',
      'Foto besar di halaman selamat datang (sebelum login).'),
  _ImageSlot('jobseeker_hero', 'Foto Hero Beranda Pelamar',
      'Foto latar di kartu hero atas halaman Home setelah pelamar login.'),
  _ImageSlot('feature_card_1', 'Kartu Fitur 1', 'Foto kecil di kartu fitur pertama halaman depan.'),
  _ImageSlot('feature_card_2', 'Kartu Fitur 2', 'Foto kecil di kartu fitur kedua halaman depan.'),
  _ImageSlot('feature_card_3', 'Kartu Fitur 3', 'Foto kecil di kartu fitur ketiga halaman depan.'),
];

class _ImageSlot {
  final String key;
  final String label;
  final String description;
  const _ImageSlot(this.key, this.label, this.description);
}

class AdminHomeScreen extends ConsumerStatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  ConsumerState<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends ConsumerState<AdminHomeScreen> {
  String? _uploadingKey;

  Future<void> _pickAndUpload(String key) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    setState(() => _uploadingKey = key);
    try {
      final bytes = await picked.readAsBytes();
      final uid = SupabaseService.instance.currentUserId ?? 'admin';
      final ext = picked.path.split('.').last;
      final path = '$uid/${const Uuid().v4()}.$ext';
      final url = await SupabaseService.instance
          .uploadFile(bucket: 'app-images', path: path, bytes: bytes);
      await SupabaseService.instance.setAppImage(key, url);
      ref.invalidate(appImagesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Gambar berhasil diganti.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal upload: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploadingKey = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentProfileProvider);
    return profileAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, st) => Scaffold(body: Center(child: Text('$e'))),
      data: (profile) {
        if (profile == null || profile.role != 'admin') {
          WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/role-select'));
          return const Scaffold(body: SizedBox());
        }
        return _buildAdmin(context);
      },
    );
  }

  Widget _buildAdmin(BuildContext context) {
    return Scaffold(
      body: MeshBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('Kelola Tampilan',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                  ),
                  IconButton(
                    onPressed: () async {
                      await ref.read(authControllerProvider.notifier).signOut();
                      if (context.mounted) context.go('/role-select');
                    },
                    icon: const Icon(Icons.logout_rounded),
                    style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.5),
                        shape: const CircleBorder()),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Ganti gambar yang tampil di halaman depan aplikasi GrowIn untuk semua pengguna.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 20),
              ..._kImageSlots.map((slot) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: GlassPane(
                      borderRadius: 20,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 84,
                            height: 84,
                            child: AdminManagedImage(
                              imageKey: slot.key,
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(slot.label,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700, fontSize: 14.5)),
                                const SizedBox(height: 3),
                                Text(slot.description,
                                    style: const TextStyle(
                                        color: AppColors.textSecondary, fontSize: 12)),
                                const SizedBox(height: 10),
                                SizedBox(
                                  height: 36,
                                  child: OutlinedButton.icon(
                                    onPressed: _uploadingKey == slot.key
                                        ? null
                                        : () => _pickAndUpload(slot.key),
                                    icon: _uploadingKey == slot.key
                                        ? const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(strokeWidth: 2))
                                        : const Icon(Icons.upload_rounded, size: 16),
                                    label: Text(_uploadingKey == slot.key
                                        ? 'Mengunggah...'
                                        : 'Ganti Gambar'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
