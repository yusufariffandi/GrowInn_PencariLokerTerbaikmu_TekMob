import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../models/cover_letter_model.dart';

/// Membangun dokumen PDF surat lamaran kerja formal, meniru layout template
/// referensi: kop tempat & tanggal rata kanan, tujuan surat, paragraf pembuka
/// berisi sumber info lowongan, tabel data pribadi, daftar lampiran bernomor,
/// dan blok tanda tangan rata kanan.
class CoverLetterPdf {
  static Future<pw.Document> build(CoverLetterModel cl) async {
    final doc = pw.Document();
    final included = cl.attachments.where((a) => a.included && a.name.trim().isNotEmpty).toList();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 56, vertical: 48),
        build: (context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColor.fromInt(0xFF7A1F1F), width: 1.4),
            ),
            padding: const pw.EdgeInsets.all(28),
            child: pw.DefaultTextStyle(
              style: const pw.TextStyle(fontSize: 10.5, lineSpacing: 2),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Align(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text('${cl.place}, ${cl.letterDate}'),
                  ),
                  pw.SizedBox(height: 18),
                  pw.Text('Hal: Lamaran pekerjaan'),
                  pw.SizedBox(height: 14),
                  pw.Text('Kepada Yth.'),
                  pw.Text(cl.recipientTitle.isEmpty ? 'HRD ${cl.companyName}' : cl.recipientTitle),
                  ...cl.companyAddress.split('\n').map((l) => pw.Text(l)),
                  pw.SizedBox(height: 16),
                  pw.Text('Dengan hormat,'),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Berdasarkan informasi dari situs ${cl.sourceSite} pada tanggal ${cl.sourceDate} '
                    'perihal lowongan pekerjaan di ${cl.companyName}. Melalui surat lamaran ini saya ingin '
                    'mengajukan diri untuk melamar pekerjaan guna mengisi posisi ${cl.position}.',
                    textAlign: pw.TextAlign.justify,
                  ),
                  pw.SizedBox(height: 16),
                  pw.Text('Saya yang bertanda tangan di bawah ini:'),
                  pw.SizedBox(height: 8),
                  _dataRow('Nama', cl.fullname),
                  _dataRow('Tempat, Tanggal Lahir', '${cl.birthPlace}, ${cl.birthDate}'),
                  _dataRow('Jenis Kelamin', cl.gender),
                  _dataRow('Alamat', cl.address),
                  _dataRow('Pendidikan Terakhir', cl.lastEducation),
                  _dataRow('Nomor Handphone', cl.phone),
                  _dataRow('Email', cl.email),
                  pw.SizedBox(height: 16),
                  pw.Text(
                    'Untuk melengkapi beberapa data yang diperlukan sebagai persyaratan administrasi '
                    'dan juga sebagai bahan pertimbangan Bapak/Ibu, saya lampirkan juga kelengkapan '
                    'data diri sebagai berikut:',
                    textAlign: pw.TextAlign.justify,
                  ),
                  pw.SizedBox(height: 6),
                  ...List.generate(included.length, (i) => pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 2, left: 6),
                        child: pw.Text('${i + 1}. ${included[i].name}'),
                      )),
                  pw.SizedBox(height: 16),
                  pw.Text(
                    'Demikian surat lamaran ini saya buat dengan sebenarnya. Atas perhatian dan '
                    'kebijaksanaan Bapak/Ibu, saya ucapkan banyak terima kasih.',
                    textAlign: pw.TextAlign.justify,
                  ),
                  pw.SizedBox(height: 24),
                  pw.Align(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text('Hormat saya,'),
                        pw.SizedBox(height: 40),
                        pw.Text(
                          '(${cl.signatureName.isEmpty ? cl.fullname : cl.signatureName})',
                          style: pw.TextStyle(decoration: pw.TextDecoration.underline),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    return doc;
  }

  static pw.Widget _dataRow(String label, String value) {
    if (value.trim().isEmpty || value.trim() == ',') return pw.SizedBox();
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(width: 130, child: pw.Text(label)),
          pw.Text(': '),
          pw.Expanded(child: pw.Text(value)),
        ],
      ),
    );
  }
}
