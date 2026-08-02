import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/app_images_provider.dart';
import 'admin_image.dart';

class HeroSlide {
  final String eyebrow;
  final String title;
  final String subtitle;
  final IconData icon;
  const HeroSlide({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

/// Hero section glassmorphism yang menampilkan informasi bergantian
/// secara otomatis setiap beberapa detik — dipasang di bagian atas
/// halaman Home (mengikuti komposisi hero foto pada referensi desain).
///
/// Bila [backgroundImageKey] diisi, foto yang diatur Admin lewat menu
/// Kelola Tampilan (tabel `app_images`) akan tampil sebagai latar di
/// belakang gradient — kalau admin belum upload apa pun, tampilan lama
/// (gradient polos) tetap dipakai sebagai fallback.
class HeroCarousel extends ConsumerStatefulWidget {
  final List<HeroSlide> slides;
  final Duration interval;
  final String? backgroundImageKey;
  const HeroCarousel({
    super.key,
    required this.slides,
    this.interval = const Duration(seconds: 4),
    this.backgroundImageKey,
  });

  @override
  ConsumerState<HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends ConsumerState<HeroCarousel> {
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.interval, (_) {
      if (!mounted) return;
      setState(() => _index = (_index + 1) % widget.slides.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slide = widget.slides[_index];
    final hasBgKey = widget.backgroundImageKey != null;
    final bgUrl = hasBgKey
        ? ref.watch(appImagesProvider).maybeWhen(
            data: (m) => m[widget.backgroundImageKey!], orElse: () => null)
        : null;
    final hasBgImage = bgUrl != null && bgUrl.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        height: 210,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.heroGradient,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasBgImage) ...[
              AdminManagedImage(imageKey: widget.backgroundImageKey!, fit: BoxFit.cover),
              Container(color: Colors.black.withValues(alpha: 0.38)),
            ],
            // Dekorasi bentuk lingkaran lembut ala foto gunung/kabut senja.
            Positioned(
              right: -40,
              top: -30,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.10),
                ),
              ),
            ),
            Positioned(
              left: -30,
              bottom: -50,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.black.withValues(alpha: 0.14),
                ),
              ),
            ),
            // Ikon besar transparan sebagai aksen visual, berganti tiap slide.
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Align(
                key: ValueKey('icon_$_index'),
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 18, bottom: 10),
                  child: Icon(slide.icon, size: 100, color: Colors.white.withValues(alpha: 0.16)),
                ),
              ),
            ),
            // Konten teks glass di atas gradient.
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 450),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.15),
                          end: Offset.zero,
                        ).animate(anim),
                        child: child,
                      ),
                    ),
                    child: Column(
                      key: ValueKey(_index),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(9999),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                          ),
                          child: Text(
                            slide.eyebrow,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          slide.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          slide.subtitle,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: List.generate(widget.slides.length, (i) {
                      final active = i == _index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 6),
                        width: active ? 20 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: active ? 0.95 : 0.4),
                          borderRadius: BorderRadius.circular(9999),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
