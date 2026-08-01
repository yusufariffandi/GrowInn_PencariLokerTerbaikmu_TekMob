import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/app_colors.dart';
import '../../models/job_model.dart';
import '../../providers/job_provider.dart';
import '../../shared/widgets/glass_widgets.dart';

/// Peta Lowongan — pakai flutter_map + OpenStreetMap (gratis, tanpa API key),
/// setara dengan Leaflet.js di prototype HTML asli.
class JobMapScreen extends ConsumerStatefulWidget {
  const JobMapScreen({super.key});

  @override
  ConsumerState<JobMapScreen> createState() => _JobMapScreenState();
}

class _JobMapScreenState extends ConsumerState<JobMapScreen> {
  JobModel? _selected;
  final _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    final jobsAsync = ref.watch(jobListProvider);

    return Scaffold(
      body: Stack(
        children: [
          jobsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('$e')),
            data: (jobs) {
              final validJobs = jobs.where((j) => j.lat != 0 && j.lng != 0).toList();
              return FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: validJobs.isNotEmpty
                      ? LatLng(validJobs.first.lat, validJobs.first.lng)
                      : const LatLng(-7.7956, 110.3695), // Yogyakarta
                  initialZoom: 12,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.growin.app',
                  ),
                  MarkerLayer(
                    markers: validJobs
                        .map(
                          (job) => Marker(
                            point: LatLng(job.lat, job.lng),
                            width: 44,
                            height: 44,
                            child: GestureDetector(
                              onTap: () => setState(() => _selected = job),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.black,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(Icons.work_rounded, color: Colors.white, size: 20),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              );
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.85), shape: const CircleBorder()),
              ),
            ),
          ),
          if (_selected != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: GlassPane(
                borderRadius: 22,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_selected!.title,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                          const SizedBox(height: 2),
                          Text('${_selected!.company} · ${_selected!.city}',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/job/${_selected!.id}'),
                      child: const Text('Lihat',
                          style: TextStyle(color: AppColors.black, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
