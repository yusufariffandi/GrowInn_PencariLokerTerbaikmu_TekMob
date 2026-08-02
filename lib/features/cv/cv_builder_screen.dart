import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../models/cv_model.dart';
import '../../services/supabase_service.dart';
import '../../shared/widgets/glass_widgets.dart';
import 'cv_preview_screen.dart';

/// Form pembuatan CV berbasis TEMPLATE (bukan AI generatif) — pertanyaan
/// mengikuti struktur CV umum: foto, data pribadi, pendidikan, pengalaman,
/// keahlian, kontak, dan hobi. Foto bisa diunggah langsung dari galeri/kamera
/// perangkat, dan opsional dipakai juga sebagai foto profil akun.
class CvBuilderScreen extends StatefulWidget {
  final Map<String, dynamic>? existing; // isi bila mode edit CV tersimpan
  const CvBuilderScreen({super.key, this.existing});

  @override
  State<CvBuilderScreen> createState() => _CvBuilderScreenState();
}

class _CvBuilderScreenState extends State<CvBuilderScreen> {
  late CVModel _cv;
  Uint8List? _pickedPhotoBytes;
  bool _useAsProfilePhoto = false;
  bool _uploadingPhoto = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cv = widget.existing != null ? CVModel.fromJson(widget.existing!) : CVModel();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (c) => _PhotoSourceSheet(),
    );
    if (source == null) return;
    final xfile = await picker.pickImage(source: source, imageQuality: 85, maxWidth: 900);
    if (xfile == null) return;
    // Baca langsung sebagai bytes (bukan dart:io File) agar berfungsi juga
    // di Flutter Web — dart:io File akan error "Unsupported operation:
    // _Namespace" di web.
    final bytes = await xfile.readAsBytes();
    setState(() => _pickedPhotoBytes = bytes);
  }

  Future<String?> _uploadPhotoIfNeeded() async {
    if (_pickedPhotoBytes == null) return _cv.photoUrl.isNotEmpty ? _cv.photoUrl : null;
    final uid = SupabaseService.instance.currentUserId;
    if (uid == null) return null;
    setState(() => _uploadingPhoto = true);
    try {
      final path = '$uid/cv_photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final url = await SupabaseService.instance
          .uploadFile(bucket: 'cvs', path: path, bytes: _pickedPhotoBytes!);
      if (_useAsProfilePhoto) {
        await SupabaseService.instance.updateProfile(uid, {'avatar_url': url});
      }
      return url;
    } catch (e) {
      setState(() => _error = 'Gagal unggah foto: $e');
      return null;
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _saveAndPreview() async {
    if (_cv.fullname.trim().isEmpty) {
      setState(() => _error = 'Nama lengkap wajib diisi.');
      return;
    }
    final uid = SupabaseService.instance.currentUserId;
    if (uid == null) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    final photoUrl = await _uploadPhotoIfNeeded();
    if (photoUrl != null) _cv.photoUrl = photoUrl;

    try {
      // Jika sedang mengedit CV yang sudah tersimpan (punya id), UPDATE baris
      // yang sama alih-alih selalu membuat baris baru. Ini juga yang membuat
      // foto yang baru diunggah akhirnya benar-benar tersimpan & muncul.
      if (_cv.id.isNotEmpty) {
        await SupabaseService.instance.updateCV(_cv.id, _cv.toInsertJson(uid));
      } else {
        await SupabaseService.instance.saveCV(_cv.toInsertJson(uid));
      }
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => CvPreviewScreen(cv: _cv)),
        );
      }
    } catch (e) {
      setState(() => _error = 'Gagal menyimpan CV: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
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
                    const Expanded(
                      child: Text('Buat CV',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                  children: [
                    _sectionTitle('Foto Profil'),
                    Center(
                      child: GestureDetector(
                        onTap: _pickPhoto,
                        child: Stack(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.5),
                                border: Border.all(color: AppColors.black.withValues(alpha: 0.15)),
                                image: _pickedPhotoBytes != null
                                    ? DecorationImage(
                                        image: MemoryImage(_pickedPhotoBytes!), fit: BoxFit.cover)
                                    : (_cv.photoUrl.isNotEmpty
                                        ? DecorationImage(
                                            image: NetworkImage(_cv.photoUrl), fit: BoxFit.cover)
                                        : null),
                              ),
                              child: (_pickedPhotoBytes == null && _cv.photoUrl.isEmpty)
                                  ? const Icon(Icons.add_a_photo_outlined,
                                      color: AppColors.textSecondary, size: 28)
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                    color: AppColors.black, shape: BoxShape.circle),
                                child: const Icon(Icons.edit_rounded, color: Colors.white, size: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Checkbox(
                            value: _useAsProfilePhoto,
                            activeColor: AppColors.black,
                            onChanged: (v) => setState(() => _useAsProfilePhoto = v ?? false),
                          ),
                          const Flexible(
                            child: Text('Gunakan juga sebagai foto profil akun',
                                style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                          ),
                        ],
                      ),
                    ),

                    _sectionTitle('Identitas'),
                    _field('Nama Lengkap', _cv.fullname, (v) => _cv.fullname = v, hint: 'Ketut Susilo'),
                    _field('Tagline / Status', _cv.tagline, (v) => _cv.tagline = v,
                        hint: 'Contoh: Lulusan Baru'),
                    _field('Ringkasan Singkat', _cv.summary, (v) => _cv.summary = v,
                        hint: 'Ceritakan dirimu secara singkat...', maxLines: 3),

                    _sectionTitle('Data Pribadi'),
                    Row(children: [
                      Expanded(
                          child: _field('Tempat Lahir', _cv.birthPlace, (v) => _cv.birthPlace = v)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _field('Tanggal Lahir', _cv.birthDate, (v) => _cv.birthDate = v,
                              hint: '25 Juli 2000')),
                    ]),
                    _field('Alamat', _cv.address, (v) => _cv.address = v),
                    Row(children: [
                      Expanded(child: _field('No. Telepon', _cv.phone, (v) => _cv.phone = v)),
                      const SizedBox(width: 12),
                      Expanded(child: _field('Jenis Kelamin', _cv.gender, (v) => _cv.gender = v,
                          hint: 'Laki-laki / Perempuan')),
                    ]),
                    Row(children: [
                      Expanded(child: _field('Agama', _cv.religion, (v) => _cv.religion = v)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _field('Kewarganegaraan', _cv.nationality, (v) => _cv.nationality = v)),
                    ]),
                    _field('Email', _cv.email, (v) => _cv.email = v),
                    _field('Status Pernikahan', _cv.maritalStatus, (v) => _cv.maritalStatus = v,
                        hint: 'Belum Menikah / Menikah'),

                    _sectionTitle('Pendidikan'),
                    ..._cv.educations.asMap().entries.map((e) {
                      final i = e.key;
                      final edu = e.value;
                      return _ListItemCard(
                        onDelete: _cv.educations.length > 1
                            ? () => setState(() => _cv.educations.removeAt(i))
                            : null,
                        children: [
                          _field('Institusi', edu.institution, (v) => edu.institution = v,
                              hint: 'Contoh: Universitas Borcelle'),
                          _field('Tahun', edu.year, (v) => edu.year = v, hint: '2014 – 2018'),
                        ],
                      );
                    }),
                    _addButton('Tambah Pendidikan',
                        () => setState(() => _cv.educations.add(CVEducation()))),

                    _sectionTitle('Pengalaman'),
                    ..._cv.experiences.asMap().entries.map((e) {
                      final i = e.key;
                      final exp = e.value;
                      return _ListItemCard(
                        onDelete: _cv.experiences.length > 1
                            ? () => setState(() => _cv.experiences.removeAt(i))
                            : null,
                        children: [
                          _field('Judul', exp.title, (v) => exp.title = v,
                              hint: 'Contoh: Komunikasi Internal'),
                          _field('Sub-judul (peran & periode)', exp.subtitle, (v) => exp.subtitle = v,
                              hint: 'Contoh: Strategi Komunikasi (Juni 2018 – Juli 2018)'),
                          const Padding(
                            padding: EdgeInsets.only(top: 4, bottom: 6),
                            child: Text('Poin-poin kegiatan',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
                          ),
                          ...exp.bullets.asMap().entries.map((b) {
                            final bi = b.key;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: b.value,
                                      decoration: const InputDecoration(hintText: 'Contoh: Mewawancarai narasumber'),
                                      onChanged: (v) => exp.bullets[bi] = v,
                                    ),
                                  ),
                                  if (exp.bullets.length > 1)
                                    IconButton(
                                      onPressed: () => setState(() => exp.bullets.removeAt(bi)),
                                      icon: const Icon(Icons.close_rounded, size: 18),
                                    ),
                                ],
                              ),
                            );
                          }),
                          TextButton.icon(
                            onPressed: () => setState(() => exp.bullets.add('')),
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: const Text('Tambah poin'),
                          ),
                        ],
                      );
                    }),
                    _addButton('Tambah Pengalaman',
                        () => setState(() => _cv.experiences.add(CVExperience()))),

                    _sectionTitle('Keahlian'),
                    ..._cv.skills.asMap().entries.map((e) => _simpleListRow(
                          value: e.value,
                          hint: 'Contoh: Kepemimpinan',
                          onChanged: (v) => _cv.skills[e.key] = v,
                          onDelete: _cv.skills.length > 1
                              ? () => setState(() => _cv.skills.removeAt(e.key))
                              : null,
                        )),
                    _addButton('Tambah Keahlian', () => setState(() => _cv.skills.add(''))),

                    _sectionTitle('Kontak'),
                    _field('No. Telepon (kontak)', _cv.contactPhone, (v) => _cv.contactPhone = v),
                    _field('Alamat (kontak)', _cv.contactAddress, (v) => _cv.contactAddress = v),
                    _field('Website / Portofolio', _cv.contactWebsite, (v) => _cv.contactWebsite = v,
                        hint: 'www.contohkamu.com'),

                    _sectionTitle('Hobi'),
                    ..._cv.hobbies.asMap().entries.map((e) => _simpleListRow(
                          value: e.value,
                          hint: 'Contoh: Membaca Buku',
                          onChanged: (v) => _cv.hobbies[e.key] = v,
                          onDelete: _cv.hobbies.length > 1
                              ? () => setState(() => _cv.hobbies.removeAt(e.key))
                              : null,
                        )),
                    _addButton('Tambah Hobi', () => setState(() => _cv.hobbies.add(''))),

                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                    ],
                    const SizedBox(height: 20),
                    PrimaryPillButton(
                      label: 'Simpan & Lihat Preview CV',
                      icon: Icons.visibility_outlined,
                      loading: _saving || _uploadingPhoto,
                      onPressed: _saveAndPreview,
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

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 10),
        child: Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
      );

  Widget _field(String label, String initial, ValueChanged<String> onChanged,
      {String? hint, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
          const SizedBox(height: 6),
          TextFormField(
            initialValue: initial,
            maxLines: maxLines,
            decoration: InputDecoration(hintText: hint ?? ''),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _simpleListRow({
    required String value,
    required String hint,
    required ValueChanged<String> onChanged,
    VoidCallback? onDelete,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              initialValue: value,
              decoration: InputDecoration(hintText: hint),
              onChanged: onChanged,
            ),
          ),
          if (onDelete != null)
            IconButton(onPressed: onDelete, icon: const Icon(Icons.close_rounded, size: 18)),
        ],
      ),
    );
  }

  Widget _addButton(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.add_rounded, size: 18),
        label: Text(label),
      ),
    );
  }
}

class _ListItemCard extends StatelessWidget {
  final List<Widget> children;
  final VoidCallback? onDelete;
  const _ListItemCard({required this.children, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassPane(
        borderRadius: 18,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...children,
            if (onDelete != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.error),
                  label: const Text('Hapus', style: TextStyle(color: AppColors.error)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PhotoSourceSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: GlassPane(
          borderRadius: 22,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Pilih dari Galeri'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Ambil Foto'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
