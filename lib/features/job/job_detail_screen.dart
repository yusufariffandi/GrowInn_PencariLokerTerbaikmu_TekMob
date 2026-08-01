import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../models/job_model.dart';
import '../../services/supabase_service.dart';
import '../../shared/widgets/glass_widgets.dart';

class JobDetailScreen extends StatefulWidget {
  final String jobId;
  const JobDetailScreen({super.key, required this.jobId});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  JobModel? _job;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _load();
  }

  Future<void> _load() async {
    final data = await SupabaseService.instance.client
        .from('jobs')
        .select()
        .eq('id', widget.jobId)
        .maybeSingle();
    if (mounted) {
      setState(() {
        _job = data != null ? JobModel.fromJson(data) : null;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MeshBackground(
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _job == null
                  ? const Center(child: Text('Lowongan tidak ditemukan.'))
                  : _buildContent(_job!),
        ),
      ),
    );
  }

  Widget _buildContent(JobModel job) {
    final f = NumberFormat.decimalPattern('id_ID');
    final salaryText = (job.salaryMin != null && job.salaryMax != null)
        ? 'Rp${f.format(job.salaryMin)} - Rp${f.format(job.salaryMax)}'
        : job.salaryDisplay;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Row(
            children: [
              IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.5), shape: const CircleBorder()),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Share.share(
                  'Lowongan "${job.title}" di ${job.company} (${job.city}) — cek selengkapnya di aplikasi GrowIn!',
                  subject: 'Lowongan ${job.title} — ${job.company}',
                ),
                icon: const Icon(Icons.share_rounded, size: 20),
                style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.5), shape: const CircleBorder()),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
            children: [
              GlassPane(
                borderRadius: 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                              color: AppColors.black, borderRadius: BorderRadius.circular(16)),
                          child: Center(
                            child: Text(job.company.isNotEmpty ? job.company[0].toUpperCase() : '?',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(job.title,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 4),
                              Text(job.company,
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      GlassChip(label: salaryText, icon: Icons.payments_outlined),
                      GlassChip(label: job.jobType, icon: Icons.schedule_rounded),
                      GlassChip(label: job.experienceLevel, icon: Icons.workspace_premium_outlined),
                      GlassChip(label: job.location, icon: Icons.location_on_outlined),
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _MiniStat(
                      icon: Icons.groups_rounded,
                      label: '${job.applicantsCount} pelamar',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MiniStat(
                      icon: Icons.schedule_send_rounded,
                      label: _timeAgo(job.createdAt),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MiniStat(
                      icon: job.isActive ? Icons.bolt_rounded : Icons.pause_circle_outline_rounded,
                      label: job.isActive ? 'Aktif merekrut' : 'Ditutup sementara',
                    ),
                  ),
                ],
              ),
              if (job.industry.isNotEmpty) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: GlassChip(label: job.industry, icon: Icons.factory_outlined),
                ),
              ],
              if (job.galleryUrls.isNotEmpty) ...[
                const SizedBox(height: 18),
                _GalleryCarousel(urls: job.galleryUrls),
              ],
              if (job.lat != 0 && job.lng != 0) ...[
                const SizedBox(height: 18),
                _LocationPreviewCard(job: job, onOpenMaps: () => _openInMaps(job)),
              ],
              const SizedBox(height: 18),
              GlassPane(
                borderRadius: 20,
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    TabBar(
                      controller: _tab,
                      labelColor: Colors.white,
                      unselectedLabelColor: AppColors.textSecondary,
                      indicator: BoxDecoration(
                          color: AppColors.black, borderRadius: BorderRadius.circular(9999)),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelPadding: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(6),
                      labelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                      tabs: const [
                        Tab(text: 'Deskripsi'),
                        Tab(text: 'Kualifikasi'),
                        Tab(text: 'Perusahaan'),
                      ],
                    ),
                    SizedBox(
                      height: 220,
                      child: TabBarView(
                        controller: _tab,
                        children: [
                          _tabText(job.description.isNotEmpty
                              ? job.description
                              : 'Deskripsi pekerjaan belum diisi oleh rekruter.'),
                          _tabText(job.qualifications.isNotEmpty
                              ? job.qualifications
                              : 'Kualifikasi belum diisi oleh rekruter.'),
                          _tabText(job.aboutCompany.isNotEmpty
                              ? job.aboutCompany
                              : 'Informasi perusahaan belum diisi.'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Row(
            children: [
              IconButton(
                onPressed: () => context.push('/chat/${job.recruiterId}',
                    extra: {'name': job.company}),
                icon: const Icon(Icons.chat_bubble_outline_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryPillButton(
                  label: 'Lamar Sekarang',
                  icon: Icons.send_rounded,
                  onPressed: () => context.push('/apply/${job.id}'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Format "diposting X lalu" dari [date] tanpa perlu paket tambahan.
  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays >= 30) {
      final months = (diff.inDays / 30).floor();
      return 'Diposting $months bln lalu';
    } else if (diff.inDays >= 1) {
      return 'Diposting ${diff.inDays} hari lalu';
    } else if (diff.inHours >= 1) {
      return 'Diposting ${diff.inHours} jam lalu';
    } else if (diff.inMinutes >= 1) {
      return 'Diposting ${diff.inMinutes} mnt lalu';
    }
    return 'Baru saja diposting';
  }

  Future<void> _openInMaps(JobModel job) async {
    final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${job.lat},${job.lng}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Tidak bisa membuka aplikasi peta.')));
    }
  }

  Widget _tabText(String text) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Text(text, style: const TextStyle(fontSize: 13.5, height: 1.6)),
    );
  }
}

/// Pil kecil untuk menampilkan statistik lowongan (jumlah pelamar, waktu
/// posting, status aktif) supaya halaman detail terasa lebih "hidup".
class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MiniStat({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return GlassPane(
      borderRadius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Column(
        children: [
          Icon(icon, size: 16, color: AppColors.black),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Kartu pratinjau peta lokasi lowongan — cuplikan statis OpenStreetMap,
/// tap untuk membuka rute lengkap di aplikasi peta perangkat.
class _LocationPreviewCard extends StatelessWidget {
  final JobModel job;
  final VoidCallback onOpenMaps;
  const _LocationPreviewCard({required this.job, required this.onOpenMaps});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onOpenMaps,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: 130,
          child: Stack(
            fit: StackFit.expand,
            children: [
              IgnorePointer(
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(job.lat, job.lng),
                    initialZoom: 13.5,
                    interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.growin.app',
                    ),
                    MarkerLayer(markers: [
                      Marker(
                        point: LatLng(job.lat, job.lng),
                        width: 40,
                        height: 40,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.black,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.work_rounded, color: Colors.white, size: 18),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: GlassPane(
                  borderRadius: 9999,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.directions_rounded, size: 16, color: AppColors.black),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Buka rute ke ${job.location}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Carousel galeri foto lowongan (maks 3 slide) yang diunggah recruiter,
/// menampilkan gambaran suasana kerja / kantor di halaman detail pekerjaan.
class _GalleryCarousel extends StatefulWidget {
  final List<String> urls;
  const _GalleryCarousel({required this.urls});

  @override
  State<_GalleryCarousel> createState() => _GalleryCarouselState();
}

class _GalleryCarouselState extends State<_GalleryCarousel> {
  final _pageController = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 180,
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.urls.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (c, i) => Image.network(
                widget.urls[i],
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (c, e, st) => Container(
                  color: AppColors.lightGrey,
                  child: const Icon(Icons.broken_image_outlined, color: AppColors.midGrey),
                ),
              ),
            ),
            if (widget.urls.length > 1)
              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.urls.length, (i) {
                    final active = i == _index;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: active ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: active ? 0.95 : 0.5),
                        borderRadius: BorderRadius.circular(9999),
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3)],
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
