import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../core/utils/auth_error.dart';
import 'widgets/auth_form_scaffold.dart';

class RecruiterSignupScreen extends ConsumerStatefulWidget {
  const RecruiterSignupScreen({super.key});

  @override
  ConsumerState<RecruiterSignupScreen> createState() => _RecruiterSignupScreenState();
}

class _RecruiterSignupScreenState extends ConsumerState<RecruiterSignupScreen> {
  final _name = TextEditingController();
  final _company = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _error;

  Future<void> _submit() async {
    setState(() => _error = null);
    if (_name.text.trim().isEmpty ||
        _company.text.trim().isEmpty ||
        _email.text.trim().isEmpty ||
        _password.text.length < 6) {
      setState(() => _error = 'Lengkapi semua data (kata sandi min. 6 karakter).');
      return;
    }
    final ok = await ref.read(authControllerProvider.notifier).signUp(
          _email.text.trim(),
          _password.text,
          _name.text.trim(),
          'recruiter',
          companyName: _company.text.trim(),
        );
    if (ok && mounted) {
      context.go('/home');
    } else if (mounted) {
      final err = ref.read(authControllerProvider).error;
      setState(() => _error = friendlyAuthError(err, action: 'Pendaftaran'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(authControllerProvider).isLoading;
    return AuthFormScaffold(
      badgeLabel: 'Rekruter',
      badgeIcon: Icons.business_center_rounded,
      title: 'Daftar sebagai Rekruter',
      subtitle: 'Buat akun perusahaan untuk mulai memasang lowongan di GrowIn.',
      loading: loading,
      errorText: _error,
      fields: [
        AuthTextField(
          label: 'Nama Penanggung Jawab (HR)',
          hint: 'Nama kamu',
          controller: _name,
          icon: Icons.person_outline_rounded,
        ),
        AuthTextField(
          label: 'Nama Perusahaan',
          hint: 'PT Contoh Sejahtera',
          controller: _company,
          icon: Icons.apartment_rounded,
        ),
        AuthTextField(
          label: 'Email Perusahaan',
          hint: 'hr@perusahaan.com',
          controller: _email,
          icon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
        ),
        AuthTextField(
          label: 'Kata Sandi',
          hint: 'Minimal 6 karakter',
          controller: _password,
          icon: Icons.lock_outline_rounded,
          obscure: true,
        ),
      ],
      primaryLabel: 'Daftar sebagai Rekruter',
      onPrimaryPressed: _submit,
      switchPrompt: 'Sudah punya akun Rekruter?',
      switchActionLabel: 'Masuk di sini',
      onSwitchAction: () => context.pushReplacement('/login/recruiter'),
      onBack: () => context.pop(),
    );
  }
}
