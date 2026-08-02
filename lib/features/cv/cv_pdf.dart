import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../models/cv_model.dart';

/// Membangun dokumen PDF CV, meniru layout `CvPreviewScreen`: sidebar gelap
/// (foto, nama, keahlian, kontak) di kiri, dan Data Pribadi / Pendidikan /
/// Pengalaman / Hobi di kanan — versi cetak dari tema "Mono Glass" GrowIn.
class CvPdf {
  static Future<pw.Document> build(CVModel cv) async {
    final doc = pw.Document();

    pw.MemoryImage? photo;
    if (cv.photoUrl.isNotEmpty) {
      try {
        final res = await http.get(Uri.parse(cv.photoUrl));
        if (res.statusCode == 200) photo = pw.MemoryImage(res.bodyBytes);
      } catch (_) {
        // Foto gagal dimuat, lanjut tanpa foto.
      }
    }

    final black = PdfColor.fromInt(0xFF000000);

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (context) {
          return pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // ---- SIDEBAR (gelap) ----
              pw.Container(
                width: 160,
                color: black,
                padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 26),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (photo != null)
                      pw.ClipOval(
                        child: pw.Image(photo, width: 70, height: 70, fit: pw.BoxFit.cover),
                      )
                    else
                      pw.Container(
                        width: 70,
                        height: 70,
                        decoration: const pw.BoxDecoration(
                          color: PdfColor.fromInt(0x33FFFFFF),
                          shape: pw.BoxShape.circle,
                        ),
                      ),
                    pw.SizedBox(height: 16),
                    pw.Text(cv.fullname.isEmpty ? 'Nama Kamu' : cv.fullname,
                        style: pw.TextStyle(
                            color: PdfColors.white, fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    if (cv.tagline.isNotEmpty) ...[
                      pw.SizedBox(height: 2),
                      pw.Text(cv.tagline,
                          style: pw.TextStyle(
                              color: PdfColors.grey300,
                              fontSize: 9.5,
                              fontStyle: pw.FontStyle.italic)),
                    ],
                    if (cv.summary.isNotEmpty) ...[
                      pw.SizedBox(height: 12),
                      pw.Text(cv.summary,
                          style: const pw.TextStyle(
                              color: PdfColors.grey400, fontSize: 8.5, lineSpacing: 2)),
                    ],
                    pw.SizedBox(height: 18),
                    _sideTitle('KEAHLIAN'),
                    ...cv.skills.where((s) => s.trim().isNotEmpty).map(_sideBullet),
                    pw.SizedBox(height: 18),
                    _sideTitle('KONTAK'),
                    if (cv.contactPhone.isNotEmpty) _sideText(cv.contactPhone),
                    if (cv.contactAddress.isNotEmpty) _sideText(cv.contactAddress),
                    if (cv.contactWebsite.isNotEmpty) _sideText(cv.contactWebsite),
                  ],
                ),
              ),
              // ---- KONTEN (terang) ----
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(22),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
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
                      pw.SizedBox(height: 14),
                      _mainTitle('PENDIDIKAN'),
                      ...cv.educations
                          .where((e) => e.institution.trim().isNotEmpty)
                          .map((e) => _eduRow(e.institution, e.year)),
                      pw.SizedBox(height: 14),
                      _mainTitle('PENGALAMAN'),
                      ...cv.experiences
                          .where((e) => e.title.trim().isNotEmpty)
                          .map((e) => pw.Padding(
                                padding: const pw.EdgeInsets.only(bottom: 8),
                                child: pw.Column(
                                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.Text(e.title,
                                        style: pw.TextStyle(
                                            fontWeight: pw.FontWeight.bold, fontSize: 10)),
                                    if (e.subtitle.isNotEmpty)
                                      pw.Text(e.subtitle,
                                          style: pw.TextStyle(
                                              fontStyle: pw.FontStyle.italic,
                                              fontSize: 8.5,
                                              color: PdfColors.grey700)),
                                    pw.SizedBox(height: 3),
                                    ...e.bullets
                                        .where((b) => b.trim().isNotEmpty)
                                        .map((b) => pw.Padding(
                                              padding: const pw.EdgeInsets.only(bottom: 2),
                                              child: pw.Text('•  $b',
                                                  style: const pw.TextStyle(fontSize: 8.5)),
                                            )),
                                  ],
                                ),
                              )),
                      pw.SizedBox(height: 14),
                      _mainTitle('HOBI'),
                      ...cv.hobbies
                          .where((h) => h.trim().isNotEmpty)
                          .map((h) => pw.Text('•  $h', style: const pw.TextStyle(fontSize: 9))),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return doc;
  }

  static pw.Widget _sideTitle(String text) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Text(text,
            style: pw.TextStyle(
                color: PdfColors.white, fontSize: 9.5, fontWeight: pw.FontWeight.bold)),
      );

  static pw.Widget _sideBullet(String text) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.Text('•  $text', style: const pw.TextStyle(color: PdfColors.grey300, fontSize: 8.5)),
      );

  static pw.Widget _sideText(String text) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Text(text, style: const pw.TextStyle(color: PdfColors.grey300, fontSize: 8.5)),
      );

  static pw.Widget _mainTitle(String text) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Text(text,
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
      );

  static pw.Widget _dataRow(String label, String value) {
    if (value.trim().isEmpty || value.trim() == ',') return pw.SizedBox();
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(width: 110, child: pw.Text(label, style: const pw.TextStyle(fontSize: 8.5))),
          pw.Text(': ', style: const pw.TextStyle(fontSize: 8.5)),
          pw.Expanded(
              child: pw.Text(value,
                  style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold))),
        ],
      ),
    );
  }

  static pw.Widget _eduRow(String institution, String year) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 3),
        child: pw.Row(
          children: [
            pw.Expanded(
                child: pw.Text(institution,
                    style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
            pw.Text(year, style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
          ],
        ),
      );
}
