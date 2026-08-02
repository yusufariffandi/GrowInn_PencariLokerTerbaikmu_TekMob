import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/glass_widgets.dart';

class AiToolsHubScreen extends StatelessWidget {
  const AiToolsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tools = [
      _Tool('Buat CV (Template)', 'Isi data diri, foto, riwayat pendidikan & pengalaman',
          Icons.badge_outlined, '/cv/list'),
      _Tool('Surat Lamaran (Template)', 'Isi data diri & info lowongan, langsung jadi PDF siap print',
          Icons.mail_outline_rounded, '/cover-letter/list'),
      _Tool('Peta Lowongan', 'Jelajahi lowongan di sekitar lokasimu',
          Icons.map_rounded, '/job-map'),
      _Tool('Latihan Wawancara AI', 'Simulasi wawancara kerja dengan AI HRD — jawab dengan ketik atau suara',
          Icons.record_voice_over_rounded, '/ai/interview-simulator'),
    ];

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
        children: [
          const Text('AI Tools', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text('Semua fitur AI GrowIn ditenagai oleh Google Gemini.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 20),
          ...tools.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: InkWell(
                  onTap: () => context.push(t.route),
                  borderRadius: BorderRadius.circular(22),
                  child: GlassPane(
                    borderRadius: 22,
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                              color: AppColors.black, borderRadius: BorderRadius.circular(16)),
                          child: Icon(t.icon, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.title,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                              const SizedBox(height: 3),
                              Text(t.subtitle,
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded,
                            size: 14, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

class _Tool {
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  _Tool(this.title, this.subtitle, this.icon, this.route);
}
