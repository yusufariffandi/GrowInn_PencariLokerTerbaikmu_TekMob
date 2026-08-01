import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_colors.dart';
import '../../models/job_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_provider.dart';
import '../../services/supabase_service.dart';
import '../../shared/widgets/glass_widgets.dart';
import 'location_picker_screen.dart';

/// Form Pasang / Edit Lowongan.
/// Bila [existingJob] diisi, form otomatis dalam mode edit (prefill data
/// & submit memanggil updateJob, bukan postJob) — dipakai karena tiap
/// recruiter hanya boleh punya 1 lowongan aktif.
class PostJobScreen extends ConsumerStatefulWidget {
  final JobModel? existingJob;
  const PostJobScreen({super.key, this.existingJob});

  @override
  ConsumerState<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends ConsumerState<PostJobScreen> {
  late final _title = TextEditingController(text: widget.existingJob?.title ?? '');
  late final _location =
      TextEditingController(text: widget.existingJob?.location ?? 'Yogyakarta');
  late final _city = TextEditingController(text: widget.existingJob?.city ?? 'Yogyakarta');
  late final _salaryMin =
      TextEditingController(text: widget.existingJob?.salaryMin?.toStringAsFixed(0) ?? '');
  late final _salaryMax =
      TextEditingController(text: widget.existingJob?.salaryMax?.toStringAsFixed(0) ?? '');
  late final _description = TextEditingController(text: widget.existingJob?.description ?? '');
  late final _qualifications =
      TextEditingController(text: widget.existingJob?.qualifications ?? '');
  late final _aboutCompany = TextEditingController(text: widget.existingJob?.aboutCompany ?? '');

  late String _jobType = widget.existingJob?.jobType ?? 'Full-time';
  late String _experienceLevel = widget.existingJob?.experienceLevel ?? 'Entry';
  late double _lat = widget.existingJob?.lat ?? -7.7956;
  late double _lng = widget.existingJob?.lng ?? 110.3695;
  bool _submitting = false;
  String? _error;

  /// Buka pemilih lokasi di peta, lalu simpan titik yang dipilih rekruter.
  Future<void> _pickLocationOnMap() async {
    final result = await context.push<LatLng>(
      '/recruiter/pick-location',
      extra: {'lat': _lat, 'lng': _lng},
    );
    if (result != null) {
      setState(() {
        _lat = result.latitude;
        _lng = result.longitude;
      });
    }
  }

  /// Galeri foto pekerjaan — maksimal 3 slide. Berisi URL lama (sudah
  /// tersimpan) atau null bila slot masih kosong. File baru yang dipilih
  /// disimpan terpisah di [_newGalleryFiles] menunggu diupload saat submit.
  late final List<String?> _galleryUrls = List<String?>.generate(
      3, (i) => (i < (widget.existingJob?.galleryUrls.length ?? 0)) ? widget.existingJob!.galleryUrls[i] : null);
  final List<Uint8List?> _newGalleryFiles = List<Uint8List?>.filled(3, null);
  final List<bool> _uploadingSlot = List<bool>.filled(3, false);

  final _jobTypes = ['Full-time', 'Part-time', 'Kontrak', 'Magang', 'Remote'];
  final _levels = ['Entry', 'Mid', 'Senior', 'Lead'];

  bool get _isEdit => widget.existingJob != null;

  Future<void> _pickGalleryImage(int index) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    // Baca langsung sebagai bytes (bukan dart:io File) agar berfungsi juga
    // di Flutter Web — dart:io File akan error "Unsupported operation:
    // _Namespace" di web.
    final bytes = await picked.readAsBytes();
    setState(() {
      _newGalleryFiles[index] = bytes;
    });
  }

  void _removeGalleryImage(int index) {
    setState(() {
      _newGalleryFiles[index] = null;
      _galleryUrls[index] = null;
    });
  }

