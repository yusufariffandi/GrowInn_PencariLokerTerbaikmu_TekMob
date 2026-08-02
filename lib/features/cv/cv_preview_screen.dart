import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/cv_model.dart';
import '../../shared/widgets/glass_widgets.dart';
import 'cv_pdf_preview_screen.dart';

/// Preview CV meniru layout template referensi: sidebar gelap (foto, nama,
/// keahlian, kontak) di kiri, dan Data Pribadi / Pendidikan / Pengalaman /
/// Hobi di kanan — versi monokrom sesuai tema "Mono Glass" GrowIn.
class CvPreviewScreen extends StatelessWidget {
  final CVModel cv;
  const CvPreviewScreen({super.key, required this.cv});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Preview CV'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Cetak / Simpan PDF',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => CvPdfPreviewScreen(cv: cv)),
            ),
            icon: const Icon(Icons.picture_as_pdf_outlined),
          ),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('CV tersimpan di profil kamu.')));
            },
            icon: const Icon(Icons.check_circle_outline_rounded),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ---- SIDEBAR (gelap) ----
                Container(
                  width: 140,
                  color: AppColors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white24,
                        backgroundImage:
                            cv.photoUrl.isNotEmpty ? NetworkImage(cv.photoUrl) : null,
                        child: cv.photoUrl.isEmpty
                            ? const Icon(Icons.person_rounded, color: Colors.white54, size: 36)
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(cv.fullname.isEmpty ? 'Nama Kamu' : cv.fullname,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                      if (cv.tagline.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(cv.tagline,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 11, fontStyle: FontStyle.italic)),
                      ],
                      if (cv.summary.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(cv.summary,
                            style: const TextStyle(color: Colors.white60, fontSize: 9.5, height: 1.5)),
                      ],
                      const SizedBox(height: 20),
                      _sideTitle('KEAHLIAN'),
                      ...cv.skills.where((s) => s.trim().isNotEmpty).map(_sideBullet),
                      const SizedBox(height: 20),
                      _sideTitle('KONTAK'),
                      if (cv.contactPhone.isNotEmpty) _sideIconText(Icons.call_rounded, cv.contactPhone),
                      if (cv.contactAddress.isNotEmpty)
                        _sideIconText(Icons.location_on_rounded, cv.contactAddress),
                      if (cv.contactWebsite.isNotEmpty)
                        _sideIconText(Icons.language_rounded, cv.contactWebsite),
                    ],
                  ),
                ),
                // ---- KONTEN (terang) ----
                Expanded(
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _mainTitle('DATA PRIBADI'),
                        _dataRow('Tempat, Tgl Lahir', '${cv.birthPlace}, ${cv.birthDate}'),
                        _dataRow('Alamat', cv.address),
                        _dataRow('No. Telepon', cv.phone),
                        _dataRow('Jenis Kelamin', cv.gender),
                        _dataRow('Agama', cv.religion),
                        _dataRow('Kewarganegaraan', cv.nationality),
                        _dataRow('Email', cv.email),
                        _dataRow('Status', cv.maritalStatus),
                        const SizedBox(height: 16),
                        _mainTitle('PENDIDIKAN'),
                        ...cv.educations
                            .where((e) => e.institution.trim().isNotEmpty)
                            .map((e) => _eduRow(e.institution, e.year)),
                        const SizedBox(height: 16),
                        _mainTitle('PENGALAMAN'),
                        ...cv.experiences
                            .where((e) => e.title.trim().isNotEmpty)
                            .map((e) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(e.title,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700, fontSize: 11)),
                                      if (e.subtitle.isNotEmpty)
                                        Text(e.subtitle,
                                            style: const TextStyle(
                                                fontStyle: FontStyle.italic,
                                                fontSize: 9.5,
                                                color: AppColors.textSecondary)),
                                      const SizedBox(height: 4),
                                      ...e.bullets
                                          .where((b) => b.trim().isNotEmpty)
                                          .map((b) => Padding(
                                                padding: const EdgeInsets.only(bottom: 2),
                                                child: Text('•  $b',
                                                    style: const TextStyle(fontSize: 9.5, height: 1.4)),
                                              )),
                                    ],
                                  ),
                                )),
                        const SizedBox(height: 16),
                        _mainTitle('HOBI'),
                        ...cv.hobbies
                            .where((h) => h.trim().isNotEmpty)
                            .map((h) => Text('•  $h', style: const TextStyle(fontSize: 10))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: PrimaryPillButton(
          label: 'Selesai',
          icon: Icons.check_rounded,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  Widget _sideTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(
                color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
      );

  Widget _sideBullet(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Text('•  $text', style: const TextStyle(color: Colors.white70, fontSize: 9.5)),
      );

  Widget _sideIconText(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white70, size: 12),
            const SizedBox(width: 6),
            Expanded(
                child: Text(text,
                    style: const TextStyle(color: Colors.white70, fontSize: 9.5, height: 1.3))),
          ],
        ),
      );

  Widget _mainTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
      );

  Widget _dataRow(String label, String value) {
    if (value.trim().isEmpty || value.trim() == ',') return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(fontSize: 9.5))),
          const Text(': ', style: TextStyle(fontSize: 9.5)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _eduRow(String institution, String year) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            Expanded(
                child: Text(institution,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
            Text(year, style: const TextStyle(fontSize: 9.5, color: AppColors.textSecondary)),
          ],
        ),
      );
}
