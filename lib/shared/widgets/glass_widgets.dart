import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Panel kaca dasar — dipakai di seluruh app untuk konsistensi "Warm Glass".
/// Menggunakan gradient tint tipis + highlight border ganda supaya efek
/// glassmorphism terasa lebih hidup dibanding tint solid biasa.
class GlassPane extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double blur;
  final Color? tint;
  final Border? border;

  const GlassPane({
    super.key,
    required this.child,
    this.borderRadius = 24,
    this.padding = const EdgeInsets.all(16),
    this.blur = 24,
    this.tint,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: tint == null
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.55),
                      AppColors.accentPeach.withValues(alpha: 0.18),
                      Colors.white.withValues(alpha: 0.30),
                    ],
                  )
                : null,
            color: tint,
            borderRadius: BorderRadius.circular(borderRadius),
            border: border ??
                Border.all(color: Colors.white.withValues(alpha: 0.65), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentClay.withValues(alpha: 0.10),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Panel kaca versi gelap (dipakai di atas foto/gambar terang, contoh: header profil)
class GlassPaneDark extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  const GlassPaneDark({
    super.key,
    required this.child,
    this.borderRadius = 24,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.black.withValues(alpha: 0.45),
                AppColors.accentClay.withValues(alpha: 0.35),
              ],
            ),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Background mesh gradient hitam-putih — dipasang di belakang setiap layar.
/// Catatan: versi ini SENGAJA tanpa bentuk bulat/blob di background (sudah
/// dihapus sesuai permintaan), tinggal gradient datar saja.
class MeshBackground extends StatelessWidget {
  final Widget child;
  final bool dark;
  const MeshBackground({super.key, required this.child, this.dark = false});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: dark ? AppColors.meshGradientDark : AppColors.meshGradient,
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// Chip/badge pil kaca kecil (tag, status, dsb.)
class GlassChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool filled;
  const GlassChip({super.key, required this.label, this.icon, this.filled = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: filled
            ? const LinearGradient(colors: [AppColors.primary, AppColors.primaryContainer])
            : null,
        color: filled ? null : Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(
            color: filled ? Colors.transparent : AppColors.black.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: filled ? Colors.white : AppColors.textPrimary),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: filled ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tombol utama pil solid dengan efek tekan.
class PrimaryPillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool expand;
  const PrimaryPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) {
    final button = ElevatedButton(
      onPressed: loading ? null : onPressed,
      child: loading
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
                Text(label),
              ],
            ),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
