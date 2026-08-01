import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../models/job_model.dart';
import '../../services/supabase_service.dart';
import '../../shared/widgets/glass_widgets.dart';
import '../../shared/widgets/job_card.dart';

class SavedJobsScreen extends StatefulWidget {
  const SavedJobsScreen({super.key});

  @override
  State<SavedJobsScreen> createState() => _SavedJobsScreenState();
}

class _SavedJobsScreenState extends State<SavedJobsScreen> {
  bool _loading = true;
  List<JobModel> _jobs = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = SupabaseService.instance.currentUserId;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }
    final rows = await SupabaseService.instance.getSavedJobs(uid);
    setState(() {
      _jobs = rows
          .where((r) => r['jobs'] != null)
          .map((r) => JobModel.fromJson(Map<String, dynamic>.from(r['jobs'])))
          .toList();
      _loading = false;
    });
  }

  Future<void> _unsave(String jobId) async {
    final uid = SupabaseService.instance.currentUserId;
    if (uid == null) return;
    await SupabaseService.instance.toggleSaveJob(uid, jobId, false);
    setState(() => _jobs.removeWhere((j) => j.id == jobId));
  }

  @override
  Widget build(BuildContext context) {
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
                      child: Text('Lowongan Tersimpan',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _jobs.isEmpty
                        ? const Center(
                            child: Text('Belum ada lowongan tersimpan.',
                                style: TextStyle(color: AppColors.textSecondary)))
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                            itemCount: _jobs.length,
                            itemBuilder: (c, i) {
                              final job = _jobs[i];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: JobCard(
                                  job: job,
                                  isSaved: true,
                                  onTap: () => context.push('/job/${job.id}'),
                                  onBookmark: () => _unsave(job.id),
                                ),
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
