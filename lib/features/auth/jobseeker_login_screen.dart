import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import 'widgets/auth_form_scaffold.dart';

class JobseekerLoginScreen extends ConsumerStatefulWidget {
  const JobseekerLoginScreen({super.key});

  @override
  ConsumerState<JobseekerLoginScreen> createState() => _JobseekerLoginScreenState();
}

class _JobseekerLoginScreenState extends ConsumerState<JobseekerLoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _error;

  Future<void> _submit() async {
    setState(() => _error = null);
    if (_email.text.trim().isEmpty || _password.text.isEmpty) {
      setState(() => _error = 'Email dan kata sandi wajib diisi.');
      return;
    }
    final ok = await ref
        .read(authControllerProvider.notifier)
        .signIn(_email.text.trim(), _password.text);
    if (ok && mounted) {
      context.go('/home');
    } else if (mounted) {
      setState(() => _error = 'Email atau kata sandi salah. Coba lagi.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(authControllerProvider).isLoading;
    return AuthFormScaffold(
      badgeLabel: 'Karyawan',
      badgeIcon: Icons.person_search_rounded,
      title: 'Masuk sebagai Karyawan',
      subtitle: 'Lanjutkan pencarian kerja kamu bersama GrowIn.',
      loading: loading,
      errorText: _error,
      fields: [
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
      primaryLabel: 'Masuk',
      onPrimaryPressed: _submit,
      switchPrompt: 'Belum punya akun Karyawan?',
      switchActionLabel: 'Daftar di sini',
      onSwitchAction: () => context.pushReplacement('/signup/jobseeker'),
      onBack: () => context.pop(),
    );
  }
}
