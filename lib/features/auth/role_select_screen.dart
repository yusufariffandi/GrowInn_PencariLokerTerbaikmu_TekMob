import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/glass_widgets.dart';
import '../../shared/widgets/admin_image.dart';
import '../profile/help_screen.dart' show HelpFaqData;

/// Halaman depan (landing) sebelum login — hero foto besar + CTA,
/// kartu fitur, dan FAQ singkat, bertema hitam-putih ("Mono Glass").
/// Titik cabang: pengguna memilih Karyawan atau Rekruter, masing-masing
/// punya alur login & signup terpisah total.
class RoleSelectScreen extends StatefulWidget {
  const RoleSelectScreen({super.key});

  @override
  State<RoleSelectScreen> createState() => _RoleSelectScreenState();
}

class _RoleSelectScreenState extends State<RoleSelectScreen> {
  int _openFaq = -1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MeshBackground(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _buildHero(context),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pilih peran kamu', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 6),
                    const Text(
                      'Alur masuk untuk Karyawan dan Rekruter dibuat terpisah total.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
                    ),
                    const SizedBox(height: 18),
                    _RoleCard(
                      title: 'Saya Karyawan',
                      subtitle: 'Cari kerja, kelola CV, dan lamar dengan mudah',
                      icon: Icons.person_search_rounded,
                      onTap: () => context.push('/login/jobseeker'),
                    ),
                    const SizedBox(height: 14),
                    _RoleCard(
                      title: 'Saya Rekruter',
                      subtitle: 'Pasang lowongan, kelola kandidat, chat pelamar',
                      icon: Icons.business_center_rounded,
                      onTap: () => context.push('/login/recruiter'),
                    ),
                    const SizedBox(height: 36),
                    Text('Kenapa GrowIn', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 4),
                    const Text(
                      'Satu aplikasi untuk seluruh perjalanan kariermu.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              _buildFeatureCards(),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 36, 24, 0),
                child: Text('Pertanyaan Umum', style: Theme.of(context).textTheme.headlineMedium),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: List.generate(HelpFaqData.landingPreview.length, (i) {
                    final faq = HelpFaqData.landingPreview[i];
                    final open = _openFaq == i;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GlassPane(
                        borderRadius: 18,
                        child: InkWell(
                          onTap: () => setState(() => _openFaq = open ? -1 : i),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(faq.$1,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700, fontSize: 14)),
                                  ),
                                  Icon(open ? Icons.remove_rounded : Icons.add_rounded,
                                      color: AppColors.black),
                                ],
                              ),
                              if (open) ...[
                                const SizedBox(height: 8),
                                Text(faq.$2,
                                    style: const TextStyle(
                                        color: AppColors.textSecondary, fontSize: 12.5, height: 1.5)),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    return SizedBox(
      height: 380,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const AdminManagedImage(
            imageKey: 'landing_hero',
            fallbackIcon: Icons.work_outline_rounded,
          ),
          // Gradasi gelap tipis di bawah supaya teks tetap terbaca di atas foto.
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xCC000000)],
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            top: 20,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: const Center(
                    child: Text('G',
                        style: TextStyle(
                            color: AppColors.black, fontSize: 18, fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(width: 10),
                const Text('GrowIn',
                    style: TextStyle(
                        color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Lebih Cepat & Efisien',
                    style: TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                const Text(
                  'Tumbuh Karier,\nSatu Langkah Lagi.',
                  style: TextStyle(
                      color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800, height: 1.15),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: 190,
                  child: ElevatedButton(
                    onPressed: () => context.push('/login/jobseeker'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.black,
                    ),
                    child: const Text('Mulai Sekarang'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCards() {
    const cards = [
      (
        'feature_card_1',
        'Lowongan Terverifikasi',
        'Ribuan lowongan dari perusahaan yang sudah diverifikasi.'
      ),
      (
        'feature_card_2',
        'CV & Surat Lamaran',
        'Bangun CV dan surat lamaran profesional dalam hitungan menit.'
      ),
      (
        'feature_card_3',
        'Chat Langsung Rekruter',
        'Diskusi langsung dengan rekruter lewat chat dalam aplikasi.'
      ),
    ];
    return SizedBox(
      height: 228,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        itemBuilder: (c, i) {
          final card = cards[i];
          return Padding(
            padding: const EdgeInsets.only(right: 14),
            child: SizedBox(
              width: 160,
              child: GlassPane(
                borderRadius: 20,
                padding: EdgeInsets.zero,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 90,
                      width: double.infinity,
                      child: AdminManagedImage(
                        imageKey: card.$1,
                        fallbackIcon: Icons.check_circle_outline_rounded,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(card.$2,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text(card.$3,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: AppColors.textSecondary, fontSize: 11, height: 1.3)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  const _RoleCard(
      {required this.title, required this.subtitle, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: GlassPane(
        borderRadius: 24,
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                  color: AppColors.black, borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
