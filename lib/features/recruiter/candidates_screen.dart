import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../models/application_model.dart';
import '../../providers/application_provider.dart';
import '../../services/supabase_service.dart';
import '../../shared/widgets/glass_widgets.dart';

class CandidatesScreen extends ConsumerWidget {
  final String jobId;
  const CandidatesScreen({super.key, required this.jobId});

  Future<void> _updateStatus(WidgetRef ref, String appId, String status) async {
    await SupabaseService.instance.updateApplicationStatus(appId, status);
    ref.invalidate(jobApplicationsProvider(jobId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appsAsync = ref.watch(jobApplicationsProvider(jobId));

    return Scaffold(
      body: MeshBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                      style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.5),
                          shape: const CircleBorder()),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('Kandidat Pelamar',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: appsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, st) => Center(child: Text('$e')),
                  data: (apps) {
                    if (apps.isEmpty) {
                      return const Center(
                          child: Text('Belum ada pelamar untuk lowongan ini.',
                              style: TextStyle(color: AppColors.textSecondary)));
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                      itemCount: apps.length,
                      itemBuilder: (c, i) {
                        final app = apps[i];
                        final name = app.applicant?['name'] ?? 'Kandidat';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GlassPane(
                            borderRadius: 20,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: const BoxDecoration(
                                          color: AppColors.black, shape: BoxShape.circle),
                                      child: Center(
                                        child: Text(
                                          name.toString().isNotEmpty
                                              ? name.toString()[0].toUpperCase()
                                              : '?',
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
                                          Text(name,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w700, fontSize: 14.5)),
                                          const SizedBox(height: 2),
                                          Text(app.applicant?['headline'] ?? '',
                                              style: const TextStyle(
                                                  color: AppColors.textSecondary, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => context.push('/chat/${app.userId}',
                                          extra: {'name': name}),
                                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: ApplicationModel.pipeline.map((stage) {
                                    final sel = app.status == stage;
                                    return GestureDetector(
                                      onTap: () => _updateStatus(ref, app.id, stage),
                                      child: GlassChip(label: stage, filled: sel),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
