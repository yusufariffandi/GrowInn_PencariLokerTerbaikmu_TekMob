import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';
import '../auth/widgets/auth_form_scaffold.dart';

/// Login khusus Admin. SENGAJA tidak ada tombol "Daftar" — akun admin
/// hanya boleh dibuat manual lewat Supabase Dashboard (lihat
/// supabase/migration_admin_and_notifications.sql), dan layar ini juga
/// tidak dipasang link-nya di role-select publik. Buka langsung lewat
/// path /login/admin.
class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _error;

  Future<void> _submit() async {
    setState(() => _error = null);
    if (_email.text.trim().isEmpty || _password.text.isEmpty) {
      setState(() => _error = 'Lengkapi email & kata sandi admin.');
      return;
    }
    final ok = await ref
        .read(authControllerProvider.notifier)
        .signIn(_email.text.trim(), _password.text);
    if (!ok) {
      if (mounted) setState(() => _error = 'Login gagal. Cek email & kata sandi.');
      return;
    }
    final uid = SupabaseService.instance.currentUserId;
    final profile = uid == null ? null : await SupabaseService.instance.getProfile(uid);
    if (profile == null || profile['role'] != 'admin') {
      await SupabaseService.instance.signOut();
      if (mounted) {
        setState(() => _error = 'Akun ini bukan akun Admin.');
      }
      return;
    }
    if (mounted) context.go('/admin');
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(authControllerProvider).isLoading;
    return AuthFormScaffold(
      badgeLabel: 'Admin',
      badgeIcon: Icons.admin_panel_settings_outlined,
      title: 'Login Admin',
      subtitle: 'Khusus tim internal GrowIn untuk mengelola tampilan gambar aplikasi.',
      loading: loading,
      errorText: _error,
      fields: [
        AuthTextField(
          label: 'Email Admin',
          hint: 'admin@growin.app',
          controller: _email,
          icon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
        ),
        AuthTextField(
          label: 'Kata Sandi',
          hint: 'Kata sandi admin',
          controller: _password,
          icon: Icons.lock_outline_rounded,
          obscure: true,
        ),
      ],
      primaryLabel: 'Masuk sebagai Admin',
      onPrimaryPressed: _submit,
      switchPrompt: '',
      switchActionLabel: '',
      onSwitchAction: () {},
      onBack: () => context.pop(),
    );
  }
}
