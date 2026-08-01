import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../models/cv_model.dart';
import '../../services/supabase_service.dart';
import '../../shared/widgets/glass_widgets.dart';
import 'cv_builder_screen.dart';
import 'cv_preview_screen.dart';

class CvListScreen extends StatefulWidget {
  const CvListScreen({super.key});

  @override
  State<CvListScreen> createState() => _CvListScreenState();
}

class _CvListScreenState extends State<CvListScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _rows = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = SupabaseService.instance.currentUserId;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }
    final rows = await SupabaseService.instance.getMyCVs(uid);
    setState(() {
      _rows = rows;
      _loading = false;
    });
  }

  Future<void> _confirmDelete(Map<String, dynamic> row) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Hapus CV?'),
        content: Text(
            'CV "${(row['fullname'] as String?)?.isNotEmpty == true ? row['fullname'] : 'Tanpa Nama'}" akan dihapus permanen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Hapus', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await SupabaseService.instance.deleteCV(row['id'] as String);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('CV berhasil dihapus.')));
      }
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal menghapus CV: $e')));
      }
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
                      child: Text('CV Saya', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    ),
                    InkWell(
                      onTap: () async {
                        await context.push('/cv/builder');
                        _load();
                      },
                      borderRadius: BorderRadius.circular(9999),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(color: AppColors.black, shape: BoxShape.circle),
                        child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _rows.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.description_outlined,
                                    size: 40, color: AppColors.textSecondary),
                                const SizedBox(height: 12),
                                const Text('Kamu belum punya CV tersimpan.',
                                    style: TextStyle(color: AppColors.textSecondary)),
                                const SizedBox(height: 14),
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    await context.push('/cv/builder');
                                    _load();
                                  },
                                  icon: const Icon(Icons.add_rounded, size: 18),
                                  label: const Text('Buat CV Baru'),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                            itemCount: _rows.length,
                            itemBuilder: (c, i) {
                              final row = _rows[i];
                              final cv = CVModel.fromJson(row);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: InkWell(
                                  onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => CvPreviewScreen(cv: cv))),
                                  borderRadius: BorderRadius.circular(20),
                                  child: GlassPane(
                                    borderRadius: 20,
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                              color: AppColors.black,
                                              borderRadius: BorderRadius.circular(12)),
                                          child: const Icon(Icons.description_rounded,
                                              color: Colors.white, size: 20),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(cv.fullname.isEmpty ? 'CV Tanpa Nama' : cv.fullname,
                                                  style: const TextStyle(
                                                      fontWeight: FontWeight.w700, fontSize: 14)),
                                              if (cv.tagline.isNotEmpty)
                                                Text(cv.tagline,
                                                    style: const TextStyle(
                                                        color: AppColors.textSecondary, fontSize: 12)),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () async {
                                            await context.push('/cv/builder', extra: row);
                                            _load();
                                          },
                                          icon: const Icon(Icons.edit_outlined, size: 18),
                                        ),
                                        IconButton(
                                          onPressed: () => _confirmDelete(row),
                                          icon: const Icon(Icons.delete_outline_rounded,
                                              size: 18, color: AppColors.error),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
