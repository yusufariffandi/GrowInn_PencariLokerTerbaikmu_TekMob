import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_provider.dart';
import '../../shared/widgets/glass_widgets.dart';

class RecruiterHomeScreen extends ConsumerWidget {
  const RecruiterHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);

    return SafeArea(
      child: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('$e')),
        data: (profile) {
          final recruiterId = profile?.id ?? '';
          final jobsAsync = ref.watch(recruiterJobsProvider(recruiterId));

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Dashboard Rekruter',
                            style: TextStyle(color: AppColors.textSecondary)),
                        Text(
                          profile?.companyName.isNotEmpty == true
                              ? profile!.companyName
                              : (profile?.name ?? 'Perusahaan'),
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                        ),
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
              const SizedBox(height: 20),
              jobsAsync.when(
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
                data: (jobs) {
                  final totalApplicants =
                      jobs.fold<int>(0, (sum, j) => sum + j.applicantsCount);
                  return Row(
                    children: [
                      Expanded(
                          child: _StatCard(
                              label: 'Lowongan Aktif', value: '${jobs.length}')),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _StatCard(
                              label: 'Total Pelamar', value: '$totalApplicants')),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              InkWell(
                onTap: () => context.push('/recruiter/post-job'),
                borderRadius: BorderRadius.circular(20),
                child: GlassPane(
                  borderRadius: 20,
                  tint: AppColors.black,
                  border: Border.all(color: AppColors.black),
                  child: const Row(
                    children: [
                      Icon(Icons.add_circle_rounded, color: Colors.white),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text('Pasang Lowongan Baru',
                            style: TextStyle(
                                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Lowongan Terbaru Kamu',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              jobsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Text('$e'),
                data: (jobs) {
                  if (jobs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                          child: Text('Belum ada lowongan. Yuk pasang lowongan pertama!',
                              style: TextStyle(color: AppColors.textSecondary))),
                    );
                  }
                  return Column(
                    children: jobs
                        .map((job) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: InkWell(
                                onTap: () => context.push('/recruiter/candidates/${job.id}'),
                                borderRadius: BorderRadius.circular(20),
                                child: GlassPane(
                                  borderRadius: 20,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(job.title,
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w700, fontSize: 14.5)),
                                            const SizedBox(height: 4),
                                            Text('${job.applicantsCount} pelamar · ${job.city}',
                                                style: const TextStyle(
                                                    color: AppColors.textSecondary, fontSize: 12.5)),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.chevron_right_rounded,
                                          color: AppColors.textSecondary),
                                    ],
                                  ),
                                ),
                              ),
                            ))
                        .toList(),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return GlassPane(
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
