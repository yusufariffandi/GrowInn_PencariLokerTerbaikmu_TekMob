import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/glass_widgets.dart';

/// Data FAQ dibagi bersama antara halaman Bantuan (lengkap) dan halaman
/// depan/landing sebelum login (versi pendek, 3 pertanyaan pertama).
class HelpFaqData {
  HelpFaqData._();

  static const List<(String, String)> all = [
    (
      'Bagaimana cara membuat CV di GrowIn?',
      'Buka menu AI Tools atau shortcut "Buat CV" di Home, isi data diri, '
          'pendidikan, dan pengalamanmu, lalu CV siap diunduh dalam format PDF.',
    ),
    (
      'Apakah fitur AI GrowIn gratis?',
      'Ya, semua fitur AI GrowIn (CV Generator, Surat Lamaran, Kalkulator Gaji) '
          'dapat digunakan tanpa biaya tambahan selama masa uji coba.',
    ),
    (
      'Bagaimana cara melamar pekerjaan?',
      'Buka detail lowongan yang kamu minati, lalu tekan tombol "Lamar Sekarang" '
          'dan lengkapi data yang diminta.',
    ),
    (
      'Bagaimana melacak status lamaran saya?',
      'Gunakan menu "Application Tracker" di halaman Profil untuk melihat '
          'status setiap lamaran yang sudah kamu kirim.',
    ),
    (
      'Bagaimana cara mengubah data profil?',
      'Masuk ke halaman Profil, tekan "Edit Profil", ubah data yang diperlukan, '
          'lalu simpan perubahan.',
    ),
  ];

  /// Ditampilkan di halaman depan (sebelum login) — cukup 3 pertama.
  static List<(String, String)> get landingPreview => all.take(3).toList();
}

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _faqs = HelpFaqData.all;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: MeshBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                    ),
                    const Text('Bantuan',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
                  children: [
                    GlassPane(
                      borderRadius: 22,
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                  colors: [AppColors.primary, AppColors.primaryContainer]),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.support_agent_rounded,
                                color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Text(
                              'Butuh bantuan lebih lanjut? Tim GrowIn siap membantu.',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Pertanyaan Umum',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    ..._faqs.map((f) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GlassPane(
                            borderRadius: 18,
                            child: ExpansionTile(
                              tilePadding: EdgeInsets.zero,
                              childrenPadding: EdgeInsets.zero,
                              shape: const Border(),
                              title: Text(f.$1,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700, fontSize: 13.5)),
                              children: [
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(f.$2,
                                      style: const TextStyle(
                                          color: AppColors.textSecondary, fontSize: 12.5, height: 1.4)),
                                ),
                              ],
                            ),
                          ),
                        )),
                    const SizedBox(height: 8),
                    const Text('Hubungi Kami',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    GlassPane(
                      borderRadius: 18,
                      child: Column(
                        children: const [
                          _ContactRow(icon: Icons.email_outlined, text: 'support@growin.id'),
                          SizedBox(height: 12),
                          _ContactRow(icon: Icons.chat_bubble_outline_rounded, text: 'Live chat (09.00–21.00 WIB)'),
                          SizedBox(height: 12),
                          _ContactRow(icon: Icons.language_rounded, text: 'growin.id/bantuan'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _ContactRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
