import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../core/utils/auth_error.dart';
import 'widgets/auth_form_scaffold.dart';

class JobseekerSignupScreen extends ConsumerStatefulWidget {
  const JobseekerSignupScreen({super.key});

  @override
  ConsumerState<JobseekerSignupScreen> createState() => _JobseekerSignupScreenState();
}

class _JobseekerSignupScreenState extends ConsumerState<JobseekerSignupScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _error;

  Future<void> _submit() async {
    setState(() => _error = null);
    if (_name.text.trim().isEmpty || _email.text.trim().isEmpty || _password.text.length < 6) {
      setState(() => _error = 'Lengkapi nama, email, dan kata sandi (min. 6 karakter).');
      return;
    }
    final ok = await ref.read(authControllerProvider.notifier).signUp(
          _email.text.trim(),
          _password.text,
          _name.text.trim(),
          'jobseeker',
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
      badgeLabel: 'Karyawan',
      badgeIcon: Icons.person_search_rounded,
      title: 'Daftar sebagai Karyawan',
      subtitle: 'Buat akun untuk mulai melamar kerja & memakai fitur AI GrowIn.',
      loading: loading,
      errorText: _error,
      fields: [
        AuthTextField(
          label: 'Nama Lengkap',
          hint: 'Nama kamu',
          controller: _name,
          icon: Icons.person_outline_rounded,
        ),
        AuthTextField(
          label: 'Email',
          hint: 'nama@email.com',
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
      primaryLabel: 'Daftar sebagai Karyawan',
      onPrimaryPressed: _submit,
      switchPrompt: 'Sudah punya akun Karyawan?',
      switchActionLabel: 'Masuk di sini',
      onSwitchAction: () => context.pushReplacement('/login/jobseeker'),
      onBack: () => context.pop(),
    );
  }
}
