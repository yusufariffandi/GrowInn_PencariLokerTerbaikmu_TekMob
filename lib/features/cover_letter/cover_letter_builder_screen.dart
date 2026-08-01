import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../models/cover_letter_model.dart';
import '../../services/supabase_service.dart';
import '../../shared/widgets/glass_widgets.dart';
import 'cover_letter_preview_screen.dart';

/// Form surat lamaran kerja berbasis TEMPLATE — pertanyaan mengikuti
/// struktur surat lamaran formal Indonesia: tempat & tanggal, tujuan surat,
/// info lowongan, data pribadi, dan daftar lampiran berkas.
class CoverLetterBuilderScreen extends StatefulWidget {
  final Map<String, dynamic>? existing; // isi bila mode edit
  const CoverLetterBuilderScreen({super.key, this.existing});

  @override
  State<CoverLetterBuilderScreen> createState() => _CoverLetterBuilderScreenState();
}

class _CoverLetterBuilderScreenState extends State<CoverLetterBuilderScreen> {
  late CoverLetterModel _cl;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cl = widget.existing != null
        ? CoverLetterModel.fromJson(widget.existing!)
        : CoverLetterModel();
  }

  Future<void> _saveAndPreview() async {
    if (_cl.fullname.trim().isEmpty || _cl.position.trim().isEmpty || _cl.companyName.trim().isEmpty) {
      setState(() => _error = 'Nama, posisi yang dilamar, dan nama perusahaan wajib diisi.');
      return;
    }
    final uid = SupabaseService.instance.currentUserId;
    if (uid == null) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      // Jika sedang mengedit surat lamaran yang sudah tersimpan (punya id),
      // UPDATE baris yang sama alih-alih selalu membuat baris baru.
      if (_cl.id.isNotEmpty) {
        await SupabaseService.instance.updateCoverLetter(_cl.id, _cl.toInsertJson(uid));
      } else {
        await SupabaseService.instance.saveCoverLetter(_cl.toInsertJson(uid));
      }
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => CoverLetterPreviewScreen(cl: _cl)),
        );
      }
    } catch (e) {
      setState(() => _error = 'Gagal menyimpan surat lamaran: $e');
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
                      child: Text('Surat Lamaran Kerja',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                  children: [
                    _sectionTitle('Tempat & Tanggal Surat'),
                    Row(children: [
                      Expanded(
                          child: _field('Tempat', _cl.place, (v) => _cl.place = v,
                              hint: 'Contoh: Yogyakarta')),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _field('Tanggal', _cl.letterDate, (v) => _cl.letterDate = v,
                              hint: '12 Juli 2026')),
                    ]),

                    _sectionTitle('Tujuan Surat'),
                    _field('Nama Perusahaan', _cl.companyName, (v) => _cl.companyName = v,
                        hint: 'Contoh: Turen Indah Group'),
                    _field('Ditujukan Kepada', _cl.recipientTitle, (v) => _cl.recipientTitle = v,
                        hint: 'Contoh: HRD Turen Indah Group'),
                    _field('Alamat Perusahaan', _cl.companyAddress, (v) => _cl.companyAddress = v,
                        hint: 'Jl. Lelede No. 80, Lombok Barat', maxLines: 2),

                    _sectionTitle('Info Lowongan'),
                    _field('Sumber Info Lowongan', _cl.sourceSite, (v) => _cl.sourceSite = v,
                        hint: 'Contoh: https://glints.com/id atau "media sosial perusahaan"'),
                    _field('Tanggal Info Diperoleh', _cl.sourceDate, (v) => _cl.sourceDate = v,
                        hint: 'Contoh: 10 Juli 2026'),
                    _field('Posisi yang Dilamar', _cl.position, (v) => _cl.position = v,
                        hint: 'Contoh: Digital Marketing'),

                    _sectionTitle('Data Pribadi'),
                    _field('Nama Lengkap', _cl.fullname, (v) => _cl.fullname = v),
                    Row(children: [
                      Expanded(
                          child: _field('Tempat Lahir', _cl.birthPlace, (v) => _cl.birthPlace = v)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _field('Tanggal Lahir', _cl.birthDate, (v) => _cl.birthDate = v,
                              hint: '25 Juli 2000')),
                    ]),
                    _field('Jenis Kelamin', _cl.gender, (v) => _cl.gender = v,
                        hint: 'Laki-laki / Perempuan'),
                    _field('Alamat', _cl.address, (v) => _cl.address = v, maxLines: 2),
                    _field('Pendidikan Terakhir', _cl.lastEducation, (v) => _cl.lastEducation = v,
                        hint: 'Contoh: S1 Sistem Informasi'),
                    _field('Nomor Handphone', _cl.phone, (v) => _cl.phone = v),
                    _field('Email', _cl.email, (v) => _cl.email = v),

                    _sectionTitle('Lampiran Berkas'),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text('Centang berkas yang ingin dicantumkan dalam surat.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ),
                    ..._cl.attachments.asMap().entries.map((e) {
                      final i = e.key;
                      final att = e.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Checkbox(
                              value: att.included,
                              activeColor: AppColors.black,
                              onChanged: (v) => setState(() => att.included = v ?? true),
                            ),
                            Expanded(
                              child: TextFormField(
                                initialValue: att.name,
                                decoration: const InputDecoration(border: InputBorder.none),
                                onChanged: (v) => att.name = v,
                              ),
                            ),
                            IconButton(
                              onPressed: () => setState(() => _cl.attachments.removeAt(i)),
                              icon: const Icon(Icons.close_rounded, size: 18),
                            ),
                          ],
                        ),
                      );
                    }),
                    OutlinedButton.icon(
                      onPressed: () => setState(
                          () => _cl.attachments.add(CoverLetterAttachment(name: ''))),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Tambah Lampiran'),
                    ),

                    _sectionTitle('Tanda Tangan'),
                    _field('Nama untuk Tanda Tangan', _cl.signatureName, (v) => _cl.signatureName = v,
                        hint: 'Default: sama seperti Nama Lengkap'),

                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                    ],
                    const SizedBox(height: 20),
                    PrimaryPillButton(
                      label: 'Simpan & Lihat Preview PDF',
                      icon: Icons.picture_as_pdf_outlined,
                      loading: _saving,
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
}
