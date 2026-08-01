import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';
import '../../shared/widgets/glass_widgets.dart';

class ApplyFlowScreen extends ConsumerStatefulWidget {
  final String jobId;
  const ApplyFlowScreen({super.key, required this.jobId});

  @override
  ConsumerState<ApplyFlowScreen> createState() => _ApplyFlowScreenState();
}

class _ApplyFlowScreenState extends ConsumerState<ApplyFlowScreen> {
  int _step = 0;
  String? _selectedCvId;
  List<Map<String, dynamic>> _cvs = [];
  final _coverLetter = TextEditingController();
  final _expectedSalary = TextEditingController();
  String _noticePeriod = 'Segera';
  bool _loading = true;
  bool _submitting = false;
  bool _success = false;

  @override
  void initState() {
    super.initState();
    _loadCVs();
  }

  Future<void> _loadCVs() async {
    final uid = SupabaseService.instance.currentUserId;
    if (uid != null) {
      _cvs = await SupabaseService.instance.getMyCVs(uid);
    }
    setState(() => _loading = false);
  }

  Future<void> _submit() async {
    final uid = SupabaseService.instance.currentUserId;
    if (uid == null) return;
    setState(() => _submitting = true);
    try {
      await SupabaseService.instance.applyToJob({
        'job_id': widget.jobId,
        'user_id': uid,
        'cv_id': _selectedCvId,
        'cover_letter': _coverLetter.text.trim(),
        'expected_salary': _expectedSalary.text.trim(),
        'notice_period': _noticePeriod,
      });
      setState(() {
        _step = 2;
        _success = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal mengirim lamaran: $e')));
      }
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
                    const Expanded(
                        child: Text('Lamar Pekerjaan',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700))),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _StepIndicator(step: _step),
              const SizedBox(height: 20),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : IndexedStack(
                        index: _step,
                        children: [
                          _buildStep1(),
                          _buildStep2(),
                          _buildStep3(),
                        ],
                      ),
              ),
              if (!_loading && _step < 2)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Row(
                    children: [
                      if (_step > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => setState(() => _step--),
                            child: const Text('Kembali'),
                          ),
                        ),
                      if (_step > 0) const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: PrimaryPillButton(
                          label: _step == 0 ? 'Lanjut' : 'Kirim Lamaran',
                          loading: _submitting,
                          onPressed: _step == 0
                              ? (_cvs.isEmpty ? null : () => setState(() => _step = 1))
                              : _submit,
                        ),
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

  Widget _buildStep1() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        const Text('Pilih CV', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        const Text('Pilih salah satu CV yang tersimpan, atau buat baru dengan AI.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 16),
        if (_cvs.isEmpty)
          GlassPane(
            borderRadius: 20,
            child: Column(
              children: [
                const Icon(Icons.description_outlined, size: 36, color: AppColors.textSecondary),
                const SizedBox(height: 10),
                const Text('Kamu belum punya CV tersimpan.',
                    style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => context.push('/cv/builder'),
                  icon: const Icon(Icons.badge_outlined, size: 18),
                  label: const Text('Buat CV'),
                ),
              ],
            ),
          )
        else
          ..._cvs.map((cv) {
            final selected = _selectedCvId == cv['id'];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => setState(() => _selectedCvId = cv['id']),
                borderRadius: BorderRadius.circular(18),
                child: GlassPane(
                  borderRadius: 18,
                  border: selected ? Border.all(color: AppColors.black, width: 1.5) : null,
                  child: Row(
                    children: [
                      Icon(
                          selected
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_off_rounded,
                          color: AppColors.black),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(cv['fullname'] ?? 'CV', style: const TextStyle(fontWeight: FontWeight.w700)),
                            Text(cv['title'] ?? '',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildStep2() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        const Text('Detail Tambahan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        const Text('Cover Letter', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 8),
        TextField(
          controller: _coverLetter,
          maxLines: 5,
          decoration: const InputDecoration(hintText: 'Tulis cover letter singkat...'),
        ),
        const SizedBox(height: 16),
        const Text('Ekspektasi Gaji', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 8),
        TextField(
          controller: _expectedSalary,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'Contoh: 6.000.000'),
        ),
        const SizedBox(height: 16),
        const Text('Notice Period', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: ['Segera', '2 Minggu', '1 Bulan'].map((p) {
            final sel = _noticePeriod == p;
            return GestureDetector(
              onTap: () => setState(() => _noticePeriod = p),
              child: GlassChip(label: p, filled: sel),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: const BoxDecoration(color: AppColors.black, shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 46),
          ),
          const SizedBox(height: 24),
          const Text('Lamaran Terkirim!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Lamaranmu sudah dikirim. Pantau statusnya di Application Tracker.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: PrimaryPillButton(
              label: 'Lihat Status Lamaran',
              onPressed: () => context.go('/home'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int step;
  const _StepIndicator({required this.step});

  @override
  Widget build(BuildContext context) {
    final labels = ['Pilih CV', 'Detail', 'Selesai'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: List.generate(3, (i) {
          final active = i <= step;
          return Expanded(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: active ? AppColors.black : Colors.white.withValues(alpha: 0.6),
                  child: Text('${i + 1}',
                      style: TextStyle(
                          color: active ? Colors.white : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ),
                if (i < 2)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: i < step ? AppColors.black : AppColors.outlineVariant,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
