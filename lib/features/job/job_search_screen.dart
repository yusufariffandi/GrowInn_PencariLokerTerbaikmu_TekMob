import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/job_provider.dart';
import '../../services/supabase_service.dart';
import '../../shared/widgets/glass_widgets.dart';
import '../../shared/widgets/job_card.dart';

class JobSearchScreen extends ConsumerWidget {
  const JobSearchScreen({super.key});

  static const cities = ['Semua Kota', 'Yogyakarta', 'Jakarta', 'Bandung', 'Surabaya', 'Semarang'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(jobListProvider);
    final savedIds = ref.watch(savedJobIdsProvider);
    final cityFilter = ref.watch(jobCityFilterProvider);

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: GlassPane(
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
                    ),
                    const SizedBox(width: 10),
                    InkWell(
                      onTap: () => context.push('/job-map'),
                      borderRadius: BorderRadius.circular(9999),
                      child: GlassPane(
                        borderRadius: 9999,
                        padding: const EdgeInsets.all(14),
                        child: const Icon(Icons.map_rounded, size: 22),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: cities.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (c, i) {
                      final city = cities[i];
                      final selected = (city == 'Semua Kota' && cityFilter == null) ||
                          city == cityFilter;
                      return GestureDetector(
                        onTap: () => ref.read(jobCityFilterProvider.notifier).state =
                            city == 'Semua Kota' ? null : city,
                        child: GlassChip(label: city, filled: selected),
                      );
                    },
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
                  return const Center(
                      child: Text('Tidak ada lowongan ditemukan.',
                          style: TextStyle(color: AppColors.textSecondary)));
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                  itemCount: jobs.length,
                  itemBuilder: (c, i) {
                    final job = jobs[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: JobCard(
                        job: job,
                        isSaved: savedIds.contains(job.id),
                        onTap: () => context.push('/job/${job.id}'),
                        onBookmark: () async {
                          final uid = SupabaseService.instance.currentUserId;
                          if (uid == null) return;
                          final willSave = !savedIds.contains(job.id);
                          await SupabaseService.instance.toggleSaveJob(uid, job.id, willSave);
                          final next = {...savedIds};
                          willSave ? next.add(job.id) : next.remove(job.id);
                          ref.read(savedJobIdsProvider.notifier).state = next;
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
