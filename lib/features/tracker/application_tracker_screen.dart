import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../models/application_model.dart';
import '../../services/supabase_service.dart';
import '../../shared/widgets/glass_widgets.dart';

class ApplicationTrackerScreen extends StatefulWidget {
  const ApplicationTrackerScreen({super.key});

  @override
  State<ApplicationTrackerScreen> createState() => _ApplicationTrackerScreenState();
}

class _ApplicationTrackerScreenState extends State<ApplicationTrackerScreen> {
  bool _loading = true;
  List<ApplicationModel> _apps = [];

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
    final rows = await SupabaseService.instance.getMyApplications(uid);
    setState(() {
      _apps = rows.map((e) => ApplicationModel.fromJson(e)).toList();
      _loading = false;
    });
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
                      child: Text('Application Tracker',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _apps.isEmpty
                        ? const Center(
                            child: Text('Belum ada lamaran yang dikirim.',
                                style: TextStyle(color: AppColors.textSecondary)))
                        : ListView(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                            children: ApplicationModel.pipeline.map((stage) {
                              final items = _apps.where((a) => a.status == stage).toList();
                              if (items.isEmpty) return const SizedBox();
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(stage,
                                            style: const TextStyle(
                                                fontSize: 14, fontWeight: FontWeight.w700)),
                                        const SizedBox(width: 8),
                                        GlassChip(label: '${items.length}'),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    ...items.map((a) => Padding(
                                          padding: const EdgeInsets.only(bottom: 10),
                                          child: GlassPane(
                                            borderRadius: 18,
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 40,
                                                  height: 40,
                                                  decoration: BoxDecoration(
                                                      color: AppColors.black,
                                                      borderRadius: BorderRadius.circular(12)),
                                                  child: Center(
                                                    child: Text(
                                                      (a.job?['company'] ?? '?')
                                                          .toString()
                                                          .substring(0, 1)
                                                          .toUpperCase(),
                                                      style: const TextStyle(
                                                          color: Colors.white,
                                                          fontWeight: FontWeight.w700),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(a.job?['title'] ?? 'Lowongan',
                                                          style: const TextStyle(
                                                              fontWeight: FontWeight.w700,
                                                              fontSize: 13.5)),
                                                      Text(a.job?['company'] ?? '',
                                                          style: const TextStyle(
                                                              color: AppColors.textSecondary,
                                                              fontSize: 12)),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
