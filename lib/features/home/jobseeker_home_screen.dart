import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_provider.dart';
import '../../services/supabase_service.dart';
import '../../shared/widgets/glass_widgets.dart';
import '../../shared/widgets/hero_carousel.dart';
import '../../shared/widgets/job_card.dart';

class JobseekerHomeScreen extends ConsumerStatefulWidget {
  const JobseekerHomeScreen({super.key});

  @override
  ConsumerState<JobseekerHomeScreen> createState() => _JobseekerHomeScreenState();
}

class _JobseekerHomeScreenState extends ConsumerState<JobseekerHomeScreen> {
  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentProfileProvider);
    final jobsAsync = ref.watch(jobListProvider);
    final savedIds = ref.watch(savedJobIdsProvider);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async => ref.invalidate(jobListProvider),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          children: [
            profileAsync.when(
              data: (p) => Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Halo,', style: TextStyle(color: AppColors.textSecondary)),
                        Text(p?.name.isNotEmpty == true ? p!.name : 'Karyawan',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.push('/notifications'),
                    icon: const Icon(Icons.notifications_none_rounded),
                    style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.5),
                        shape: const CircleBorder()),
                  ),
                ],
              ),
              loading: () => const SizedBox(height: 40),
              error: (_, __) => const SizedBox(),
            ),
            const SizedBox(height: 18),
            HeroCarousel(
              backgroundImageKey: 'jobseeker_hero',
              slides: const [
                HeroSlide(
                  eyebrow: 'GrowIn Insight',
                  title: 'Karier Bertumbuh,\nHidup Lebih Seimbang.',
                  subtitle: 'Temukan lowongan yang cocok dengan gaya hidupmu hari ini.',
                  icon: Icons.self_improvement_rounded,
                ),
                HeroSlide(
                  eyebrow: 'CV Builder',
                  title: 'CV Rapi Cuma\nDalam Hitungan Menit.',
                  subtitle: 'Isi sekali, pakai untuk lamar ke banyak perusahaan.',
                  icon: Icons.badge_rounded,
                ),
                HeroSlide(
                  eyebrow: 'Peta Lowongan',
                  title: 'Jelajahi Peluang\nDi Sekitarmu.',
                  subtitle: 'Lihat sebaran lowongan terbaru langsung dari peta.',
                  icon: Icons.map_rounded,
                ),
              ],
            ),
            const SizedBox(height: 18),
            GlassPane(
              borderRadius: 20,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                onChanged: (v) => ref.read(jobSearchQueryProvider.notifier).state = v,
                decoration: const InputDecoration(
                  hintText: 'Cari posisi, perusahaan...',
                  prefixIcon: Icon(Icons.search_rounded),
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _ShortcutTile(
                    icon: Icons.badge_outlined,
                    label: 'Buat CV',
                    onTap: () => context.push('/cv/list'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ShortcutTile(
                    icon: Icons.mail_outline_rounded,
                    label: 'Surat Lamaran',
                    onTap: () => context.push('/cover-letter/list'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ShortcutTile(
                    icon: Icons.map_rounded,
                    label: 'Peta Kerja',
                    onTap: () => context.push('/job-map'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Rekomendasi untukmu',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            jobsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, st) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text('Belum bisa memuat lowongan: $e',
                    style: const TextStyle(color: AppColors.textSecondary)),
              ),
              data: (jobs) {
                if (jobs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                        child: Text('Belum ada lowongan tersedia.',
                            style: TextStyle(color: AppColors.textSecondary))),
                  );
                }
                return Column(
                  children: jobs
                      .map((job) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: JobCard(
                              job: job,
                              isSaved: savedIds.contains(job.id),
                              onTap: () => context.push('/job/${job.id}'),
                              onBookmark: () async {
                                final uid = SupabaseService.instance.currentUserId;
                                if (uid == null) return;
                                final willSave = !savedIds.contains(job.id);
                                await SupabaseService.instance
                                    .toggleSaveJob(uid, job.id, willSave);
                                final next = {...savedIds};
                                willSave ? next.add(job.id) : next.remove(job.id);
                                ref.read(savedJobIdsProvider.notifier).state = next;
                              },
                            ),
                          ))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ShortcutTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ShortcutTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: GlassPane(
        borderRadius: 20,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: AppColors.black, size: 24),
            const SizedBox(height: 8),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
