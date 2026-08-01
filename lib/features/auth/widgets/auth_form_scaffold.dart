import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/glass_widgets.dart';

/// Kerangka visual bersama untuk 4 layar auth (login/signup x jobseeker/recruiter).
/// Menjaga konsistensi tampilan "Mono Glass" tanpa duplikasi banyak kode,
/// sementara tetap menghasilkan 4 ROUTE & SCREEN terpisah secara nyata.
class AuthFormScaffold extends StatelessWidget {
  final String badgeLabel; // "Karyawan" / "Rekruter"
  final IconData badgeIcon;
  final String title;
  final String subtitle;
  final List<Widget> fields;
  final String primaryLabel;
  final VoidCallback? onPrimaryPressed;
  final bool loading;
  final String switchPrompt;
  final String switchActionLabel;
  final VoidCallback onSwitchAction;
  final VoidCallback onBack;
  final String? errorText;

  const AuthFormScaffold({
    super.key,
    required this.badgeLabel,
    required this.badgeIcon,
    required this.title,
    required this.subtitle,
    required this.fields,
    required this.primaryLabel,
    required this.onPrimaryPressed,
    required this.loading,
    required this.switchPrompt,
    required this.switchActionLabel,
    required this.onSwitchAction,
    required this.onBack,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MeshBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.5),
                    shape: const CircleBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                GlassChip(label: badgeLabel, icon: badgeIcon),
                const SizedBox(height: 16),
                Text(title, style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 6),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 28),
                ...fields,
                if (errorText != null) ...[
                  const SizedBox(height: 8),
                  Text(errorText!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                ],
                const SizedBox(height: 12),
                PrimaryPillButton(
                  label: primaryLabel,
                  onPressed: onPrimaryPressed,
                  loading: loading,
                ),
                const SizedBox(height: 20),
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      Text(switchPrompt,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5)),
                      GestureDetector(
                        onTap: onSwitchAction,
                        child: Text(' $switchActionLabel',
                            style: const TextStyle(
                                color: AppColors.black,
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Text field kaca standar untuk form auth.
class AuthTextField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool obscure;
  final TextInputType keyboardType;
  final IconData icon;

  const AuthTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    required this.icon,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(icon, size: 20, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
