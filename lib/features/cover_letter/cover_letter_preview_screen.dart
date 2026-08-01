import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../core/theme/app_colors.dart';
import '../../models/cover_letter_model.dart';
import '../../shared/widgets/glass_widgets.dart';
import 'cover_letter_pdf.dart';

/// Preview PDF surat lamaran — pakai package `printing` untuk render live
/// preview di layar, plus tombol Print (langsung ke printer/Save as PDF via
/// dialog OS) dan Share/Export file PDF.
class CoverLetterPreviewScreen extends StatelessWidget {
  final CoverLetterModel cl;
  const CoverLetterPreviewScreen({super.key, required this.cl});

  @override
  Widget build(BuildContext context) {
    final fileName =
        'Surat_Lamaran_${cl.fullname.replaceAll(' ', '_').isEmpty ? 'GrowIn' : cl.fullname.replaceAll(' ', '_')}.pdf';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Preview Surat Lamaran'),
        backgroundColor: Colors.transparent,
      ),
      body: PdfPreview(
        build: (format) async => (await CoverLetterPdf.build(cl)).save(),
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
