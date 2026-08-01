import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../shared/widgets/glass_widgets.dart';
import 'jobseeker_home_screen.dart';
import 'recruiter_home_screen.dart';
import '../job/job_search_screen.dart';
import '../ai/ai_tools_hub_screen.dart';
import '../messages/messages_list_screen.dart';
import '../profile/profile_screen.dart';
import '../recruiter/recruiter_jobs_screen.dart';

/// Shell utama setelah login — bottom nav 5 ikon, konten beda antara
/// Karyawan (jobseeker) dan Rekruter, sesuai role di tabel `profiles`.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentProfileProvider);

    return profileAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, st) => Scaffold(
        body: Center(child: Text('Gagal memuat profil: $e')),
      ),
      data: (profile) {
        if (profile == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/role-select'));
          return const Scaffold(body: SizedBox());
        }

        final isRecruiter = profile.isRecruiter;

        final jobseekerScreens = [
          const JobseekerHomeScreen(),
          const JobSearchScreen(),
          const AiToolsHubScreen(),
          const MessagesListScreen(),
          const ProfileScreen(),
        ];

        final recruiterScreens = [
          const RecruiterHomeScreen(),
          const RecruiterJobsScreen(),
          const AiToolsHubScreen(),
          const MessagesListScreen(),
          const ProfileScreen(),
        ];

        final screens = isRecruiter ? recruiterScreens : jobseekerScreens;

        final navItems = isRecruiter
            ? const [
                _NavItem(Icons.home_rounded, 'Home'),
                _NavItem(Icons.work_rounded, 'Lowongan'),
                _NavItem(Icons.auto_awesome_rounded, 'AI Tools'),
                _NavItem(Icons.chat_bubble_rounded, 'Pesan'),
                _NavItem(Icons.person_rounded, 'Profil'),
              ]
            : const [
                _NavItem(Icons.home_rounded, 'Home'),
                _NavItem(Icons.search_rounded, 'Cari'),
                _NavItem(Icons.auto_awesome_rounded, 'AI Tools'),
                _NavItem(Icons.chat_bubble_rounded, 'Pesan'),
                _NavItem(Icons.person_rounded, 'Profil'),
              ];

        return Scaffold(
          extendBody: true,
          body: MeshBackground(child: IndexedStack(index: _index, children: screens)),
          bottomNavigationBar: _GlassBottomNav(
            items: navItems,
            currentIndex: _index,
            onTap: (i) => setState(() => _index = i),
          ),
        );
      },
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}

/// Navbar glassmorphism dengan lengkungan (curve) di sisi atas dan
/// indikator aktif berbentuk pil yang meluncur mengikuti tab terpilih.
class _GlassBottomNav extends StatelessWidget {
  final List<_NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _GlassBottomNav({required this.items, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      child: ClipPath(
        clipper: _NavCurveClipper(),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 18, 10, 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.55),
                  AppColors.accentPeach.withValues(alpha: 0.30),
                  Colors.white.withValues(alpha: 0.40),
                ],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentClay.withValues(alpha: 0.14),
                  blurRadius: 26,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final slotWidth = constraints.maxWidth / items.length;
                return Stack(
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      left: slotWidth * currentIndex,
                      top: 0,
                      bottom: 0,
                      width: slotWidth,
                      child: Center(
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [AppColors.primary, AppColors.primaryContainer]),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.35),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: List.generate(items.length, (i) {
                        final active = i == currentIndex;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => onTap(i),
                            behavior: HitTestBehavior.opaque,
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: TextStyle(
                                color: active ? Colors.white : AppColors.textSecondary,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(items[i].icon,
                                      size: active ? 21 : 22,
                                      color: active ? Colors.white : AppColors.textSecondary),
                                  const SizedBox(height: 3),
                                  Text(items[i].label),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Clipper untuk membentuk sisi atas navbar melengkung (curve) khas
/// glassmorphism, dengan cekungan lembut di bagian tengah.
class _NavCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const radius = 32.0;
    final path = Path();
    path.moveTo(0, radius);
    path.quadraticBezierTo(0, 0, radius, 0);

    const midDip = 14.0;
    path.lineTo(size.width * 0.40, 0);
    path.quadraticBezierTo(size.width * 0.5, midDip, size.width * 0.60, 0);

    path.lineTo(size.width - radius, 0);
    path.quadraticBezierTo(size.width, 0, size.width, radius);
    path.lineTo(size.width, size.height - radius);
    path.quadraticBezierTo(size.width, size.height, size.width - radius, size.height);
    path.lineTo(radius, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - radius);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
