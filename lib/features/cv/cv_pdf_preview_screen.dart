import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../core/theme/app_colors.dart';
import '../../models/cv_model.dart';
import 'cv_pdf.dart';

/// Preview PDF CV — pakai package `printing` untuk render live preview di
/// layar, plus tombol Print (langsung ke printer/Save as PDF via dialog OS)
/// dan Share/Export file PDF.
class CvPdfPreviewScreen extends StatelessWidget {
  final CVModel cv;
  const CvPdfPreviewScreen({super.key, required this.cv});

  @override
  Widget build(BuildContext context) {
    final fileName =
        'CV_${cv.fullname.replaceAll(' ', '_').isEmpty ? 'GrowIn' : cv.fullname.replaceAll(' ', '_')}.pdf';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Cetak / Simpan PDF'),
        backgroundColor: Colors.transparent,
      ),
      body: PdfPreview(
        build: (format) async => (await CvPdf.build(cv)).save(),
        allowPrinting: true,
        allowSharing: true,
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        pdfFileName: fileName,
      ),
    );
  }
}