  Future<List<String>> _uploadGalleryIfNeeded(String uid) async {
    final result = <String>[];
    for (var i = 0; i < 3; i++) {
      if (_newGalleryFiles[i] != null) {
        setState(() => _uploadingSlot[i] = true);
        try {
          final path = '$uid/${const Uuid().v4()}.jpg';
          final url = await SupabaseService.instance
              .uploadFile(bucket: 'job-gallery', path: path, bytes: _newGalleryFiles[i]!);
          result.add(url);
        } finally {
          if (mounted) setState(() => _uploadingSlot[i] = false);
        }
      } else if (_galleryUrls[i] != null && _galleryUrls[i]!.isNotEmpty) {
        result.add(_galleryUrls[i]!);
      }
    }
    return result;
  }

  Future<void> _submit() async {
    if (_title.text.trim().isEmpty || _location.text.trim().isEmpty) {
      setState(() => _error = 'Judul posisi & lokasi wajib diisi.');
      return;
    }
    final profile = ref.read(currentProfileProvider).value;
    final uid = SupabaseService.instance.currentUserId;
    if (uid == null || profile == null) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final galleryUrls = await _uploadGalleryIfNeeded(uid);

      final data = <String, dynamic>{
        'title': _title.text.trim(),
        'company': profile.companyName.isNotEmpty ? profile.companyName : profile.name,
        'company_logo_url': profile.companyLogoUrl,
        'location': _location.text.trim(),
        'city': _city.text.trim(),
        'lat': _lat,
        'lng': _lng,
        'salary_min': double.tryParse(_salaryMin.text.trim()),
        'salary_max': double.tryParse(_salaryMax.text.trim()),
        'salary_display': (_salaryMin.text.isEmpty || _salaryMax.text.isEmpty)
            ? 'Negotiable'
            : 'Rp${_salaryMin.text} - Rp${_salaryMax.text}',
        'experience_level': _experienceLevel,
        'job_type': _jobType,
        'description': _description.text.trim(),
        'qualifications': _qualifications.text.trim(),
        'about_company': _aboutCompany.text.trim(),
        'gallery_urls': galleryUrls,
      };

      if (_isEdit) {
        await SupabaseService.instance.updateJob(widget.existingJob!.id, data);
      } else {
        await SupabaseService.instance.postJob({
          'recruiter_id': uid,
          ...data,
        });
      }
      ref.invalidate(recruiterJobsProvider(uid));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(_isEdit ? 'Lowongan berhasil diperbarui!' : 'Lowongan berhasil dipasang!')));
        context.pop();
      }
    } catch (e) {
      setState(() => _error = 'Gagal menyimpan lowongan: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
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
                    Expanded(
                      child: Text(_isEdit ? 'Edit Lowongan' : 'Pasang Lowongan',
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                  children: [
                    if (_isEdit) ...[
                      GlassPane(
                        borderRadius: 16,
                        child: Row(
                          children: const [
                            Icon(Icons.info_outline_rounded, size: 18, color: AppColors.textSecondary),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Setiap akun recruiter hanya boleh punya 1 lowongan aktif. Perubahan akan menimpa lowongan yang sudah ada.',
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    _label('Judul Posisi'),
                    TextField(
                        controller: _title,
                        decoration: const InputDecoration(hintText: 'Contoh: Frontend Developer')),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Kota'),
                              TextField(controller: _city),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Lokasi Detail'),
                              TextField(controller: _location),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _label('Titik Lokasi di Peta'),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: Text(
                        'Tandai titik lokasi kerja di peta supaya calon karyawan bisa melihat & menuju lokasi dengan mudah.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        height: 140,
                        child: Stack(
                          children: [
                            IgnorePointer(
                              child: FlutterMap(
                                options: MapOptions(
                                  initialCenter: LatLng(_lat, _lng),
                                  initialZoom: 13,
                                  interactionOptions:
                                      const InteractionOptions(flags: InteractiveFlag.none),
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                    userAgentPackageName: 'com.growin.app',
                                  ),
                                  MarkerLayer(markers: [
                                    Marker(
                                      point: LatLng(_lat, _lng),
                                      width: 40,
                                      height: 40,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: AppColors.black,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 2),
                                        ),
                                        child: const Icon(Icons.work_rounded,
                                            color: Colors.white, size: 18),
                                      ),
                                    ),
                                  ]),
                                ],
                              ),
                            ),
                            Positioned(
                              right: 10,
                              bottom: 10,
                              child: ElevatedButton.icon(
                                onPressed: _pickLocationOnMap,
                                icon: const Icon(Icons.edit_location_alt_rounded, size: 16),
                                label: const Text('Ubah Titik'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppColors.black,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  textStyle:
                                      const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Gaji Min (Rp)'),
                              TextField(controller: _salaryMin, keyboardType: TextInputType.number),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Gaji Max (Rp)'),
                              TextField(controller: _salaryMax, keyboardType: TextInputType.number),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _label('Tipe Pekerjaan'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _jobTypes.map((t) {
                        final sel = _jobType == t;
                        return GestureDetector(
                          onTap: () => setState(() => _jobType = t),
                          child: GlassChip(label: t, filled: sel),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    _label('Level Pengalaman'),
                    Wrap(
                      spacing: 8,
                      children: _levels.map((l) {
                        final sel = _experienceLevel == l;
                        return GestureDetector(
                          onTap: () => setState(() => _experienceLevel = l),
                          child: GlassChip(label: l, filled: sel),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    _label('Deskripsi Pekerjaan'),
                    TextField(
                      controller: _description,
                      maxLines: 4,
                      decoration: const InputDecoration(hintText: 'Jelaskan tanggung jawab posisi ini...'),
                    ),
                    const SizedBox(height: 14),
                    _label('Kualifikasi'),
                    TextField(
                      controller: _qualifications,
                      maxLines: 4,
                      decoration: const InputDecoration(hintText: 'Syarat & kualifikasi kandidat...'),
                    ),
                    const SizedBox(height: 14),
                    _label('Tentang Perusahaan'),
                    TextField(
                      controller: _aboutCompany,
                      maxLines: 3,
                      decoration: const InputDecoration(hintText: 'Ceritakan tentang perusahaanmu...'),
                    ),
                    const SizedBox(height: 20),
                    _label('Galeri Foto Pekerjaan (maks 3)'),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: Text(
                        'Tambahkan sampai 3 foto sebagai gambaran suasana kerja / kantor, akan tampil sebagai slide di halaman detail lowongan.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                    Row(
                      children: List.generate(3, (i) => Expanded(child: _gallerySlot(i))),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 10),
                      Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                    ],
                    const SizedBox(height: 20),
                    PrimaryPillButton(
                      label: _isEdit ? 'Simpan Perubahan' : 'Pasang Lowongan',
                      icon: Icons.check_circle_outline_rounded,
                      loading: _submitting,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gallerySlot(int index) {
    final file = _newGalleryFiles[index];
    final url = _galleryUrls[index];
    final hasImage = file != null || (url != null && url.isNotEmpty);
    final uploading = _uploadingSlot[index];

    return Padding(
      padding: EdgeInsets.only(right: index < 2 ? 10 : 0),
      child: AspectRatio(
        aspectRatio: 1,
        child: GestureDetector(
          onTap: uploading ? null : () => _pickGalleryImage(index),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white.withValues(alpha: 0.5),
              border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (file != null)
                  Image.memory(file, fit: BoxFit.cover)
                else if (url != null && url.isNotEmpty)
                  Image.network(url, fit: BoxFit.cover)
                else
                  const Center(
                    child: Icon(Icons.add_photo_alternate_outlined,
                        size: 26, color: AppColors.textSecondary),
                  ),
                if (uploading)
                  Container(
                    color: Colors.black.withValues(alpha: 0.35),
                    child: const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      ),
                    ),
                  ),
                if (hasImage && !uploading)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removeGalleryImage(index),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                            color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.close_rounded, size: 13, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      );
}
