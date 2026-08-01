import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_provider.dart';
import '../../shared/widgets/glass_widgets.dart';

class RecruiterJobsScreen extends ConsumerWidget {
  const RecruiterJobsScreen({super.key});

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
          final existingJob = jobsAsync.maybeWhen(
            data: (jobs) => jobs.isNotEmpty ? jobs.first : null,
            orElse: () => null,
          );

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text('Lowongan Saya',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                    ),
                    InkWell(
                      onTap: () => context.push('/recruiter/post-job', extra: existingJob),
                      borderRadius: BorderRadius.circular(9999),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                            color: AppColors.black, shape: BoxShape.circle),
                        child: Icon(
                            existingJob != null ? Icons.edit_rounded : Icons.add_rounded,
                            color: Colors.white,
                            size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: jobsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, st) => Center(child: Text('$e')),
                  data: (jobs) {
                    if (jobs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.work_off_outlined,
                                size: 40, color: AppColors.textSecondary),
                            const SizedBox(height: 12),
                            const Text('Belum ada lowongan dipasang.',
                                style: TextStyle(color: AppColors.textSecondary)),
                            const SizedBox(height: 14),
                            OutlinedButton.icon(
                              onPressed: () => context.push('/recruiter/post-job'),
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text('Pasang Lowongan'),
                            ),
                            const SizedBox(height: 4),
                            const Text('Kamu bisa memasang 1 lowongan aktif.',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                      itemCount: jobs.length,
                      itemBuilder: (c, i) {
                        final job = jobs[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () => context.push('/recruiter/candidates/${job.id}'),
                            borderRadius: BorderRadius.circular(20),
                            child: GlassPane(
                              borderRadius: 20,
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                        color: AppColors.black,
                                        borderRadius: BorderRadius.circular(14)),
                                    child: Center(
                                      child: Text(
                                        job.title.isNotEmpty ? job.title[0].toUpperCase() : '?',
                                        style: const TextStyle(
                                            color: Colors.white, fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(job.title,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w700, fontSize: 14.5)),
                                        const SizedBox(height: 4),
                                        Text('${job.city} · ${job.jobType}',
                                            style: const TextStyle(
                                                color: AppColors.textSecondary, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      GlassChip(
                                          label: '${job.applicantsCount} pelamar',
                                          icon: Icons.people_outline_rounded),
                                      const SizedBox(height: 8),
                                      InkWell(
                                        onTap: () =>
                                            context.push('/recruiter/post-job', extra: job),
                                        borderRadius: BorderRadius.circular(9999),
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                                          child: Icon(Icons.edit_outlined,
                                              size: 16, color: AppColors.textSecondary),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
